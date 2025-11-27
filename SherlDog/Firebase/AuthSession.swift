//
//  AuthSession.swift
//  SherlDog
//
//  Created by Jin Lee on 11/26/25.
//

import Foundation

enum SocialLoginProvider {
    case kakao
    case google
    case apple
    case none
}

enum AuthUserDefaultsKey {
    static let isKakaoLoggedIn = "isKakaoLoggedIn"
    static let isGoogleLoggedIn = "isGoogleLoggedIn"
    static let isAppleLoggedIn = "isAppleLoggedIn"
}

struct AuthSession {
    
    static var currentProvider: SocialLoginProvider {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: AuthUserDefaultsKey.isKakaoLoggedIn) { return .kakao }
        if defaults.bool(forKey: AuthUserDefaultsKey.isGoogleLoggedIn) { return .google }
        if defaults.bool(forKey: AuthUserDefaultsKey.isAppleLoggedIn) { return .apple }
        return .none
    }
    
    static func setProvider(_ provider: SocialLoginProvider) {
        let defaults = UserDefaults.standard
        defaults.set(provider == .kakao, forKey: AuthUserDefaultsKey.isKakaoLoggedIn)
        defaults.set(provider == .google, forKey: AuthUserDefaultsKey.isGoogleLoggedIn)
        defaults.set(provider == .apple,  forKey: AuthUserDefaultsKey.isAppleLoggedIn)
    }
    
    static func clearProvider() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: AuthUserDefaultsKey.isKakaoLoggedIn)
        defaults.removeObject(forKey: AuthUserDefaultsKey.isGoogleLoggedIn)
        defaults.removeObject(forKey: AuthUserDefaultsKey.isAppleLoggedIn)
    }
}
