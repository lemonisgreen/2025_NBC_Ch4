import Foundation
import RxSwift
import RxCocoa
import FirebaseAuth
import GoogleSignIn
import KakaoSDKUser
import FirebaseFirestore
import AuthenticationServices
import CryptoKit

final class LoginViewModel: NSObject {
    
    // MARK: - Input/Output 구조체
    struct Input {
        let kakaoTap: AnyObserver<Void>
        let googleTap: AnyObserver<Void>
        let appleTap: AnyObserver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let navigate: Signal<Void>
        let showError: Signal<String>
        let showAlert: Signal<String>
    }
    
    // MARK: - Properties
    lazy var input: Input = {
        return Input(
            kakaoTap: kakaoTapSubject.asObserver(),
            googleTap: googleTapSubject.asObserver(),
            appleTap: appleTapSubject.asObserver()
        )
    }()
    
    lazy var output: Output = {
        return Output(
            isLoading: isLoadingSubject.asDriver(onErrorJustReturn: false),
            navigate: navigateSubject.asSignal(onErrorSignalWith: .empty()),
            showError: showErrorSubject.asSignal(onErrorSignalWith: .empty()),
            showAlert: showAlertSubject.asSignal(onErrorSignalWith: .empty())
        )
    }()
    
    private let kakaoTapSubject = PublishSubject<Void>()
    private let googleTapSubject = PublishSubject<Void>()
    private let appleTapSubject = PublishSubject<Void>()
    
    private let isLoadingSubject = BehaviorSubject<Bool>(value: false)
    private let navigateSubject = PublishSubject<Void>()
    private let showErrorSubject = PublishSubject<String>()
    private let showAlertSubject = PublishSubject<String>()
    
    private let disposeBag = DisposeBag()
    
    // 애플 로그인용 nonce
    private var currentNonce: String?
    
    override init() {
        super.init()
        bindInputs()
    }
    
    private func bindInputs() {
        // 카카오 로그인
        kakaoTapSubject
            .bind { [weak self] in
                self?.loginWithKakao()
            }
            .disposed(by: disposeBag)
        
        // 구글 로그인
        googleTapSubject
            .bind { [weak self] in
                self?.loginWithGoogle()
            }
            .disposed(by: disposeBag)
        
        // 애플 로그인
        appleTapSubject
            .bind { [weak self] in
                self?.loginWithApple()
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - 카카오 로그인
    private func loginWithKakao() {
        guard ((try? isLoadingSubject.value()) != true) else { return }
        isLoadingSubject.onNext(true)
        
        KakaoLoginManager.shared.login { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    let userInfo = KakaoUserInfo(from: user)
                    self?.linkKakaoToFirebase(userInfo: userInfo)
                    
                case .failure(let error):
                    self?.isLoadingSubject.onNext(false)
                    if case .userCancelled = error { return }
                    self?.showErrorSubject.onNext(error.localizedDescription)
                }
            }
        }
    }
    
    private func linkKakaoToFirebase(userInfo: KakaoUserInfo) {
        // 먼저 익명 로그인
        Auth.auth().signInAnonymously { [weak self] authResult, error in
            if let error = error {
                self?.isLoadingSubject.onNext(false)
                self?.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            guard let firebaseUser = authResult?.user else {
                self?.isLoadingSubject.onNext(false)
                self?.showErrorSubject.onNext("Firebase 인증 실패")
                return
            }
            
            // Firestore에 카카오 사용자 정보 저장
            self?.saveKakaoUserToFirestore(firebaseUser: firebaseUser, kakaoUserInfo: userInfo)
        }
    }
    
    private func saveKakaoUserToFirestore(firebaseUser: FirebaseAuth.User, kakaoUserInfo: KakaoUserInfo) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "kakaoId": kakaoUserInfo.id,
            "nickname": kakaoUserInfo.nickname ?? "",
            "email": kakaoUserInfo.email ?? "",
            "profileImageUrl": kakaoUserInfo.profileImageUrl ?? "",
            "provider": "kakao",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(firebaseUser.uid).setData(userData, merge: true) { [weak self] error in
            self?.isLoadingSubject.onNext(false)
            
            if let error = error {
                self?.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            // 로그인 성공
            UserDefaults.standard.set(true, forKey: "isKakaoLoggedIn")
            UserDefaults.standard.set(kakaoUserInfo.nickname, forKey: "userNickname")
            UserDefaults.standard.set(kakaoUserInfo.email, forKey: "userEmail")
            UserDefaults.standard.set(firebaseUser.uid, forKey: "firebaseUID")
            self?.navigateSubject.onNext(())
        }
    }
    
    // MARK: - 구글 로그인
    private func loginWithGoogle() {
        guard (try? isLoadingSubject.value()) == false else { return }
        isLoadingSubject.onNext(true)
        
        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows.first?.rootViewController else {
            isLoadingSubject.onNext(false)
            showErrorSubject.onNext("화면 전환 컨트롤러를 찾을 수 없습니다.")
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.isLoadingSubject.onNext(false)
                self.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.isLoadingSubject.onNext(false)
                self.showErrorSubject.onNext("인증 토큰을 가져오지 못했습니다")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            // Firebase Auth로 로그인
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.isLoadingSubject.onNext(false)
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                // 구글 로그인 성공 시 Firestore에 사용자 정보 저장
                if let firebaseUser = authResult?.user {
                    self.saveGoogleUserToFirestore(firebaseUser: firebaseUser, googleUser: user)
                } else {
                    self.isLoadingSubject.onNext(false)
                    self.showErrorSubject.onNext("Firebase 사용자 정보를 가져오지 못했습니다")
                }
            }
        }
    }
    
