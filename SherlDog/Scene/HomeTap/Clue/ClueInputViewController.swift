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

class ClueInputViewController: UIViewController {
    private let imageView = UIImageView()
    private let textView = UITextView()
    private let registerButton = UIButton()
    private let closeButton = UIButton()
    private let countLabel = UILabel()
    private let placeholderLabel = UILabel()

    private let cameraViewModel: CameraViewModel
    private let disposeBag = DisposeBag()
    
  
    init(viewModel: CameraViewModel) {
        self.cameraViewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindRegisterAction()
        bindCloseAction()
        bindTextView()
        bind()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraViewModel.input.accept(.viewDismissed)
    }
    
    private func bind() {
        cameraViewModel.output.capturedImage
            .subscribe(onNext: { [weak self] image in
                self?.imageView.image = image
            })
            .disposed(by: disposeBag)
    }

    private func setupUI() {
        view.backgroundColor = .keycolorTertiaryBG

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor(named: "gray300")?.cgColor
        imageView.layer.cornerRadius = 6
        
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

        registerButton.setTitle("단서 등록하기", for: .normal)
        registerButton.setTitleColor(.textInverse, for: .normal)
        registerButton.titleLabel?.font = .highlight4
        registerButton.backgroundColor = .keycolorPrimary3
        registerButton.layer.cornerRadius = 6
        
        countLabel.text = "0 / 150자"
        countLabel.font = .alert2
        countLabel.textColor = .gray400
        
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .textPrimary
        
        [imageView, textView, registerButton, closeButton, countLabel].forEach { view.addSubview($0) }
    }
    
    private func setupConstraints() {
        imageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(imageView.snp.width).multipliedBy(1.2).priority(.low)
            $0.height.greaterThanOrEqualTo(100).priority(.low)
        }

        textView.snp.makeConstraints{
            $0.top.equalTo(imageView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(180)
        }
        
        countLabel.snp.makeConstraints {
            $0.trailing.equalTo(textView.snp.trailing).inset(8)
            $0.bottom.equalTo(textView.snp.bottom).inset(8)
        }

        registerButton.snp.makeConstraints {
            $0.top.equalTo(textView.snp.bottom).offset(50)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
        
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(1)
            $0.trailing.equalToSuperview().inset(16)
            $0.width.height.equalTo(24)
        }
    }

    private func bindRegisterAction() {
        registerButton.rx.tap
            .bind { [weak self] in
                print("단서 등록 로직 실행됨")
                self?.dismiss(animated: true, completion: nil)
                self?.presentingViewController?.dismiss(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindCloseAction() {
        closeButton.rx.tap
            .bind { [weak self] in
                print("dismiss")
                self?.dismiss(animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
    }
    
    private func bindTextView() {
        textView.rx.text.orEmpty
            .do(onNext: { [weak self] text in
                if text.count > 150 {
                    let trimmed = String(text.prefix(150))
                    self?.textView.text = trimmed
                    self?.countLabel.text = "150 / 150자"
                } else {
                    self?.countLabel.text = "\(text.count) / 150자"
                }
            })
            .map { !$0.isEmpty }
            .bind(to: placeholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
}
