//
//  CommunityViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxDataSources

// 레이아웃/등록/데이터소스에서 공통 사용
enum PostElementKind {
    static let header = "post-header-kind"
    static let footer = "post-footer-kind"
}

// MARK: - CommunityViewController
final class CommunityViewController: UIViewController {
    
    private let viewModel = CommunityViewModel()
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = setDataSource()
    
    // MARK: - UIProperty
    private lazy var segmentedControl = CommunitySegmentedControl(items: self.viewModel.output.sectionName.value)
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    private let addButton = UIButton()
    
    // MARK: - Lifecycle
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

// MARK: - Bindings
extension CommunityViewController {
    
    private func bind() {
        Observable.combineLatest(
            viewModel.output.selectedCategory,
            viewModel.output.currentCellData
        )
        .map { category, data in
            guard let result = data[category] else { return [] }
            
            return result
        }
        .asDriver(onErrorJustReturn: [])
        .drive(self.collectionView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        viewModel.output.selectedCategory
            .map {
                switch $0 {
                case .invLogBoard: return true
                case .detectiveMateBoard: return false
                }
            }
            .asDriver(onErrorJustReturn: true)
            .drive(self.addButton.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.segmentedControl.rx.selectedSegmentIndex
            .map { .segmentedControlChanged($0) }
            .bind(to: viewModel.input)
            .disposed(by: disposeBag)
        
        self.addButton.rx.tap
            .asSignal()
            .emit(onNext: { [weak self] in
                self?.navigationController?.pushViewController(AddNewContentViewController(), animated: true)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UI
extension CommunityViewController {
    
    private func setupUI() {
        view.backgroundColor = .textInverse
        view.addSubviews([
            segmentedControl,
            collectionView,
            addButton
        ])
        
        segmentedControl.selectedSegmentIndex = 0
        
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        collectionView.register(PostHeaderView.self,
                                forSupplementaryViewOfKind: PostElementKind.header,
                                withReuseIdentifier: PostHeaderView.identifier)
        collectionView.register(PostFooterView.self,
                                forSupplementaryViewOfKind: PostElementKind.footer,
                                withReuseIdentifier: PostFooterView.identifier)
        collectionView.backgroundColor = .textInverse
        
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .bold)
        let image = UIImage(systemName: "plus.circle.fill", withConfiguration: config)
        addButton.setImage(image, for: .normal)
        addButton.tintColor = .keycolorPrimary2
    }
    
    private func configureUI() {
        segmentedControl.snp.makeConstraints {
            $0.height.equalTo(50)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(segmentedControl.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        addButton.snp.makeConstraints {
            $0.trailing.bottom.equalTo(collectionView).offset(-16)
        }
    }
}

// MARK: - DataSource
extension CommunityViewController {
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunitySection> {
        return RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunitySection>(
            configureCell: { _, collectionView, indexPath, item in
                // item == String (이미지 URL)
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else { return .init() }
                
                cell.settingCell(item)
                
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                // 섹션 모델 == CommunityModel
                let sectionModel = dataSource.sectionModels[indexPath.section].model
                switch kind {
                case PostElementKind.header:
                    guard let header = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PostHeaderView.identifier,
                        for: indexPath
                    ) as? PostHeaderView else { return .init() }
                    
                    header.settingCell(data: sectionModel)
                    
                    return header
                    
                case PostElementKind.footer:
                    guard let footer = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PostFooterView.identifier,
                        for: indexPath
                    ) as? PostFooterView else { return .init() }
                    
                    footer.settingCell(data: sectionModel)
                    
                    return footer
                    
                default:
                    return .init()
                }
            }
        )
    }
}

// MARK: - Compositional Layout
extension CommunityViewController {
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 8
        
        // 아이템(이미지 한 장)
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                              heightDimension: .fractionalHeight(1.0))
        )
        item.contentInsets = .zero
        
        // 가로 페이징 그룹
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                              heightDimension: .estimated(300)),
            subitems: [item]
        )
        
        // 헤더
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                              heightDimension: .estimated(64)),
            elementKind: PostElementKind.header,
            alignment: .top
        )
        
        // 푸터
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                              heightDimension: .estimated(20)),
            elementKind: PostElementKind.footer,
            alignment: .bottom
        )
        
        // 섹션
        let section = NSCollectionLayoutSection(group: group)
        section.boundarySupplementaryItems = [header, footer]
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 0
        section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}
