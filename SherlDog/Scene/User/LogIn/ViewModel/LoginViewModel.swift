//
//  AuthManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import KakaoSDKUser
import KakaoSDKAuth
import AuthenticationServices
import CryptoKit

final class LoginViewModel: NSObject {
    
    // MARK: - Input / Output
    struct Input {
        let kakaoTap: AnyObserver<Void>
        let googleTap: AnyObserver<Void>
        let appleTap: AnyObserver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let navigateToPetProfile: Signal<Void>
        let navigateToMain: Signal<Void>
        let showError: Signal<String>
        let showAlert: Signal<String>
    }
    
    // MARK: - Subjects
    private let kakaoTapSubject = PublishSubject<Void>()
    private let googleTapSubject = PublishSubject<Void>()
    private let appleTapSubject = PublishSubject<Void>()
    
    private let isLoadingSubject = BehaviorSubject<Bool>(value: false)
    private let navigateToPetProfileSubject = PublishSubject<Void>()
    private let navigateToMainSubject = PublishSubject<Void>()
    private let showErrorSubject = PublishSubject<String>()
    private let showAlertSubject = PublishSubject<String>()
    
    private let disposeBag = DisposeBag()
    
    // 애플 로그인용 nonce
    private var currentNonce: String?
    
    // MARK: - Exposed IO
    lazy var input: Input = {
        Input(
            kakaoTap: kakaoTapSubject.asObserver(),
            googleTap: googleTapSubject.asObserver(),
            appleTap: appleTapSubject.asObserver()
        )
    }()
    
    lazy var output: Output = {
        Output(
            isLoading: isLoadingSubject.asDriver(onErrorJustReturn: false),
            navigateToPetProfile: navigateToPetProfileSubject.asSignal(onErrorSignalWith: .empty()),
            navigateToMain: navigateToMainSubject.asSignal(onErrorSignalWith: .empty()),
            showError: showErrorSubject.asSignal(onErrorSignalWith: .empty()),
            showAlert: showAlertSubject.asSignal(onErrorSignalWith: .empty())
        )
    }()
    
    // MARK: - Init
    override init() {
        super.init()
        bindInputs()
    }
    
    private func bindInputs() {
        kakaoTapSubject
            .bind { [weak self] in self?.loginWithKakao() }
            .disposed(by: disposeBag)
        
        googleTapSubject
            .bind { [weak self] in self?.loginWithGoogle() }
            .disposed(by: disposeBag)
        
        appleTapSubject
            .bind { [weak self] in self?.loginWithApple() }
            .disposed(by: disposeBag)
    }
}

// MARK: - 공통 유틸
extension LoginViewModel {
    
    /// 이미 로딩 중이면 false 반환하고 아무것도 안 함
    @discardableResult
    private func beginLoadingIfPossible() -> Bool {
        let isLoading = (try? isLoadingSubject.value()) ?? false
        guard !isLoading else { return false }
        isLoadingSubject.onNext(true)
        return true
    }
    
    private func endLoading() {
        isLoadingSubject.onNext(false)
    }
    
    private func checkPetProfiles() {
        guard let appUserId = AuthSession.currentAppUserId else {
            navigateToPetProfileSubject.onNext(())
            return
        }
        
        FirestoreManager.shared.fetchQuery(
            FirestoreQuery<PetProfile>(
                collection: .petProfile,
                type: .whereField(field: "userId", value: appUserId)
            )
        )
        .observe(on: MainScheduler.instance)
        .subscribe(onSuccess: { [weak self] profiles in
            if profiles.isEmpty {
                self?.navigateToPetProfileSubject.onNext(())
            } else {
                self?.navigateToMainSubject.onNext(())
            }
        }, onFailure: { [weak self] _ in
            self?.navigateToPetProfileSubject.onNext(())
        })
        .disposed(by: disposeBag)
    }
}

// MARK: - Kakao Login
extension LoginViewModel {
    
