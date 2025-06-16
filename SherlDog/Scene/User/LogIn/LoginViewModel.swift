import Foundation
import RxSwift
import RxCocoa
import FirebaseAuth
import GoogleSignIn
import KakaoSDKUser

final class LoginViewModel {
    
    // MARK: - Input/Output 구조체
    struct Input {
        let kakaoTap: AnyObserver<Void>
        let naverTap: AnyObserver<Void>
        let googleTap: AnyObserver<Void>
        let appleTap: AnyObserver<Void>
        let facebookTap: AnyObserver<Void>
    }
    
    struct Output {
        let isLoading: Driver<Bool>
        let navigate: Signal<Void>
        let showError: Signal<String>
        let showAlert: Signal<String>
    }
    
    // MARK: - Properties
    let input: Input
    let output: Output
    
    private let kakaoTapSubject = PublishSubject<Void>()
    private let naverTapSubject = PublishSubject<Void>()
    private let googleTapSubject = PublishSubject<Void>()
    private let appleTapSubject = PublishSubject<Void>()
    private let facebookTapSubject = PublishSubject<Void>()
    
    private let isLoadingSubject = BehaviorSubject<Bool>(value: false)
    private let navigateSubject = PublishSubject<Void>()
    private let showErrorSubject = PublishSubject<String>()
    private let showAlertSubject = PublishSubject<String>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        // Input 설정
        input = Input(
            kakaoTap: kakaoTapSubject.asObserver(),
            naverTap: naverTapSubject.asObserver(),
            googleTap: googleTapSubject.asObserver(),
            appleTap: appleTapSubject.asObserver(),
            facebookTap: facebookTapSubject.asObserver()
        )
        
        // Output 설정
        output = Output(
            isLoading: isLoadingSubject.asDriver(onErrorJustReturn: false),
            navigate: navigateSubject.asSignal(onErrorSignalWith: .empty()),
            showError: showErrorSubject.asSignal(onErrorSignalWith: .empty()),
            showAlert: showAlertSubject.asSignal(onErrorSignalWith: .empty())
        )
        
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
        
        // 준비 중인 로그인들
        naverTapSubject
            .bind { [weak self] in
                self?.showAlertSubject.onNext("네이버 로그인은 준비 중입니다.")
            }
            .disposed(by: disposeBag)
        
        appleTapSubject
            .bind { [weak self] in
                self?.showAlertSubject.onNext("애플 로그인은 준비 중입니다.")
            }
            .disposed(by: disposeBag)
        
        facebookTapSubject
            .bind { [weak self] in
                self?.showAlertSubject.onNext("페이스북 로그인은 준비 중입니다.")
            }
            .disposed(by: disposeBag)
    }
    
    // MARK: - 카카오 로그인
    private func loginWithKakao() {
        guard ((try? isLoadingSubject.value()) == nil) ?? false else { return }
        isLoadingSubject.onNext(true)
        
        KakaoLoginManager.shared.login { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingSubject.onNext(false)
                switch result {
                case .success(let user):
                    let userInfo = KakaoUserInfo(from: user)
                    UserDefaults.standard.set(true, forKey: "isKakaoLoggedIn")
                    UserDefaults.standard.set(userInfo.nickname, forKey: "userNickname")
                    UserDefaults.standard.set(userInfo.email, forKey: "userEmail")
                    self?.navigateSubject.onNext(())
                    
                case .failure(let error):
                    if case .userCancelled = error { return }
                    self?.showErrorSubject.onNext(error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - 구글 로그인
    private func loginWithGoogle() {
        guard ((try? isLoadingSubject.value()) == nil) ?? false else { return }
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
            self.isLoadingSubject.onNext(false)
            
            if let error = error {
                self.showErrorSubject.onNext(error.localizedDescription)
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                self.showErrorSubject.onNext("인증 토큰을 가져오지 못했습니다")
                return
            }
            
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: user.accessToken.tokenString
            )
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showErrorSubject.onNext(error.localizedDescription)
                    return
                }
                
                // 구글 로그인 성공 시 사용자 정보 저장
                if let user = authResult?.user {
                    UserDefaults.standard.set(true, forKey: "isGoogleLoggedIn")
                    UserDefaults.standard.set(user.displayName ?? "", forKey: "userNickname")
                    UserDefaults.standard.set(user.email ?? "", forKey: "userEmail")
                }
                
                self.navigateSubject.onNext(())
            }
        }
    }
}
