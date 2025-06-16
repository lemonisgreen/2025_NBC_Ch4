//
//  AuthManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/16/25.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

class AuthManager {
    static let shared = AuthManager()
    
    private init() {}
    
    // 현재 로그인 상태 확인
    func isLoggedIn() -> Bool {
        return Auth.auth().currentUser != nil &&
               (UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") ||
                UserDefaults.standard.bool(forKey: "isGoogleLoggedIn"))
    }
    
    // 로그아웃
    func logout(completion: @escaping (Bool) -> Void) {
        // 카카오 로그아웃
        if UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") {
            KakaoLoginManager.shared.logout { success in
                self.completeLogout(completion: completion)
            }
        }
        // 구글 로그아웃
        else if UserDefaults.standard.bool(forKey: "isGoogleLoggedIn") {
            GIDSignIn.sharedInstance.signOut()
            completeLogout(completion: completion)
        }
        else {
            completeLogout(completion: completion)
        }
    }
    
    private func completeLogout(completion: @escaping (Bool) -> Void) {
        // Firebase 로그아웃
        do {
            try Auth.auth().signOut()
            clearUserDefaults()
            
            DispatchQueue.main.async {
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
    
    private func clearUserDefaults() {
        let keysToRemove = [
            "isKakaoLoggedIn",
            "isGoogleLoggedIn",
            "userNickname",
            "userEmail",
            "firebaseUID"
        ]
        
        keysToRemove.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // 현재 사용자 정보
    func getCurrentUserInfo() -> (nickname: String?, email: String?, uid: String?) {
        return (
            nickname: UserDefaults.standard.string(forKey: "userNickname"),
            email: UserDefaults.standard.string(forKey: "userEmail"),
            uid: UserDefaults.standard.string(forKey: "firebaseUID")
        )
    }
}