    /// 카카오 버튼 탭 처리
    private func loginWithKakao() {
        guard beginLoadingIfPossible() else { return }
        
        // 로그인 완료 후 공통 처리 (유저 정보 받아서 Firebase 연동)
        func handleKakaoUser(_ user: KakaoSDKUser.User) {
            let userInfo = KakaoUserInfo(from: user)
            let appUserId = AppUserID.fromKakaoID(userInfo.id)
            self.linkKakaoToFirebase(userInfo: userInfo, appUserId: appUserId)
        }
        
        // Kakao SDK 로그인 completion
        let completion: (KakaoSDKAuth.OAuthToken?, Error?) -> Void = { [weak self] token, error in
            guard let self else { return }
            
            if let error = error {
                self.endLoading()
                let msg = error.localizedDescription.lowercased()
                if msg.contains("cancel") || msg.contains("취소") { return }
                self.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            UserApi.shared.me { user, error in
                if let error = error {
                    self.endLoading()
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                guard let user = user else {
                    self.endLoading()
                    self.showErrorSubject.onNext("사용자 정보를 가져올 수 없습니다.")
                    return
                }
                
                let userInfo = KakaoUserInfo(from: user)
                let appUserId = AppUserID.fromKakaoID(userInfo.id)
                self.linkKakaoToFirebase(userInfo: userInfo, appUserId: appUserId)
            }
        }
        
        // 카카오톡 앱 가능하면 톡으로, 아니면 계정 로그인
        if UserApi.isKakaoTalkLoginAvailable() {
            UserApi.shared.loginWithKakaoTalk(completion: completion)
        } else {
            UserApi.shared.loginWithKakaoAccount(completion: completion)
        }
    }
    
    /// Kakao SDK 로그인 성공 후, Firebase 익명 로그인 (Firestore 접근용)
    private func linkKakaoToFirebase(userInfo: KakaoUserInfo, appUserId: String) {
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            guard let self else { return }
            
            if let error = error {
                self.endLoading()
                self.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                self.endLoading()
                self.showErrorSubject.onNext("Firebase 인증 실패")
                return
            }
            
            self.saveKakaoUserToFirestore(
                firebaseUser: firebaseUser,
                kakaoUserInfo: userInfo,
                appUserId: appUserId
            )
        }
    }
    
    /// Firestore users 컬렉션에 Kakao 유저 정보 저장
    private func saveKakaoUserToFirestore(
        firebaseUser: FirebaseAuth.User,
        kakaoUserInfo: KakaoUserInfo,
        appUserId: String
    ) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "userId": appUserId,
            "kakaoId": kakaoUserInfo.id,
            "nickname": kakaoUserInfo.nickname ?? "",
            "email": kakaoUserInfo.email ?? "",
            "profileImageUrl": kakaoUserInfo.profileImageUrl ?? "",
            "provider": "kakao",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users")
            .document(firebaseUser.uid)
            .setData(userData, merge: true) { [weak self] error in
                guard let self else { return }
                self.endLoading()
                
                if let error = error {
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                AuthSession.setProvider(.kakao)
                AuthSession.setAppUserId(appUserId)
                
                // 현재 Firebase UID를 기반으로 마이그레이션 시도
                if let uid = Auth.auth().currentUser?.uid {
                    UserDataMigrationManager.shared.migrateIfNeeded(firebaseUID: uid) { [weak self] in
                        // 마이그레이션이 끝난 뒤에 펫 프로필 체크
                        self?.checkPetProfiles()
                    }
                } else {
                    // UID가 없을 일은 거의 없지만, 혹시 몰라서 예비 처리
                    self.checkPetProfiles()
                }
            }
    }
}

// MARK: - Google Login
extension LoginViewModel {
    
    private func loginWithGoogle() {
        guard beginLoadingIfPossible() else { return }
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            endLoading()
            showErrorSubject.onNext("화면 전환 컨트롤러를 찾을 수 없습니다.")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            guard let self else { return }
            
            if let error = error {
                self.endLoading()
                self.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.endLoading()
                self.showErrorSubject.onNext("인증 토큰을 가져오지 못했습니다")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.endLoading()
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                guard let firebaseUser = authResult?.user else {
                    self.endLoading()
                    self.showErrorSubject.onNext("Firebase 사용자 정보를 가져오지 못했습니다")
                    return
                }
                
                self.saveGoogleUserToFirestore(firebaseUser: firebaseUser, googleUser: user)
            }
        }
    }
    
