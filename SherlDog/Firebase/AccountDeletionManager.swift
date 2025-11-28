//
//  AccountDeletionManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/27/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

final class AccountDeletionManager {
    static let shared = AccountDeletionManager()
    private init() {}
    
    private var appleReauthDelegate: AppleReauthDelegate?
    private var appleAuthController: ASAuthorizationController?
    
    // MARK: - 메인 회원탈퇴 메서드
    func deleteAccount(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let userId = currentUser.uid
        let provider = AuthSession.currentProvider
        
        // 1. 재인증
        performReauthentication(provider: provider, from: viewController) { [weak self] reauthSuccess in
            guard let self else { return }
            
            guard reauthSuccess else {
                completion(false)
                return
            }
            
            // 2. Firestore 유저 데이터 삭제
            self.deleteUserData(userId: userId) { dataSuccess in
                
                // 3. 소셜 계정 unlink / 로그아웃
                self.unlinkSocialAccount(provider: provider) { _ in
                    
                    // 4. Firebase Auth 계정 삭제
                    Auth.auth().currentUser?.delete { error in
                        if let error = error {
                            print("Firebase Auth 계정 삭제 실패: \(error)")
                            completion(false)
                        } else {
                            AuthSession.clearProvider()
                            if !dataSuccess {
                                print("⚠️ Firestore 데이터 일부 삭제 실패")
                            }
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 재인증
    private func performReauthentication(
        provider: SocialLoginProvider,
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        switch provider {
        case .kakao:
            reauthenticateWithKakao(completion: completion)
        case .google:
            reauthenticateWithGoogle(from: viewController, completion: completion)
        case .apple:
            reauthenticateWithApple(from: viewController, completion: completion)
        case .none:
            completion(false)
        }
    }
    
    private func reauthenticateWithKakao(completion: @escaping (Bool) -> Void) {
        KakaoLoginManager.shared.login { result in
            switch result {
            case .success:
                completion(true)
            case .failure(let error):
                if case .userCancelled = error {
                    completion(false)
                    return
                }
                completion(false)
            }
        }
    }
    
    private func reauthenticateWithGoogle(
        from viewController: UIViewController,
        completion: @escaping (Bool) -> Void
    ) {
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error = error {
                print("Google 재인증 실패: \(error)")
                completion(false)
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                completion(false)
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
                if let error = error {
                    print("Firebase Google 재인증 실패: \(error)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    private func reauthenticateWithApple(from viewController: UIViewController,
                                         completion: @escaping (Bool) -> Void) {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        
        let delegate = AppleReauthDelegate(nonce: nonce) { [weak self] success in
            completion(success)
            self?.appleReauthDelegate = nil
            self?.appleAuthController = nil
        }
        
        controller.delegate = delegate
        controller.presentationContextProvider = delegate
        
        self.appleReauthDelegate = delegate
        self.appleAuthController = controller
        
        controller.performRequests()
    }
    
    // MARK: - Firestore 데이터 삭제
    private func deleteUserData(userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let collections = FirestoreCollection.allCases.map(\.rawValue)
        
        let group = DispatchGroup()
        var hasError = false
        
        // 각 도메인 컬렉션에서 userId 기반 문서 삭제
        for collection in collections {
            group.enter()
            db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    
                    if let error = error {
                        print("컬렉션 \(collection) 조회 실패: \(error)")
                        hasError = true
                        group.leave()
                        return
                    }
                    
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        group.leave()
                        return
                    }
                    
                    let batch = db.batch()
                    documents.forEach { batch.deleteDocument($0.reference) }
                    
                    batch.commit { error in
                        if let error = error {
                            print("컬렉션 \(collection) 배치 삭제 실패: \(error)")
                            hasError = true
                        }
                        group.leave()
                    }
                }
        }
        
        // users 컬렉션 문서 삭제
        group.enter()
        db.collection("users").document(userId).delete { error in
            if let error = error {
                print("users 문서 삭제 실패: \(error)")
                hasError = true
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(!hasError)
        }
    }
    
    // MARK: - 소셜 계정 unlink / 로그아웃
    private func unlinkSocialAccount(
        provider: SocialLoginProvider,
        completion: @escaping (Bool) -> Void
    ) {
        switch provider {
        case .kakao:
            KakaoLoginManager.shared.unlink { success in
                completion(success)
            }
        case .google:
            // 구글은 Firebase 계정 삭제 전에 signOut
            GIDSignIn.sharedInstance.signOut()
            completion(true)
        case .apple, .none:
            // 애플은 실제 "unlink" 개념이 애매해서 Firebase 계정 삭제로 정리
            completion(true)
        }
    }
    
    // MARK: - 헬퍼 메서드들 (nonce / sha256)
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple 재인증 델리게이트
private class AppleReauthDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    private let nonce: String
    private let completion: (Bool) -> Void
    
    init(nonce: String, completion: @escaping (Bool) -> Void) {
        self.nonce = nonce
        self.completion = completion
        super.init()
    }
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            completion(false)
            return
        }
        
        let credential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        Auth.auth().currentUser?.reauthenticate(with: credential) { _, error in
            DispatchQueue.main.async {
                self.completion(error == nil)
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Apple 재인증 실패: \(error)")
        completion(false)
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}
