//
//  SceneDelegate.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: LoginViewController())
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }

    // MARK: - URL Handling for Kakao Login
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            print("🔗 Scene에서 URL 처리: \(url)")
            
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                print("✅ 카카오톡 로그인 URL 감지됨 (Scene)")
                _ = AuthController.handleOpenUrl(url: url)
            } else {
                print("ℹ️ 카카오 URL이 아님 (Scene)")
            }
        }
    }
}
