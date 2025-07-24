//
//  CreateLogViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - CreateLogViewController
class CreateLogViewController: UIViewController {
    
    private let cameraViewModel: CameraViewModel
    private let viewModel = InvLogViewModel()
    private let disposeBag = DisposeBag()
    
    private let titleLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    private let photoImageView = UIImageView()
    private let dateLabel = UILabel()
    private let distanceTitleLabel = UILabel()
    private let durationTitleLabel = UILabel()
    private let stepsTitleLabel = UILabel()
    private let clueTitleLabel = UILabel()
    private let distanceLabel = UILabel()
    private let durationLabel = UILabel()
    private let stepsLabel = UILabel()
    private let clueLabel = UILabel()
    private let distanceStepView = UIView()
    private let durationClueView = UIView()
    private let textView = UITextView()
    private let textViewPlaceholderLabel = UILabel()
    private let textViewConstraintsLabel = UILabel()
    private let cancelButton = SubButtonManager(title: "취소")
    private let shareButton = ButtonManager(title: "등록하기")
    private let horizontalStackView = UIStackView()
    
    // MARK: - Lifecycle
    init(viewModel: CameraViewModel) {
        self.cameraViewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAroundRx(disposeBag: disposeBag)
        
        setupUI()
        configureUI()
        bind()
        inputBind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = photoImageView.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
}

// MARK: - Method
extension CreateLogViewController {
    
    private func bind() {
        cameraViewModel.output.capturedImage
            .bind(to: self.photoImageView.rx.image)
            .disposed(by: disposeBag)
        
        self.viewModel.output.uploadComplete
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                let alert = AlertManager(message: "등록되었습니다.",
                                         subMessage: nil,
                                         buttonTitles: ["확인"],
                                         buttonActions: [{ [weak self] in
                    guard let self,
                          let mainView = self.view.window?.rootViewController as? BottomTabBarController else { return }
                    mainView.dismiss(animated: true)
                    mainView.selectedIndex = 1
                }])
                
                self.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        textView.rx.text
            .subscribe(onNext: { [weak self] text in
                guard let self, let text else { return }
                
                if text.count > 120 {
                    let diff = text.count - 120
                    self.textView.text.removeLast(diff)
                }
                
                self.textViewConstraintsLabel.text = "\(text.count) / 120자"
                
                if text.count > 0 {
                    self.textViewPlaceholderLabel.isHidden = true
                } else {
                    self.textViewPlaceholderLabel.isHidden = false
                }
            })
            .disposed(by: disposeBag)
        
        self.cancelButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                let alert = AlertManager(message: "작성을 취소하시겠습니까?", subMessage: nil,
                                         buttonTitles: ["취소", "확인"],
                                         buttonActions: [
                                            nil,
                                            { [weak self] in
                                                guard let self,
                                                      let cameraView = self.presentingViewController,
                                                      let requestView = cameraView.presentingViewController,
                                                      let walkEndView = requestView.presentingViewController else { return }
                                                walkEndView.dismiss(animated: true)
                                            }])
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        self.shareButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self,
                      let text = self.textView.text else { return }
                let image = photoImageView.viewCapture()
                let data = InvLogViewModel.UploadData(invImage: image,
                                                      content: text)
                
                self.viewModel.input.accept(.didFinishedWrite(data))
            })
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        textView.addSubview(textViewPlaceholderLabel)
        
        [cancelButton, shareButton]
            .forEach { horizontalStackView.addArrangedSubview($0) }
        
        distanceStepView.addSubviews([
            distanceTitleLabel,
            distanceLabel,
            stepsTitleLabel,
            stepsLabel
        ])
        
        durationClueView.addSubviews([
            durationTitleLabel,
            durationLabel,
            clueTitleLabel,
            clueLabel
        ])
        
        photoImageView.layer.addSublayer(gradientLayer)
        photoImageView.addSubviews([
            dateLabel,
            distanceStepView,
            durationClueView
        ])
        
        view.addSubviews([
            titleLabel,
            photoImageView,
            textView,
            textViewConstraintsLabel,
            horizontalStackView
        ])
        
        titleLabel.text = "수사일지"
        titleLabel.font = .highlight3
        titleLabel.textColor = .textPrimary
        
