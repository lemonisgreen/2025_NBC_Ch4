//
//  AppUserID.swift
//  SherlDog
//
//  Created by JIN LEE on 11/27/25.
//

import Foundation

/// 앱에서 사용하는 유저 식별자
///
/// - 카카오: kakao:<fromKakaoID>
/// - Firebase(구글/애플): firebase:<fromFirebaseUID>

enum AppUserID {
    
    static func fromKakaoID(_ kakaoID: Int64) -> String {
        return "kakao:\(kakaoID)"
    }
    
    static func fromFirebaseUID(_ uid: String) -> String {
        return "firebase:\(uid)"
    }
}
