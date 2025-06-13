//
//  KakaoLoginManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import Foundation
import KakaoSDKAuth
import KakaoSDKUser
import KakaoSDKCommon

// MARK: - KakaoLoginResult
enum KakaoLoginResult {
    case success(user: User)
    case failure(error: KakaoLoginError)
}

// MARK: - KakaoLoginError
enum KakaoLoginError: LocalizedError {
    case userCancelled
    case networkError
    case invalidToken
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "사용자가 로그인을 취소했습니다."
        case .networkError:
            return "네트워크 연결을 확인해주세요."
        case .invalidToken:
            return "로그인 토큰이 유효하지 않습니다."
        case .unknownError(let message):
            return message
        }
    }
}

// MARK: - KakaoLoginManagerDelegate
protocol KakaoLoginManagerDelegate: AnyObject {
    func kakaoLoginDidSucceed(user: User)
    func kakaoLoginDidFail(error: KakaoLoginError)
}

// MARK: - KakaoUserInfo
struct KakaoUserInfo {
    let id: Int64
    let nickname: String?
    let email: String?
    let profileImageUrl: String?
    let thumbnailImageUrl: String?
    
    init(from user: User) {
        self.id = user.id ?? 0
        self.nickname = user.kakaoAccount?.profile?.nickname
        self.email = user.kakaoAccount?.email
        self.profileImageUrl = user.kakaoAccount?.profile?.profileImageUrl?.absoluteString
        self.thumbnailImageUrl = user.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString
    }
}

// MARK: - KakaoLoginManager
class KakaoLoginManager {
    
    static let shared = KakaoLoginManager()
    
    // MARK: - Properties
    weak var delegate: KakaoLoginManagerDelegate?
    private var currentUserInfo: KakaoUserInfo?
    private init() {}
    
    /// 카카오 로그인 시작
    func login(completion: ((KakaoLoginResult) -> Void)? = nil) {
        if UserApi.isKakaoTalkLoginAvailable() {
            loginWithKakaoTalk(completion: completion)
        } else {
            loginWithWeb(completion: completion)
        }
    }
    
    /// 로그아웃
    func logout(completion: ((Bool) -> Void)? = nil) {
        UserApi.shared.logout { [weak self] error in
            let success = error == nil
            if success {
                self?.currentUserInfo = nil
                // UserDefaults 정리
                UserDefaults.standard.removeObject(forKey: "isKakaoLoggedIn")
                UserDefaults.standard.removeObject(forKey: "userNickname")
                UserDefaults.standard.removeObject(forKey: "userEmail")
            }
            completion?(success)
        }
    }
    
    /// 연결 해제 (회원탈퇴)
    func unlink(completion: ((Bool) -> Void)? = nil) {
        UserApi.shared.unlink { [weak self] error in
            let success = error == nil
            if success {
                self?.currentUserInfo = nil
                // UserDefaults 정리
                UserDefaults.standard.removeObject(forKey: "isKakaoLoggedIn")
                UserDefaults.standard.removeObject(forKey: "userNickname")
                UserDefaults.standard.removeObject(forKey: "userEmail")
            }
            completion?(success)
        }
    }
    
    /// 현재 로그인 상태 확인
    func isLoggedIn() -> Bool {
        return AuthApi.hasToken()
    }
    
    /// 현재 사용자 정보 반환
    func getCurrentUserInfo() -> KakaoUserInfo? {
        return currentUserInfo
    }
    
    /// 토큰 유효성 검사
    func validateToken(completion: @escaping (Bool) -> Void) {
        guard AuthApi.hasToken() else {
            completion(false)
            return
        }
        
        UserApi.shared.accessTokenInfo { [weak self] tokenInfo, error in
            if let error = error {
                // 토큰이 유효하지 않은 경우 정리
                self?.currentUserInfo = nil
                UserDefaults.standard.removeObject(forKey: "isKakaoLoggedIn")
                completion(false)
            } else {
                if let expiresIn = tokenInfo?.expiresIn {
                    print("토큰 만료까지 남은 시간: \(expiresIn)초")
                }
                completion(true)
            }
        }
    }
    
    /// 저장된 사용자 정보로 현재 사용자 정보 복원
    func restoreUserInfo() {
        guard isLoggedIn(),
              UserDefaults.standard.bool(forKey: "isKakaoLoggedIn") else {
            return
        }
        
        let nickname = UserDefaults.standard.string(forKey: "userNickname")
        let email = UserDefaults.standard.string(forKey: "userEmail")
    }
}

// MARK: - Private Methods
private extension KakaoLoginManager {
    
    /// 카카오톡 앱으로 로그인
    func loginWithKakaoTalk(completion: ((KakaoLoginResult) -> Void)?) {
        UserApi.shared.loginWithKakaoTalk { [weak self] (oauthToken, error) in
            self?.handleLoginResponse(oauthToken: oauthToken, error: error, completion: completion)
        }
    }
    
    /// 웹 브라우저로 로그인
    func loginWithWeb(completion: ((KakaoLoginResult) -> Void)?) {
        UserApi.shared.loginWithKakaoAccount { [weak self] (oauthToken, error) in
            self?.handleLoginResponse(oauthToken: oauthToken, error: error, completion: completion)
        }
    }
    
    /// 로그인 응답 처리
    func handleLoginResponse(oauthToken: OAuthToken?, error: Error?, completion: ((KakaoLoginResult) -> Void)?) {
        if let error = error {
            let kakaoError = processError(error)
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.kakaoLoginDidFail(error: kakaoError)
                completion?(.failure(error: kakaoError))
            }
            return
        }
        
        guard let token = oauthToken else {
            let error = KakaoLoginError.invalidToken
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.kakaoLoginDidFail(error: error)
                completion?(.failure(error: error))
            }
            return
        }
        fetchUserInfo(completion: completion)
    }
    
    /// 사용자 정보 가져오기
    func fetchUserInfo(completion: ((KakaoLoginResult) -> Void)?) {
        UserApi.shared.me { [weak self] (user, error) in
            if let error = error {
                let kakaoError = self?.processError(error) ?? .unknownError(error.localizedDescription)
                DispatchQueue.main.async {
                    self?.delegate?.kakaoLoginDidFail(error: kakaoError)
                    completion?(.failure(error: kakaoError))
                }
                return
            }
            
            guard let user = user else {
                let error = KakaoLoginError.unknownError("사용자 정보를 가져올 수 없습니다.")
                
                DispatchQueue.main.async {
                    self?.delegate?.kakaoLoginDidFail(error: error)
                    completion?(.failure(error: error))
                }
                return
            }
            
            // 사용자 정보 저장
            let userInfo = KakaoUserInfo(from: user)
            self?.currentUserInfo = userInfo
            
            DispatchQueue.main.async {
                self?.delegate?.kakaoLoginDidSucceed(user: user)
                completion?(.success(user: user))
            }
        }
    }
    
    /// 에러 처리
    func processError(_ error: Error) -> KakaoLoginError {
    
        let errorMessage = error.localizedDescription.lowercased()
        
        // 에러 메시지 기반으로 분류
        if errorMessage.contains("cancel") || errorMessage.contains("취소") || errorMessage.contains("cancelled") {
            return .userCancelled
        } else if errorMessage.contains("network") || errorMessage.contains("네트워크") || errorMessage.contains("internet") {
            return .networkError
        } else if errorMessage.contains("token") || errorMessage.contains("토큰") || errorMessage.contains("invalid") {
            return .invalidToken
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
}
