//
//  SelectDefaultAvatarViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import Differentiator
import SnapKit

// MARK: - SelectDefaultAvatarViewController
class SelectAvatarViewController: UIViewController {
    
    private let viewModel: SelectAvatarViewModel
    private let disposeBag = DisposeBag()
    private lazy var dataSource = self.setDataSource()
    
    private let titleLabel = UILabel()
    private let avatarImageView = UIImageView()
    private let avatarBackground = UIImageView()
    private let detailView = UIImageView()
    private let detailTitleLabel = UILabel()
    private let detailLabel = UILabel()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    private let pageControl = UIPageControl()
    private let backButton = SubButtonManager(title: "이전")
    private let choiceButton = ButtonManager(title: "선택하기")
    private let horizontalStackView = UIStackView()
    
    // MARK: - Lifecycle
    init(viewModel: SelectAvatarViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
extension SelectAvatarViewController {
    
    private func bind() {
        self.viewModel.output.cellData
            .asDriver(onErrorJustReturn: [])
            .drive(self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel.output.cellData
            .map {
                let itemsCount = $0.flatMap { $0.items }.count
                return itemsCount / 3 + (itemsCount.isMultiple(of: 3) ? 0 : 1)
            }
            .asDriver(onErrorJustReturn: 0)
            .drive(self.pageControl.rx.numberOfPages)
            .disposed(by: disposeBag)
        
        self.viewModel.output.selectedAvatar
            .asSignal()
            .emit(onNext: { [weak self] data in
                guard let self else { return }
                
                self.avatarImageView.image = UIImage(named: data.avatar)
                self.detailTitleLabel.text = data.title
                self.detailLabel.text = data.content
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.moveToBack
            .asSignal()
            .emit(onNext: { [weak self] in
                self?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.completeSelect
            .asSignal()
            .emit(onNext: { [weak self] _ in
                self?.view.window?.rootViewController?.dismiss(animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] index in
                self?.viewModel.input.accept(.avatarSelect(index.row))
                self?.choiceButton.isEnabled = true
            })
            .disposed(by: disposeBag)

        self.backButton.rx.tap
            .map { .goBack }
            .bind(to: viewModel.input)
            .disposed(by: disposeBag)
        
        self.choiceButton.rx.tap
            .map { .completeSelect }
            .bind(to: viewModel.input)
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .textInverse
        
        detailView.addSubviews([
            detailTitleLabel,
            detailLabel
        ])
        
        [backButton, choiceButton]
            .forEach { horizontalStackView.addArrangedSubview($0) }
        
        view.addSubviews([
            titleLabel,
            avatarBackground,
            avatarImageView,
            detailView,
            collectionView,
            pageControl,
            horizontalStackView
        ])
        
        titleLabel.text = "탐정님과 함께할 조수를 선택해주세요!"
        titleLabel.textAlignment = .left
        titleLabel.font = .title1
        titleLabel.textColor = .textPrimary
        
        avatarBackground.contentMode = .scaleAspectFit
        avatarBackground.image = .avatarSelect
        
        avatarImageView.contentMode = .scaleAspectFit
        
        detailView.image = .avatarDetail
        detailView.contentMode = .scaleToFill
        
        detailTitleLabel.font = .highlight4
        detailTitleLabel.textColor = .textSecondary
        
        detailLabel.font = .alert2
        detailLabel.textColor = .textSecondary
        detailLabel.numberOfLines = 0
        
        collectionView.backgroundColor = .textInverse
        collectionView.register(SelectAvatarCell.self, forCellWithReuseIdentifier: SelectAvatarCell.identifier)
        
        choiceButton.isEnabled = false
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16
        horizontalStackView.distribution = .fill
        
        pageControl.currentPage = 0
        pageControl.isUserInteractionEnabled = false
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary2
        pageControl.pageIndicatorTintColor = .keycolorPrimary5
    }
    
    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(28)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        avatarImageView.snp.makeConstraints {
            $0.height.equalTo(206)
            $0.top.equalTo(titleLabel.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        avatarBackground.snp.makeConstraints {
            $0.width.height.equalTo(avatarImageView).inset(8)
            $0.center.equalTo(avatarImageView)
        }
        
        detailView.snp.makeConstraints {
            $0.top.equalTo(avatarImageView.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(collectionView.snp.top).offset(-16)
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
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(detailView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.bottom.equalTo(horizontalStackView.snp.top).offset(-42)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom)
            $0.centerX.equalToSuperview()
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
        }
        
        backButton.snp.makeConstraints {
            $0.width.equalTo(choiceButton).multipliedBy(1.0 / 2.0)
        }
    }
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<SelectAvatarViewModel.SelectAvatarDataSource> {
        return RxCollectionViewSectionedReloadDataSource<SelectAvatarViewModel.SelectAvatarDataSource>(
            configureCell: { dataSource, collectionView, IndexPath, section in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectAvatarCell.identifier, for: IndexPath) as? SelectAvatarCell else { return .init() }
                
                cell.settingCell(imageName: section)
                
                return cell
            })
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .fractionalHeight(1)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1/3),
                                                                         heightDimension: .estimated(116)),
                                                       subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        
        section.orthogonalScrollingBehavior = .paging
        section.visibleItemsInvalidationHandler = { [weak self] items, offset, environment in
            let viewWidth = environment.container.contentSize.width
            self?.pageControl.currentPage = Int((offset.x + (viewWidth / 2)) / viewWidth)
        }
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