    private func saveGoogleUserToFirestore(
        firebaseUser: FirebaseAuth.User,
        googleUser: GIDGoogleUser
    ) {
        let db = Firestore.firestore()
        let appUserId = AppUserID.fromFirebaseUID(firebaseUser.uid)
        
        let userData: [String: Any] = [
            "userId": appUserId,
            "googleId": googleUser.userID ?? "",
            "nickname": firebaseUser.displayName ?? "",
            "email": firebaseUser.email ?? "",
            "profileImageUrl": firebaseUser.photoURL?.absoluteString ?? "",
            "provider": "google",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users")
            .document(firebaseUser.uid)
            .setData(userData, merge: true) { [weak self] error in
                guard let self else { return }
                self.endLoading()
                
                if let error = error {
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                AuthSession.setProvider(.google)
                AuthSession.setAppUserId(appUserId)
                
                self.checkPetProfiles()
            }
    }
}

// MARK: - Apple Login
extension LoginViewModel {
    
    private func loginWithApple() {
        guard beginLoadingIfPossible() else { return }
        
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    private func saveAppleUserToFirestore(
        firebaseUser: FirebaseAuth.User,
        appleUserInfo: AppleUserInfo
    ) {
        let db = Firestore.firestore()
        let appUserId = AppUserID.fromFirebaseUID(firebaseUser.uid)
        
        let userData: [String: Any] = [
            "userId": appUserId,
            "appleId": appleUserInfo.userIdentifier,
            "nickname": appleUserInfo.fullName ?? firebaseUser.displayName ?? "",
            "email": appleUserInfo.email ?? firebaseUser.email ?? "",
            "profileImageUrl": "",
            "provider": "apple",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users")
            .document(firebaseUser.uid)
            .setData(userData, merge: true) { [weak self] error in
                guard let self else { return }
                self.endLoading()
                
                if let error = error {
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                AuthSession.setProvider(.apple)
                AuthSession.setAppUserId(appUserId)
                
                self.checkPetProfiles()
            }
    }
}

// MARK: - Apple SignIn Delegate
extension LoginViewModel: ASAuthorizationControllerDelegate {
    
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            endLoading()
            showErrorSubject.onNext("애플 인증 정보를 가져오지 못했습니다")
            return
        }
        
        guard let nonce = currentNonce else {
            endLoading()
            showErrorSubject.onNext("Invalid state: A login callback was received, but no login request was sent.")
            return
        }
        
        guard let appleIDToken = appleIDCredential.identityToken else {
            endLoading()
            showErrorSubject.onNext("Unable to fetch identity token")
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            endLoading()
            showErrorSubject.onNext("Unable to serialize token string from data")
            return
        }
        
        let credential = OAuthProvider.credential(
            providerID: .apple,
            idToken: idTokenString,
            rawNonce: nonce
        )
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self else { return }
            
            if let error = error {
                self.endLoading()
                self.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                self.endLoading()
                self.showErrorSubject.onNext("Firebase 사용자 정보를 가져오지 못했습니다")
                return
            }
            
            let fullName = PersonNameComponentsFormatter()
                .string(from: appleIDCredential.fullName ?? PersonNameComponents())
            
            let appleUserInfo = AppleUserInfo(
                userIdentifier: appleIDCredential.user,
                fullName: fullName.isEmpty ? nil : fullName,
                email: appleIDCredential.email
            )
            
            self.saveAppleUserToFirestore(
                firebaseUser: firebaseUser,
                appleUserInfo: appleUserInfo
            )
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        endLoading()
        
        if let error = error as? ASAuthorizationError {
            switch error.code {
            case .canceled:
                return
            case .failed:
                showErrorSubject.onNext("인증에 실패했습니다")
            case .invalidResponse:
                showErrorSubject.onNext("잘못된 응답입니다")
            case .notHandled:
                showErrorSubject.onNext("요청을 처리할 수 없습니다")
            case .unknown:
                showErrorSubject.onNext("알 수 없는 오류가 발생했습니다")
            @unknown default:
                showErrorSubject.onNext("애플 로그인 오류: \(error.localizedDescription)")
            }
        } else {
            showErrorSubject.onNext(error.localizedDescription)
        }
    }
}

// MARK: - Apple Presentation
extension LoginViewModel: ASAuthorizationControllerPresentationContextProviding {
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return UIWindow()
        }
        return window
    }
}

// MARK: - Apple User Info
struct AppleUserInfo {
    let userIdentifier: String
    let fullName: String?
    let email: String?
}

// MARK: - Nonce Helpers
extension LoginViewModel {
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            for random in randoms {
                if remainingLength == 0 { break }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
}

private func currentAppUserId() -> String? {
    return AuthSession.currentAppUserId
}
