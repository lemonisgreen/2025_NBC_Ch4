//
//  AppDelegate.swift
//  SherlDog
//
//  Created by 최영락 on 6/4/25.
//

import UIKit
import FirebaseCore
import KakaoSDKCommon
import KakaoSDKAuth

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 카카오 SDK 초기화
        setupKakaoSDK()
        
        return true
    }
    
    private func setupKakaoSDK() {
        
        // Info.plist에서 앱 키 읽기
        if let appKey = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
            
            if appKey.count == 32 {
                KakaoSDK.initSDK(appKey: appKey)
            }
        }
    }

    // MARK: - URL Handling for Kakao Login
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        print("🔗 URL 처리: \(url)")
        
        // 카카오 로그인 URL 처리
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }
        return false
    }

    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
