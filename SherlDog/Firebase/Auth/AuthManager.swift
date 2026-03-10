//
//  AuthManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import KakaoSDKUser
import KakaoSDKAuth
import AuthenticationServices

private struct AppleUserInfo {
    let userIdentifier: String
    let fullName: String?
    let email: String?
}

final class AuthManager {
    
    static let shared = AuthManager()
    private init() {}
    
    // 현재 로그인 상태 확인
    func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    var currentUID: String? {
        return Auth.auth().currentUser?.uid
    }
    
    // MARK: - Login
    
    func loginWithKakao(completion: @escaping (Result<Void, Error>) -> Void) {
        let completionBlock: (OAuthToken?, Error?) -> Void = { token, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard token != nil else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "카카오 인증 토큰을 가져오지 못했습니다."])))
                }
                return
            }
            
            UserApi.shared.me { user, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let user else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "사용자 정보를 가져올 수 없습니다."])))
                    }
                    return
                }
                
                let userInfo = KakaoUserInfo(from: user)
                let appUserId = AppUserID.fromKakaoID(userInfo.id)
                
                Auth.auth().signInAnonymously { [weak self] authResult, error in
                    guard let self else { return }
                    
                    if let error = error {
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                        return
                    }
                    
                    guard let firebaseUser = authResult?.user else {
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase 인증 실패"])))
                        }
                        return
                    }
                    
                    self.saveKakaoUserToFirestore(
                        firebaseUser: firebaseUser,
                        kakaoUserInfo: userInfo,
                        appUserId: appUserId,
                        completion: completion
                    )
                }
            }
        }
        
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk(completion: completionBlock)
        } else {
            UserApi.shared.loginWithKakaoAccount(completion: completionBlock)
        }
    }
    
    func loginWithGoogle(
        presentingViewController: UIViewController,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "인증 토큰을 가져오지 못했습니다"])))
                }
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    DispatchQueue.main.async {
                        completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase 사용자 정보를 가져오지 못했습니다"])))
                    }
                    return
                }
                
                self.saveGoogleUserToFirestore(
                    firebaseUser: firebaseUser,
                    googleUser: user,
                    completion: completion
                )
            }
        }
    }
    
    func loginWithApple(
        appleIDCredential: ASAuthorizationAppleIDCredential,
        rawNonce: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let appleIDToken = appleIDCredential.identityToken else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
            }
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to serialize token string from data"])))
            }
            return
        }
        
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: rawNonce
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Firebase 사용자 정보를 가져오지 못했습니다"])))
                }
                return
            }
            
            let fullName = PersonNameComponentsFormatter()
                .string(from: appleIDCredential.fullName ?? PersonNameComponents())
            let appleUserInfo = AppleUserInfo(
                userIdentifier: appleIDCredential.user,
                fullName: fullName.isEmpty ? nil : fullName,
                email: appleIDCredential.email
            )
            
            self.saveAppleUserToFirestore(
                firebaseUser: firebaseUser,
                appleUserInfo: appleUserInfo,
                completion: completion
            )
        }
    }
    
    // MARK: - Logout
    
    func logout(completion: @escaping (Bool) -> Void) {
        let provider = AuthSession.currentProvider
        
        let finishOnMain: (Bool) -> Void = { success in
            if success {
                AuthSession.clearProvider()
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
        
        switch provider {
        case .kakao:
            KakaoLoginManager.shared.logout { [weak self] _ in
                guard let self else { return }
                finishOnMain(self.firebaseLogout())
            }
            
        case .google:
            GIDSignIn.sharedInstance.signOut()
            finishOnMain(firebaseLogout())
            
        case .apple:
            finishOnMain(firebaseLogout())
            
        case .none:
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    private func firebaseLogout() -> Bool {
        do {
            try Auth.auth().signOut()
            return true
        } catch {
            print("Firebase 로그아웃 실패: \(error)")
            return false
        }
    }
    
    // MARK: - Update or insert userData
    
    private func upsertUserDocumentPreservingCreatedAt(
        firebaseUID: String,
        userData: [String: Any],
        completion: @escaping (Error?) -> Void
    ) {
        let db = Firestore.firestore()
        let ref = db.collection("users").document(firebaseUID)
        
        db.runTransaction({ txn, errPtr -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try txn.getDocument(ref)
            } catch {
                errPtr?.pointee = error as NSError
                return nil
            }
            
            var payload = userData
            payload["lastLoginAt"] = FieldValue.serverTimestamp()
            
            if snap.exists {
                payload.removeValue(forKey: "createdAt")
                txn.setData(payload, forDocument: ref, merge: true)
            } else {
                payload["createdAt"] = FieldValue.serverTimestamp()
                txn.setData(payload, forDocument: ref, merge: false)
            }
            
            return nil
        }) { _, error in
            completion(error)
        }
    }
    
    private func saveKakaoUserToFirestore(
        firebaseUser: FirebaseAuth.User,
        kakaoUserInfo: KakaoUserInfo,
        appUserId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let userData: [String: Any] = [
            "userId": appUserId,
            "kakaoId": kakaoUserInfo.id,
            "nickname": kakaoUserInfo.nickname ?? "",
            "email": kakaoUserInfo.email ?? "",
            "profileImageUrl": kakaoUserInfo.profileImageUrl ?? "",
            "provider": "kakao",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        upsertUserDocumentPreservingCreatedAt(firebaseUID: firebaseUser.uid, userData: userData) { error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            AuthSession.setProvider(.kakao)
            AuthSession.setAppUserId(appUserId)
            
            UserDataMigrationManager.shared.migrateAfterKakaoLogin(
                kakaoId: kakaoUserInfo.id,
                appUserId: appUserId,
                currentFirebaseUID: firebaseUser.uid
            ) { _ in
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            }
        }
    }
    
    private func saveGoogleUserToFirestore(
        firebaseUser: FirebaseAuth.User,
        googleUser: GIDGoogleUser,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let appUserId = AppUserID.fromFirebaseUID(firebaseUser.uid)
        let userData: [String: Any] = [
            "userId": appUserId,
            "googleId": googleUser.userID ?? "",
            "nickname": firebaseUser.displayName ?? "",
            "email": firebaseUser.email ?? "",
            "profileImageUrl": firebaseUser.photoURL?.absoluteString ?? "",
            "provider": "google",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        upsertUserDocumentPreservingCreatedAt(firebaseUID: firebaseUser.uid, userData: userData) { error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            AuthSession.setProvider(.google)
            AuthSession.setAppUserId(appUserId)
            
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
    
    private func saveAppleUserToFirestore(
        firebaseUser: FirebaseAuth.User,
        appleUserInfo: AppleUserInfo,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let appUserId = AppUserID.fromFirebaseUID(firebaseUser.uid)
        let userData: [String: Any] = [
            "userId": appUserId,
            "appleId": appleUserInfo.userIdentifier,
            "nickname": appleUserInfo.fullName ?? firebaseUser.displayName ?? "",
            "email": appleUserInfo.email ?? firebaseUser.email ?? "",
            "profileImageUrl": "",
            "provider": "apple",
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        upsertUserDocumentPreservingCreatedAt(firebaseUID: firebaseUser.uid, userData: userData) { error in
            if let error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            AuthSession.setProvider(.apple)
            AuthSession.setAppUserId(appUserId)
            
            DispatchQueue.main.async {
                completion(.success(()))
            }
        }
    }
}
