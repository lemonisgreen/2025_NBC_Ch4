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
import GoogleSignIn
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        // 구글 로그인 설정
        setupGoogleSignIn()
        
        // 카카오 SDK 초기화
        setupKakaoSDK()
        
        // IQ 키보드 작동 코드
        IQKeyboardManager.shared.isEnabled = true
        
        // NotificationDelegate
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    private func setupGoogleSignIn() {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            return
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientId)
    }
    
    private func setupKakaoSDK() {
        if var appKey = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
            appKey = appKey.trimmingCharacters(in: .whitespacesAndNewlines)
            appKey = appKey.replacingOccurrences(of: "{", with: "")
            appKey = appKey.replacingOccurrences(of: "}", with: "")
            
            if appKey.count == 32 {
                KakaoSDK.initSDK(appKey: appKey)
            }
        }
    }

    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // 구글 로그인 처리
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // 카카오 로그인 처리
        if AuthApi.isKakaoTalkLoginUrl(url) {
            return AuthController.handleOpenUrl(url: url)
        }
        
        return false
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // 필요 시 정리
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.badge, .banner, .sound]
    }
}
