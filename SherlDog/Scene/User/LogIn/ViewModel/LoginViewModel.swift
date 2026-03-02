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
    
    private func loginWithKakao() {
        guard beginLoadingIfPossible() else { return }
        
        AuthManager.shared.loginWithKakao { [weak self] result in
            guard let self else { return }
            self.endLoading()
            
            switch result {
            case .success:
                self.checkPetProfiles()
            case .failure(let error):
                let message = error.localizedDescription.lowercased()
                if message.contains("cancel") || message.contains("취소") { return }
                self.showErrorSubject.onNext(error.localizedDescription)
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
        
        AuthManager.shared.loginWithGoogle(presentingViewController: rootVC) { [weak self] result in
            guard let self else { return }
            self.endLoading()
            
            switch result {
            case .success:
                self.checkPetProfiles()
            case .failure(let error):
                self.showErrorSubject.onNext(error.localizedDescription)
            }
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
        
        AuthManager.shared.loginWithApple(appleIDCredential: appleIDCredential, rawNonce: nonce) { [weak self] result in
            guard let self else { return }
            self.endLoading()
            
            switch result {
            case .success:
                self.checkPetProfiles()
            case .failure(let error):
                self.showErrorSubject.onNext(error.localizedDescription)
            }
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
            default:
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
