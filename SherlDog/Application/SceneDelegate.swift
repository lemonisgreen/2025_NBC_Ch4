//
//  SceneDelegate.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit
import FirebaseAuth
import KakaoSDKUser
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        
        if let url = connectionOptions.urlContexts.first?.url {
            if AuthApi.isKakaoTalkLoginUrl(url) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
        
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        let splashVC = SplashViewController()
        window.rootViewController = splashVC
        window.makeKeyAndVisible()
        
        // 스플래시 끝나면 초기화면 결정
        splashVC.onSplashEnd = { [weak self] in
            self?.restoreSessionIfNeeded { [weak self] in
                guard let self else { return }
                let vc = self.determineInitialViewController()
                self.window?.rootViewController = vc
                self.window?.makeKeyAndVisible()
            }
        }
    }
    
    // MARK: - 로그인 세션 복구
    private func restoreSessionIfNeeded(completion: @escaping () -> Void) {
        
        // 1) Firebase 세션이 있는지 먼저 확인
        if let currentUser = Auth.auth().currentUser {
            let firebaseUID = currentUser.uid
            
            switch AuthSession.currentProvider {
            case .kakao:
                // Kakao 토큰 살아 있는지 체크
                if AuthApi.hasToken() {
                    // 카카오 유저 정보 -> AppUserID 복구
                    UserApi.shared.me { user, error in
                        if let id = user?.id {
                            let appUserId = AppUserID.fromKakaoID(id)
                            AuthSession.setAppUserId(appUserId)
                            
                            // 마이그레이션 호출
                            UserDataMigrationManager.shared.migrateIfNeeded(
                                firebaseUID: firebaseUID
                            ) {
                                completion()
                            }
                        } else {
                            completion()
                        }
                    }
                    return
                } else {
                    AuthSession.clearProvider()
                    completion()
                    return
                }
                
            case .google, .apple:
                
                let appUserId = AppUserID.fromFirebaseUID(firebaseUID)
                AuthSession.setAppUserId(appUserId)
                completion()
                return
                
            case .none:
                completion()
                return
            }
        }
        completion()
    }
    
    // MARK: - 초기 화면 결정
    private func determineInitialViewController() -> UIViewController {
        
        let isLoggedIn = AuthSession.currentProvider != .none
        let hasAppUserId = AuthSession.currentAppUserId != nil
        
        guard isLoggedIn, hasAppUserId else {
            return createLoginVC()
        }
        
        return createMainVC()
    }
    
    // MARK: - Factory
    private func createLoginVC() -> UIViewController {
        return UINavigationController(rootViewController: LoginViewController())
    }
    
    private func createMainVC() -> UIViewController {
        return BottomTabBarController()
    }
}

// MARK: - Kakao / 기타 URL 처리
extension SceneDelegate {
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        
        //카카오 로그인 콜백 처리
        if AuthApi.isKakaoTalkLoginUrl(url) {
            _ = AuthController.handleOpenUrl(url: url)
            return
        }
    }
}
