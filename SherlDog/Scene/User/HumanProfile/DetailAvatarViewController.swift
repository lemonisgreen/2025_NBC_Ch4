//
//  DetailAvatarViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/11/25.
//

import RxSwift
import RxCocoa
import UIKit
import SnapKit

// MARK: - DetailAvatarViewController
class DetailAvatarViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel: SelectAvatarViewModel
    
    private let titleLabel = UILabel()
    private let avatarImageView = UIImageView()
    private let avatarBackground = UIImageView()
    private let detailView = UIImageView()
    private let detailTitleLabel = UILabel()
    private let detailLabel = UILabel()
    private let backButton = UIButton()
    private let choiceButton = UIButton()
    private let horizontalStackView = UIStackView()
    
    // MARK: - Initialize
    init(viewModel: SelectAvatarViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Lifecycle
extension DetailAvatarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
        inputBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    
}

// MARK: - Method
extension DetailAvatarViewController {
    
    private func bind() {
        self.viewModel.output.selectedAvatar
            .subscribe(onNext: { [weak self] data in
                guard let self, let data else { return }
                
                self.avatarImageView.image = UIImage(named: data.avatar)
                self.detailTitleLabel.text = data.title
                self.detailLabel.text = data.content
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.backButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        self.choiceButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                // todo: 조수 프로필 뷰로 데이터 보내기
                self.dismiss(animated: true)
                self.presentingViewController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .textInverse
        
        detailView.addSubviews([
            detailTitleLabel,
            detailLabel
        ])
        
        [backButton, choiceButton].forEach {
            horizontalStackView.addArrangedSubview($0)
        }
        
        view.addSubviews([
            titleLabel,
            avatarBackground,
            avatarImageView,
            detailView,
            horizontalStackView
        ])
        
        titleLabel.text = "이 친구로 결정할까요?"
        titleLabel.font = .title1
        titleLabel.textColor = .textPrimary
        
        avatarBackground.contentMode = .scaleAspectFit
        avatarBackground.image = UIImage(systemName: "timelapse")   // test
        avatarBackground.tintColor = .keycolorOrange   // test
        
        avatarImageView.contentMode = .scaleAspectFit
        
//        detailView.image = UIImage(named: "")
        detailView.backgroundColor = .cyan  // test
        detailView.contentMode = .scaleToFill
        
        detailTitleLabel.font = .highlight4
        detailTitleLabel.textColor = .textSecondary
        
        detailLabel.font = .alert2
        detailLabel.textColor = .textSecondary
        detailLabel.numberOfLines = 0
        
        backButton.setTitle("이전", for: .normal)
        backButton.setTitleColor(.keycolorPrimary3, for: .normal)
        backButton.backgroundColor = .white
        backButton.layer.borderColor = UIColor.keycolorPrimary3.cgColor
        backButton.layer.borderWidth = 1
        backButton.layer.cornerRadius = 6
        backButton.clipsToBounds = true
        
        choiceButton.setTitle("선택하기", for: .normal)
        choiceButton.setTitleColor(.textInverse, for: .normal)
        choiceButton.backgroundColor = .keycolorPrimary3
        choiceButton.layer.cornerRadius = 6
        choiceButton.clipsToBounds = true
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16
        horizontalStackView.distribution = .fill
    }
    
    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(32)
            $0.leading.equalToSuperview().inset(16)
        }
        
        avatarImageView.snp.makeConstraints {
            $0.height.equalTo(248)
            $0.top.equalTo(titleLabel.snp.bottom).offset(96)
            $0.leading.trailing.equalToSuperview()
        }
        
        avatarBackground.snp.makeConstraints {
            $0.width.height.equalTo(avatarImageView).inset(8)
            $0.center.equalTo(avatarImageView)
        }
        
        detailView.snp.makeConstraints {
            $0.height.equalTo(141)
            $0.top.equalTo(avatarImageView.snp.bottom).offset(92)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        detailTitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(28)
        }
        
        detailLabel.snp.makeConstraints {
            $0.top.equalTo(detailTitleLabel.snp.bottom).offset(8)
            $0.leading.equalTo(detailTitleLabel)
            $0.trailing.equalToSuperview().inset(8)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(52)
        }
        
        backButton.snp.makeConstraints {
            $0.width.equalTo(choiceButton).multipliedBy(1.0 / 2.0)
        }
    }
    
}