    private func saveGoogleUserToFirestore(firebaseUser: FirebaseAuth.User, googleUser: GIDGoogleUser) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "googleId": googleUser.userID ?? "",
            "nickname": firebaseUser.displayName ?? "",
            "email": firebaseUser.email ?? "",
            "profileImageUrl": firebaseUser.photoURL?.absoluteString ?? "",
            "provider": "google",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(firebaseUser.uid).setData(userData, merge: true) { [weak self] error in
            self?.isLoadingSubject.onNext(false)
            
            if let error = error {
                self?.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            // 로그인 성공
            UserDefaults.standard.set(true, forKey: "isGoogleLoggedIn")
            UserDefaults.standard.set(firebaseUser.displayName ?? "", forKey: "userNickname")
            UserDefaults.standard.set(firebaseUser.email ?? "", forKey: "userEmail")
            UserDefaults.standard.set(firebaseUser.uid, forKey: "firebaseUID")
            self?.navigateSubject.onNext(())
        }
    }
    
    // MARK: - 애플 로그인
    private func loginWithApple() {
        guard (try? isLoadingSubject.value()) == false else { return }
        isLoadingSubject.onNext(true)
        
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
    
    private func saveAppleUserToFirestore(firebaseUser: FirebaseAuth.User, appleUserInfo: AppleUserInfo) {
        let db = Firestore.firestore()
        
        let userData: [String: Any] = [
            "appleId": appleUserInfo.userIdentifier,
            "nickname": appleUserInfo.fullName ?? firebaseUser.displayName ?? "",
            "email": appleUserInfo.email ?? firebaseUser.email ?? "",
            "profileImageUrl": "",
            "provider": "apple",
            "createdAt": FieldValue.serverTimestamp(),
            "lastLoginAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(firebaseUser.uid).setData(userData, merge: true) { [weak self] error in
            self?.isLoadingSubject.onNext(false)
            
            if let error = error {
                self?.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            // 로그인 성공
            UserDefaults.standard.set(true, forKey: "isAppleLoggedIn")
            UserDefaults.standard.set(appleUserInfo.fullName ?? firebaseUser.displayName ?? "", forKey: "userNickname")
            UserDefaults.standard.set(appleUserInfo.email ?? firebaseUser.email ?? "", forKey: "userEmail")
            UserDefaults.standard.set(firebaseUser.uid, forKey: "firebaseUID")
            self?.navigateSubject.onNext(())
        }
    }
    
    // MARK: - Nonce 생성 헬퍼 메서드
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
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
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
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}

// MARK: - Apple Sign In Delegate
extension LoginViewModel: ASAuthorizationControllerDelegate {
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            guard let nonce = currentNonce else {
                isLoadingSubject.onNext(false)
                showErrorSubject.onNext("Invalid state: A login callback was received, but no login request was sent.")
                return
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                isLoadingSubject.onNext(false)
                showErrorSubject.onNext("Unable to fetch identity token")
                return
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                isLoadingSubject.onNext(false)
                showErrorSubject.onNext("Unable to serialize token string from data")
                return
            }
            
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                    idToken: idTokenString,
                                                    rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                if let error = error {
                    self?.isLoadingSubject.onNext(false)
                    self?.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                if let firebaseUser = authResult?.user {
                    let fullName = PersonNameComponentsFormatter().string(from: appleIDCredential.fullName ?? PersonNameComponents())
                    
                    let appleUserInfo = AppleUserInfo(
                        userIdentifier: appleIDCredential.user,
                        fullName: fullName.isEmpty ? nil : fullName,
                        email: appleIDCredential.email
                    )
                    
                    self?.saveAppleUserToFirestore(firebaseUser: firebaseUser, appleUserInfo: appleUserInfo)
                } else {
                    self?.isLoadingSubject.onNext(false)
                    self?.showErrorSubject.onNext("Firebase 사용자 정보를 가져오지 못했습니다")
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        isLoadingSubject.onNext(false)
        
        if let error = error as? ASAuthorizationError {
            switch error.code {
            case .canceled:
                // 사용자가 취소한 경우 아무것도 하지 않음
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
