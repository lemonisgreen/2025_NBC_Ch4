//
//  AuthManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import Foundation
import FirebaseAuth
import GoogleSignIn

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
    
    // 로그아웃
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
}
