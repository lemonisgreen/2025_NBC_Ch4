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
    
    // MARK: - 메인 회원탈퇴 메서드
    func deleteAccount(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let userId = currentUser.uid
        
        // 재인증 먼저 수행
        performReauthentication(from: viewController) { [weak self] reauthSuccess in
            if !reauthSuccess {
                completion(false)
                return
            }
            
            // 재인증 성공 후 삭제 진행
            self?.deleteUserData(userId: userId) { dataSuccess in
                self?.unlinkSocialAccount { socialSuccess in
                    // Firebase Auth 계정 삭제
                    Auth.auth().currentUser?.delete { error in
                        if let error = error {
                            print("Firebase Auth 계정 삭제 실패: \(error)")
                            completion(false)
                        } else {
                            self?.clearAllUserDefaults()
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - 재인증
    private func performReauthentication(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") {
            reauthenticateWithKakao(completion: completion)
        } else if UserDefaults.standard.bool(forKey: "isGoogleLoggedIn") {
            reauthenticateWithGoogle(from: viewController, completion: completion)
        } else if UserDefaults.standard.bool(forKey: "isAppleLoggedIn") {
            reauthenticateWithApple(from: viewController, completion: completion)
        } else {
            completion(false)
        }
    }
    
    private func reauthenticateWithKakao(completion: @escaping (Bool) -> Void) {
        KakaoLoginManager.shared.login { result in
            switch result {
            case .success(_):
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
    
    private func reauthenticateWithGoogle(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
            if let error = error {
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
                completion(error == nil)
            }
        }
    }
    
    private func reauthenticateWithApple(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = AppleReauthDelegate(nonce: nonce, completion: completion)
        authorizationController.delegate = delegate
        authorizationController.presentationContextProvider = delegate
        authorizationController.performRequests()
    }
    
    // MARK: - 데이터 삭제
    private func deleteUserData(userId: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let collectionsToDelete = SDLiteral.CollectionName.allCases.map { $0.rawValue }
        
        var deletionTasks = 0
        let totalTasks = collectionsToDelete.count
        var hasError = false
        
        for collection in collectionsToDelete {
            db.collection(collection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    defer {
                        deletionTasks += 1
                        if deletionTasks == totalTasks {
                            completion(!hasError)
                        }
                    }
                    
                    if let error = error {
                        print("컬렉션 \(collection) 조회 실패: \(error)")
                        hasError = true
                        return
                    }
                    
                    guard let documents = snapshot?.documents else { return }
                    
                    let batch = db.batch()
                    for document in documents {
                        batch.deleteDocument(document.reference)
                    }
                    
                    if !documents.isEmpty {
                        batch.commit { error in
                            if let error = error {
                                print("배치 삭제 실패: \(error)")
                                hasError = true
                            }
                        }
                    }
                }
        }
        db.collection("users").document(userId).delete()
    }
    
    private func unlinkSocialAccount(completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") {
            KakaoLoginManager.shared.unlink { success in
                completion(success)
            }
        } else if UserDefaults.standard.bool(forKey: "isGoogleLoggedIn") {
            GIDSignIn.sharedInstance.signOut()
            completion(true)
        } else if UserDefaults.standard.bool(forKey: "isAppleLoggedIn") {
            completion(true)
        } else {
            completion(true)
        }
    }
    
    private func clearAllUserDefaults() {
        let keysToRemove = [
            "isKakaoLoggedIn",
            "isGoogleLoggedIn",
            "isAppleLoggedIn",
            "userNickname",
            "userEmail",
            "firebaseUID"
        ]
        
        keysToRemove.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: - 헬퍼 메서드들
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
            
            randoms.forEach { random in
                if remainingLength == 0 { return }
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
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
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
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            guard let appleIDToken = appleIDCredential.identityToken,
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
        } else {
            completion(false)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
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
