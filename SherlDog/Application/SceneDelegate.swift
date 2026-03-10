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
                    // 카카오 유저 정보 -> kakaoId / AppUserID 복구
                    UserApi.shared.me { user, error in
                        if let error = error {
                            print("⚠️ Kakao me() 실패: \(error)")
                            completion()
                            return
                        }
                        
                        guard let kakaoId = user?.id else {
                            print("⚠️ Kakao 사용자 ID를 가져오지 못했습니다.")
                            completion()
                            return
                        }
                        
                        let appUserId = AppUserID.fromKakaoID(kakaoId)
                        AuthSession.setAppUserId(appUserId)
                        
                        // ✅ 앱 시작 시에도 kakaoId 기반 마이그레이션 실행
                        UserDataMigrationManager.shared.migrateAfterKakaoLogin(
                            kakaoId: kakaoId,
                            appUserId: appUserId,
                            currentFirebaseUID: firebaseUID
                        ) { _ in
                            completion()
                        }
                    }
                    return
                } else {
                    // 카카오 토큰도 없으면 세션 클리어
                    AuthSession.clearProvider()
                    completion()
                    return
                }
                
            case .google, .apple:
                // 구글/애플은 UID 기반으로만 관리하고 있어서
                // 로그인 유지된 경우에는 기존 방식대로 AppUserID를 UID에서 유도
                let appUserId = AppUserID.fromFirebaseUID(firebaseUID)
                AuthSession.setAppUserId(appUserId)
                completion()
                return
                
            case .none:
                completion()
                return
            }
        }
        
        // Firebase currentUser 자체가 없는 경우
        completion()
    }
    
    // MARK: - 초기 화면 결정
    private func determineInitialViewController() -> UIViewController {
        
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "onboardingCompleted")
        
        if !hasCompletedOnboarding {
            return createOnboardingVC()
        }
        
        let isLoggedIn = AuthSession.currentProvider != .none
        let hasAppUserId = AuthSession.currentAppUserId != nil
        
        guard isLoggedIn, hasAppUserId else {
            return createLoginVC()
        }
        
        return createMainVC()
    }
    
    // MARK: - Factory
    private func createOnboardingVC() -> UIViewController {
        return OnboardingViewController()
    }
    
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