        gradientLayer.colors = [UIColor.white.withAlphaComponent(0).cgColor,
                                UIColor.black.withAlphaComponent(0.7).cgColor]
        gradientLayer.startPoint = .init(x: 0.5, y: 0.05)
        gradientLayer.endPoint = .init(x: 0.5, y: 1.0)
        
        photoImageView.contentMode = .scaleAspectFill
        photoImageView.clipsToBounds = true
        photoImageView.layer.cornerRadius = 6
        
        dateLabel.text = "2025년 6월 1일"  // test
        dateLabel.font = .title1
        dateLabel.textColor = .textInverse
        
        [distanceTitleLabel, durationTitleLabel, stepsTitleLabel, clueTitleLabel]
            .forEach {
                $0.font = .alert2
            }
        
        distanceTitleLabel.text = "거리"
        distanceTitleLabel.textColor = .gray50
        
        durationTitleLabel.text = "시간"
        durationTitleLabel.textColor = .textInverse
        
        stepsTitleLabel.text = "걸음수"
        stepsTitleLabel.textColor = .gray50
        
        clueTitleLabel.text = "남긴 단서"
        clueTitleLabel.textColor = .textInverse
        
        [distanceLabel, durationLabel, stepsLabel, clueLabel]
            .forEach {
                $0.font = .body1
                $0.textColor = .textInverse
            }
        
        distanceLabel.text = "11.23km"
        durationLabel.text = "01:12:23"
        stepsLabel.text = "99999"
        clueLabel.text = "12개"
        
        textView.font = .body3
        textView.textColor = .textPrimary
        textView.backgroundColor = .gray50
        textView.layer.cornerRadius = 6
        textView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        
        textViewPlaceholderLabel.text = "오늘의 수사일지를 간단히 적어주세요."
        textViewPlaceholderLabel.font = .body3
        textViewPlaceholderLabel.textColor = .textDisabled
        
        textViewConstraintsLabel.text = "0 / 120자"
        textViewConstraintsLabel.font = .alert2
        textViewConstraintsLabel.textColor = .gray400
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16
        horizontalStackView.distribution = .fillEqually
    }
    
    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(26)
            $0.leading.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        
        photoImageView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(12)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(textView.snp.top).offset(-16)
        }
        
        distanceStepView.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(16)
            $0.width.equalTo(100)
        }
        
        stepsTitleLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.leading.equalToSuperview()
        }
        
        stepsLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(stepsTitleLabel)
        }
        
        distanceTitleLabel.snp.makeConstraints {
            $0.bottom.equalTo(stepsTitleLabel.snp.top).offset(-8)
            $0.top.equalToSuperview()
            $0.leading.equalTo(stepsTitleLabel)
        }
        
        distanceLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(distanceTitleLabel)
        }
        
        durationClueView.snp.makeConstraints {
            $0.leading.equalTo(distanceStepView.snp.trailing).offset(10)
            $0.bottom.equalTo(distanceStepView)
            $0.width.equalTo(100)
        }
        
        clueTitleLabel.snp.makeConstraints {
            $0.bottom.equalToSuperview()
            $0.leading.equalToSuperview()
        }
        
        durationTitleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.bottom.equalTo(clueTitleLabel.snp.top).offset(-8)
            $0.top.equalToSuperview()
        }
        
        durationLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(durationTitleLabel)
        }
        
        clueLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview()
            $0.centerY.equalTo(clueTitleLabel)
        }
        
        dateLabel.snp.makeConstraints {
            $0.bottom.equalTo(distanceStepView.snp.top).offset(-6)
            $0.leading.equalTo(distanceStepView)
        }
        
        textView.snp.makeConstraints {
            $0.height.equalTo(155)
            $0.top.equalTo(photoImageView.snp.bottom).offset(16)
            $0.bottom.equalTo(horizontalStackView.snp.top).offset(-32)
            $0.leading.trailing.equalTo(photoImageView)
        }
        
        textViewPlaceholderLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(12)
        }
        
        textViewConstraintsLabel.snp.makeConstraints {
            $0.bottom.trailing.equalTo(textView).offset(-12)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
    }
    
}
