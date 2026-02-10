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

enum AuthSession {
    
    private static let providerKey = "auth.provider"
    private static let appUserIdKey = "auth.appUserId"
    
    static var currentProvider: SocialLoginProvider {
        let raw = UserDefaults.standard.string(forKey: providerKey)
        switch raw {
        case "kakao": return .kakao
        case "google": return .google
        case "apple": return .apple
        default: return .none
        }
    }
    
    static func setProvider(_ provider: SocialLoginProvider) {
        let raw: String
        switch provider {
        case .kakao: raw = "kakao"
        case .google: raw = "google"
        case .apple: raw = "apple"
        case .none: raw = "none"
        }
        UserDefaults.standard.set(raw, forKey: providerKey)
    }
    
    /// 현재 로그인한 유저의 AppUserID 
    static var currentAppUserId: String? {
        return UserDefaults.standard.string(forKey: appUserIdKey)
    }
    
    static func setAppUserId(_ id: String) {
        UserDefaults.standard.set(id, forKey: appUserIdKey)
    }
    
    static func clear() {
        UserDefaults.standard.removeObject(forKey: providerKey)
        UserDefaults.standard.removeObject(forKey: appUserIdKey)
    }
    
    static func clearProvider() {
        UserDefaults.standard.removeObject(forKey: providerKey)
        UserDefaults.standard.removeObject(forKey: appUserIdKey)
    }
}
