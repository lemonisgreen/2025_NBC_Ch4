//
//  SceneDelegate.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit
import KakaoSDKAuth
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        
        // 로그인 상태 확인 후 초기 화면 결정
        let initialViewController = determineInitialViewController()
        
        window.rootViewController = RegistrationViewController()
        self.window = window
        window.makeKeyAndVisible()
    }
    
    // MARK: - 초기 화면 결정
    private func determineInitialViewController() -> UIViewController {
        // Firebase 현재 사용자 확인
        let hasFirebaseUser = Auth.auth().currentUser != nil
        
        // 로컬 로그인 상태 확인
        let isKakaoLoggedIn = UserDefaults.standard.bool(forKey: "isKakaoLoggedIn")
        let isGoogleLoggedIn = UserDefaults.standard.bool(forKey: "isGoogleLoggedIn")
        
        // 카카오 토큰 유효성 확인 (카카오 로그인인 경우)
        if isKakaoLoggedIn && hasFirebaseUser {
            // 카카오 토큰이 유효한지 확인
            if KakaoLoginManager.shared.isLoggedIn() {
                return createMainViewController()
            } else {
                // 토큰이 만료된 경우 로그인 정보 정리
                clearExpiredLoginInfo()
                return createLoginViewController()
            }
        }
        
        // 구글 로그인인 경우 또는 다른 로그인 방식
        if (isGoogleLoggedIn && hasFirebaseUser) {
            return createMainViewController()
        }
        
        // 로그인되어 있지 않은 경우
        return createLoginViewController()
    }
    
    // MARK: - ViewController 생성
    private func createLoginViewController() -> UIViewController {
        let loginVC = LoginViewController()
        let navigationController = UINavigationController(rootViewController: loginVC)
        return navigationController
    }
    
    private func createMainViewController() -> UIViewController {
        // 여기서 메인 화면
        let mainVC = PetProfileViewController()
        let navigationController = UINavigationController(rootViewController: mainVC)
        return navigationController
    }
    
    // MARK: - 만료된 로그인 정보 정리
    private func clearExpiredLoginInfo() {
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
        
        // Firebase 로그아웃
        try? Auth.auth().signOut()
    }
    
    // MARK: - Lifecycle Methods
    func sceneDidDisconnect(_ scene: UIScene) {
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // 앱이 활성화될 때 로그인 상태 재확인 (선택사항)
        validateLoginState()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
    
    // MARK: - 로그인 상태 검증 (선택사항)
    private func validateLoginState() {
        // 카카오 로그인 상태인 경우 토큰 유효성 재확인
        if UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") {
            KakaoLoginManager.shared.validateToken { isValid in
                if !isValid {
                    DispatchQueue.main.async {
                        self.handleInvalidToken()
                    }
                }
            }
        }
    }
    
    private func handleInvalidToken() {
        // 토큰이 무효한 경우 로그인 화면으로 이동
        clearExpiredLoginInfo()
        
        let loginVC = createLoginViewController()
        
        // 부드럽게 화면 전환
        UIView.transition(with: window!, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.window?.rootViewController = loginVC
        })
    }
    
    // MARK: - URL Handling for Kakao Login
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
}
