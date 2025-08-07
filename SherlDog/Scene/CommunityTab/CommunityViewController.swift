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

// MARK: - CommunityViewController
class CommunityViewController: UIViewController {
    
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

// MARK: - Method
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
    
    private func setupUI() {
        view.backgroundColor = .textInverse
        view.addSubviews([
            segmentedControl,
            collectionView,
            addButton
        ])
        
        segmentedControl.selectedSegmentIndex = 0
        
        collectionView.backgroundColor = .textInverse
        collectionView.register(CommunityCell.self, forCellWithReuseIdentifier: CommunityCell.identifier)
        
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
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunityData> {
        return RxCollectionViewSectionedReloadDataSource(configureCell: { dataSource, collectionView, indexPath, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommunityCell.identifier, for: indexPath) as? CommunityCell else { return .init() }
            
            cell.settingCell(data: item)
            
            return cell
        })
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 16
        
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .estimated(300)))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                       heightDimension: .estimated(300)),
                                                     subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}
