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
    
    private let kakaoIndexCollectionName = "kakaoUsers"
    private var appleReauthDelegate: AppleReauthDelegate?
    private var appleAuthController: ASAuthorizationController?
    
    // MARK: - 메인 회원탈퇴 메서드
    func deleteAccount(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(false)
            return
        }
        
        let firebaseUID = currentUser.uid
        let provider = AuthSession.currentProvider
        
        // 실제 데이터 삭제에 사용할 ID (AppUserID 우선)
        let appUserId: String = {
            if let appId = AuthSession.currentAppUserId {
                return appId
            } else {
                // 혹시 세션에 appUserId가 안 들어간 경우 대비
                return firebaseUID
            }
        }()
        
        // 재인증
        performReauthentication(provider: provider, from: viewController) { [weak self] reauthSuccess in
            guard let self else { return }
            
            guard reauthSuccess else {
                completion(false)
                return
            }
            
            self.deleteUserData(appUserId: appUserId, firebaseUID: firebaseUID) { dataSuccess in

                guard dataSuccess else {
                    print("Firestore 데이터 삭제 실패. 탈퇴 중단")
                    completion(false)
                    return
                }

                self.unlinkSocialAccount(provider: provider) { _ in

                    Auth.auth().currentUser?.delete { error in
                        if let error = error {
                            print("Firebase Auth 계정 삭제 실패: \(error)")
                            completion(false)
                        } else {
                            AuthSession.clearProvider()
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
    private func deleteUserData(
        appUserId: String,
        firebaseUID: String,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        
        // 카카오면 kakaoUsers/{kakaoId}에서 legacyFirebaseUIDs까지 읽어온다
        if let kakaoId = extractKakaoId(from: appUserId) {
            let indexRef = db.collection(kakaoIndexCollectionName).document(kakaoId)
            
            indexRef.getDocument { [weak self] snapshot, error in
                guard let self else { completion(false); return }
                
                if let error = error {
                    print("⚠️ kakaoUsers(\(kakaoId)) 조회 실패:", error)
                }
                
                let legacyUIDs = (snapshot?.data()?["legacyFirebaseUIDs"] as? [String]) ?? []
                self.deleteUserDataInternal(
                    db: db,
                    appUserId: appUserId,
                    firebaseUID: firebaseUID,
                    legacyFirebaseUIDs: legacyUIDs,
                    kakaoId: kakaoId,
                    completion: completion
                )
            }
            
        } else {
        
            deleteUserDataInternal(
                db: db,
                appUserId: appUserId,
                firebaseUID: firebaseUID,
                legacyFirebaseUIDs: [],
                kakaoId: nil,
                completion: completion
            )
        }
    }
    
    private func deleteUserDataInternal(
        db: Firestore,
        appUserId: String,
        firebaseUID: String,
        legacyFirebaseUIDs: [String],
        kakaoId: String?,
        completion: @escaping (Bool) -> Void
    ) {

        let idCandidates = Array(Set([appUserId, firebaseUID] + legacyFirebaseUIDs))
        
        let group = DispatchGroup()
        var hasError = false
        
        // 1) users 컬렉션: 문서ID가 firebaseUID(raw)라서 legacyUID들도 전부 삭제해야 함
        let userDocIdsToDelete = Array(Set([firebaseUID] + legacyFirebaseUIDs))
        for uid in userDocIdsToDelete {
            group.enter()
            db.collection(FirestoreCollection.users.rawValue)
                .document(uid)
                .delete { error in
                    if let error = error {
                        let ns = error as NSError
                        if !(ns.domain == FirestoreErrorDomain &&
                             ns.code == FirestoreErrorCode.notFound.rawValue) {
                            print("users 문서 삭제 실패(\(uid)):", error)
                            hasError = true
                        }
                    } else {
                        print("✅ users 문서 삭제 완료 (\(uid))")
                    }
                    group.leave()
                }
        }
        
        // 2) HumanProfile: appUserId + legacyUID들까지 삭제
        group.enter()
        deleteHumanProfileDocuments(
            db: db,
            docIds: Array(Set([appUserId, firebaseUID] + legacyFirebaseUIDs))
        ) { success in
            if !success { hasError = true }
            group.leave()
        }
        
        let domainCollections: [FirestoreCollection] = FirestoreCollection.allCases
        
        for collection in domainCollections {
            group.enter()
            deleteInCollection(
                db: db,
                collection: collection,
                idCandidates: idCandidates
            ) { success in
                if !success { hasError = true }
                group.leave()
            }
        }
        
        // 4) kakao_users/{kakaoId} 삭제 (카카오 유저일 때만)
        if let kakaoId = kakaoId {
            group.enter()
            db.collection(kakaoIndexCollectionName)
                .document(kakaoId)
                .delete { error in
                    if let error = error {
                        let ns = error as NSError
                        if !(ns.domain == FirestoreErrorDomain &&
                             ns.code == FirestoreErrorCode.notFound.rawValue) {
                            print("kakaoUsers 문서 삭제 실패(\(kakaoId)):", error)
                            hasError = true
                        }
                    } else {
                        print("✅ kakaoUsers 문서 삭제 완료 (\(kakaoId))")
                    }
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            completion(!hasError)
        }
    }
    
    private func deleteHumanProfileDocuments(
        db: Firestore,
        docIds: [String],
        completion: @escaping (Bool) -> Void
    ) {
        let group = DispatchGroup()
        var allSuccess = true
        
        for docId in docIds {
            group.enter()
            db.collection(FirestoreCollection.humanProfile.rawValue)
                .document(docId)
                .delete { error in
                    if let error = error {
                        let ns = error as NSError
                        if !(ns.domain == FirestoreErrorDomain &&
                             ns.code == FirestoreErrorCode.notFound.rawValue) {
                            print("HumanProfile 문서 삭제 실패 (\(docId)):", error)
                            allSuccess = false
                        }
                    } else {
                        print("✅ HumanProfile 문서 삭제 완료 (\(docId))")
                    }
                    group.leave()
                }
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
    
    private func deleteInCollection(
        db: Firestore,
        collection: FirestoreCollection,
        idCandidates: [String],
        completion: @escaping (Bool) -> Void
    ) {
        let fieldNames: [String]
        switch collection {
        case .petProfile: fieldNames = ["userId"]
        case .walkResult, .clues: fieldNames = ["userID", "userId"]
        case .reportLog: fieldNames = ["reporterId", "targetUserId"]
        case .blockLog: fieldNames = ["documentId"]
        case .detectiveMate: fieldNames = ["userId"]
        case .invLogBoard: fieldNames = ["userId"]
        default:
            completion(true); return
        }
        
        let group = DispatchGroup()
        var allSuccess = true
        
        func queryAndDelete(field: String, id: String) {
            group.enter()
            db.collection(collection.rawValue)
                .whereField(field, isEqualTo: id)
                .getDocuments { (snapshot: QuerySnapshot?, error: Error?) in
                    if let error = error {
                        print("⚠️ \(collection.rawValue) (\(field) == \(id)) 조회 실패:", error)
                        allSuccess = false
                        group.leave()
                        return
                    }
                    
                    let docs = snapshot?.documents ?? []
                    guard !docs.isEmpty else {
                        group.leave()
                        return
                    }
                    
                    let batch = db.batch()
                    docs.forEach { batch.deleteDocument($0.reference) }
                    
                    batch.commit { (error: Error?) in
                        if let error = error {
                            print("⚠️ \(collection.rawValue) (\(field) == \(id)) 삭제 실패:", error)
                            allSuccess = false
                        } else {
                            print("✅ \(collection.rawValue) - \(field) == \(id) 문서 \(docs.count)개 삭제")
                        }
                        group.leave()
                    }
                }
        }
        
        for field in fieldNames {
            for id in idCandidates {
                queryAndDelete(field: field, id: id)
            }
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
    
    private func extractKakaoId(from appUserId: String) -> String? {
        // appUserId 예: "kakao:4303230810"
        guard appUserId.hasPrefix("kakao:") else { return nil }
        return String(appUserId.dropFirst("kakao:".count))
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
