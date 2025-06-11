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
class SelectDefaultAvatarViewController: UIViewController {
    
    private let viewModel = SelectDefaultAvatarViewModel()
    private let disposeBag = DisposeBag()
    private let dataSource = RxCollectionViewSectionedReloadDataSource<SelectDefaultAvatarViewModel.DataSource>(
        configureCell: { dataSource, collectionView, IndexPath, section in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SelectAvatarCell.identifier, for: IndexPath) as? SelectAvatarCell else { return .init() }
            
            cell.settingCell(imageName: section)
            
            return cell
        }, configureSupplementaryView: { dataSource, collectionView, title, indexPath in
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PictureUploadRequestViewHeader.identifier, for: indexPath) as? PictureUploadRequestViewHeader else { return .init() }
            
            let title = dataSource.sectionModels[indexPath.section].model
            header.setTitle(title: title)
            
            return header
        })
    
    private let backButton = UIButton()
    private let choiceButton = UIButton()
    private let horizontalStackView = UIStackView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    
}

// MARK: - Lifecycle
extension SelectDefaultAvatarViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
    
}

// MARK: - Method
extension SelectDefaultAvatarViewController {
    
    private func bind() {
        self.viewModel.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.backButton.rx.tap
            .subscribe { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        [backButton, choiceButton]
            .forEach { horizontalStackView.addArrangedSubview($0) }
        
        [collectionView, horizontalStackView]
            .forEach { view.addSubview($0) }
        
        collectionView.register(SelectAvatarCell.self, forCellWithReuseIdentifier: SelectAvatarCell.identifier)
        collectionView.register(PictureUploadRequestViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PictureUploadRequestViewHeader.identifier)
        
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
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.bottom.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.height.equalTo(52)
        }
        
        backButton.snp.makeConstraints {
            $0.width.equalTo(choiceButton).multipliedBy(1.0 / 2.0)
        }
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1/3),
                                                            heightDimension: .fractionalHeight(1)))
        
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                         heightDimension: .fractionalHeight(1/4)),
                                                       subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                   heightDimension: .estimated(60)),
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
