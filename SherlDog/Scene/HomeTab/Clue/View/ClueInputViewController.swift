//
//  ClueInputViewController.swift
//  SherlDog
//
//  Created by 김재우 on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import Kingfisher

class ClueInputViewController: UIViewController {

    enum EditMode {
        case new
        case fix

        var title: String {
            switch self {
            case .new: "단서 남기기"
            case .fix: "단서 수정하기"
            }
        }

        var buttonTitle: String {
            switch self {
            case .new: "단서 등록하기"
            case .fix: "수정 완료하기"
            }
        }

        var alertMessage: String {
            switch self {
            case .new: "단서가 등록되었습니다!"
            case .fix: "수정이 완료되었습니다!"
            }
        }
    }

    private let editMode: EditMode

    private let clueLabel = UILabel()
    private let cancelButton = UIButton()
    private let imageView = UIImageView()
    private let textView = UITextView()
    private let registerButton = UIButton()
    private let countLabel = UILabel()
    private let placeholderLabel = UILabel()
    private let loadingIndicator = CustomLoadingIndicator()
    
    private let isLoading = BehaviorRelay<Bool>(value: false)
    
    private let cameraViewModel: CameraViewModel?
    private let disposeBag = DisposeBag()
    
    private let markerLocation: CLLocationCoordinate2D?

    private let currentClue: ClueModel?
    var onClueUpdated: ((ClueModel) -> Void)?
    
    init(viewModel: CameraViewModel, location: CLLocationCoordinate2D) {
        self.editMode = .new
        self.cameraViewModel = viewModel
        self.markerLocation = location  // 마커 위치 저장
        self.currentClue = nil

        super.init(nibName: nil, bundle: nil)
    }

    init(data: ClueModel) {
        self.editMode = .fix
        self.cameraViewModel = nil
        self.markerLocation = nil
        self.currentClue = data
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        self.hideKeyboardWhenTappedAroundRx(disposeBag: disposeBag)
        navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindRegisterAction()
        if let currentClue {
            textView.text = currentClue.content
            imageView.kf.setImage(with: URL(string: currentClue.image), placeholder: UIImage.emptyClueDog)
        }
        bindTextView()
        bind()
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorTertiaryBG
        
        clueLabel.text = self.editMode.title
        clueLabel.font = .highlight3
        clueLabel.textColor = .textPrimary
        
        cancelButton.setImage(.modalExit, for: .normal)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(named: "gray300")?.cgColor
        imageView.layer.cornerRadius = 6
        
        textView.backgroundColor = .gray50
        textView.textColor = .textPrimary
        textView.font = .body3
        textView.layer.borderColor = UIColor(named: "gray300")?.cgColor
        textView.layer.borderWidth = 1
        textView.layer.cornerRadius = 6
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 0, right: 16)
        
        placeholderLabel.text = "사건 파일에 남길 단서의 이야기를 적어주세요"
        placeholderLabel.font = .body3
        placeholderLabel.textColor = .keycolorDisabled
        placeholderLabel.textColor = UIColor.lightGray.withAlphaComponent(0.6)
        placeholderLabel.numberOfLines = 0
        textView.addSubview(placeholderLabel)
        placeholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.equalToSuperview().offset(16)
        }
        
        textView.delegate = self
        textView.returnKeyType = .done
        
        let registerButtonTitle = self.editMode.buttonTitle

        registerButton.setTitle(registerButtonTitle, for: .normal)
        registerButton.setTitleColor(.textInverse, for: .normal)
        registerButton.titleLabel?.font = .highlight4
        registerButton.backgroundColor = .keycolorPrimary3
        registerButton.layer.cornerRadius = 6
        
        countLabel.font = .alert2
        countLabel.textColor = .gray400
        
        [clueLabel, cancelButton, imageView, textView, registerButton, countLabel, loadingIndicator].forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        clueLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(UIScreen.isIPhoneSE ? 12 : 26)
        }
        
        cancelButton.snp.makeConstraints {
            $0.top.equalTo(clueLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        imageView.snp.makeConstraints {
            $0.top.equalTo(clueLabel.snp.bottom).offset(UIScreen.isIPhoneSE ? 26 : 12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.1).priority(.low)
            $0.height.greaterThanOrEqualTo(100).priority(.low)
        }
        
        textView.snp.makeConstraints{
            $0.top.equalTo(imageView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(156)
        }
        
        countLabel.snp.makeConstraints {
            $0.trailing.equalTo(textView.snp.trailing).inset(8)
            $0.bottom.equalTo(textView.snp.bottom).inset(8)
        }
        
        registerButton.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(UIScreen.isIPhoneSE ? 12 : 32)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func bindRegisterAction() {
        registerButton.rx.tap
            .bind { [weak self] in
                self?.saveClue()
            }
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.dismiss(animated: true) {
                    guard let cameraViewModel = self?.cameraViewModel else { return }
                    cameraViewModel.input.accept(.dismiss)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindTextView() {
        textView.rx.text.orEmpty
            .do(onNext: { [weak self] text in
                if text.count > 120 {
                    let trimmed = String(text.prefix(120))
                    self?.textView.text = trimmed
                    self?.countLabel.text = "120 / 120자"
                } else {
                    self?.countLabel.text = "\(text.count) / 120자"
                }
            })
            .map { !$0.isEmpty }
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        self.isLoading
            .asDriver(onErrorJustReturn: false)
            .map { !$0 }
            .drive(self.loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)

        guard let cameraViewModel else { return }

        cameraViewModel.output.capturedImage
            .bind(to: self.imageView.rx.image)
            .disposed(by: disposeBag)
    }
    
    // 단서저장
    private func saveClue() {
        guard let text = textView.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty,
              let userId = AuthSession.currentAppUserId else {
            showSimpleAlert("이미지와 텍스트를 확인해주세요.")
            return
        }
        
        if editMode == .new && imageView.image == nil {
            showSimpleAlert("이미지를 확인해주세요.")
            return
        }
        if editMode == .fix {
            guard let currentClue, currentClue.userID == userId,
                  let id = currentClue.documentId, !id.isEmpty else {
                showSimpleAlert("수정할 단서 정보를 확인해주세요.")
                return
            }
        }
        self.isLoading.accept(true)
        isModalInPresentation = true
        cancelButton.isEnabled = false
        registerButton.isEnabled = false
        registerButton.setTitle("저장 중...", for: .normal)
        
        switch editMode {
        case .new:
            guard let image = imageView.image else { return }
            self.saveToFirebase(
                userId: userId,
                image: image,
                text: text
            )

        case .fix:
            self.editClue(updatedText: text)
        }
    }

    private func editClue(updatedText: String) {
        guard let currentClue,
              let documentId = currentClue.documentId else { return }

        var updatedClue = ClueModel(
            userID: currentClue.userID,
            latitude: currentClue.latitude,
            longitude: currentClue.longitude,
            content: updatedText,
            image: currentClue.image,
            date: currentClue.date
        )

        updatedClue.documentId = documentId
        let savedClue = updatedClue

        FirestoreManager.shared.updateDocument(
            collection: .clues,
            documentId: documentId,
            data: updatedClue
        )
        .subscribe(
            onCompleted: { [weak self] in
                DispatchQueue.main.async {
                    self?.onClueUpdated?(savedClue)
                    self?.showSuccessAndClose()
                }
            },
            onError: { [weak self] error in
                DispatchQueue.main.async {
                    self?.isLoading.accept(false)
                    self?.showSimpleAlert("저장 실패: \(error.localizedDescription)")
                    self?.resetButton()
                }
            }
        )
        .disposed(by: disposeBag)
    }

    private func saveToFirebase(userId: String, image: UIImage, text: String) {
        FirebaseImageManager.shared.uploadImage(image, type: .clue) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                self?.saveToFirestore(userId: userId, text: text, imageUrl: imageUrl)
            case .failure(let error):
                self?.isLoading.accept(false)
                self?.showSimpleAlert("이미지 업로드 실패: \(error.localizedDescription)")
                self?.resetButton()
            }
        }
    }
    
    private func saveToFirestore(userId: String, text: String, imageUrl: String) {
        guard let markerLocation else { return }

        let clue = ClueModel(
            userID: userId,
            latitude: markerLocation.latitude,
            longitude: markerLocation.longitude,
            content: text,
            image: imageUrl,
            date: Timestamp(date: Date())
        )
        
        FirestoreManager.shared.createDocument(collection: .clues, data: clue)
            .subscribe(
                onCompleted: { [weak self] in
                    DispatchQueue.main.async {
                        self?.showSuccessAndClose()
                    }
                },
                onError: { [weak self] error in
                    DispatchQueue.main.async {
                        self?.isLoading.accept(false)
                        self?.showSimpleAlert("저장 실패: \(error.localizedDescription)")
                        self?.resetButton()
                    }
                }
            )
            .disposed(by: disposeBag)
    }
    
    private func resetButton() {
        let registerButtonTitle = self.editMode.buttonTitle

        isModalInPresentation = false
        cancelButton.isEnabled = true
        registerButton.isEnabled = true
        registerButton.setTitle(registerButtonTitle, for: .normal)
    }
    
    private func showSuccessAndClose() {
        self.isLoading.accept(false)
        
        let alertMessage = self.editMode.alertMessage

        let alert = UIAlertController(title: "성공", message: alertMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let self else { return }
            if self.editMode == .fix {
                self.dismiss(animated: true)
                return
            }
            guard let mainView = self.view.window?.rootViewController else { return }
            mainView.dismiss(animated: true)
        })
        present(alert, animated: true)
    }
    
    private func showSimpleAlert(_ message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

// 키보드 완료 버튼 익스텐션
extension ClueInputViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
