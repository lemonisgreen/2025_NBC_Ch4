//
//  asdf.swift
//  SherlDog
//
//  Created by 최규현 on 6/5/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxDataSources
import Differentiator

// MARK: - PictureUploadView
class PictureUploadRequestView: UIViewController {
    
    private let viewModel: PictureUploadRequestViewModel?
    private let disposeBag = DisposeBag()
    private let dataSource = RxCollectionViewSectionedReloadDataSource<PictureUploadRequestViewModel.PictureRequestSection>(
        configureCell: { dataSource, collectionView, indexPath, section in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PictureUploadRequestViewCell.identifier, for: indexPath) as? PictureUploadRequestViewCell else { return UICollectionViewCell() }
            cell.settingCell(text: section.title, imageName: section.image)
            
            return cell
        }, configureSupplementaryView: { dataSource, collectionView, title, indexPath in
            guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                               withReuseIdentifier: PictureUploadRequestViewHeader.identifier,
                                                                               for: indexPath) as? PictureUploadRequestViewHeader else { return UICollectionReusableView() }
            let title = dataSource.sectionModels[indexPath.section].model
            header.setTitle(title: title)
            
            return header
        }
    )
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    
    init(viewModel: PictureUploadRequestViewModel?) {
        self.viewModel = viewModel
        self.viewModel?.input.accept(.defaultRequest) // test
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Lifecycle
extension PictureUploadRequestView {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
    
}

// MARK: - Method
extension PictureUploadRequestView {
    
    private func bind() {
        self.viewModel?.output
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected.subscribe { indexPath in
            guard let index = indexPath.element else { return }
            
            if index.row < 2 {
                switch index.row {
                case 0:
                    print("사진 보관함")
                case 1:
                    print("사진 찍기")
                default:
                    return
                }
            } else {
                switch index.row {
                case 0:
                    print("기본 아바타 선택")
                case 1:
                    print("사진 보관함")
                case 2:
                    print("사진 찍기")
                default:
                    return
                }
            }
        }
        .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        
        collectionView.register(PictureUploadRequestViewCell.self,
                                forCellWithReuseIdentifier: PictureUploadRequestViewCell.identifier)
        collectionView.register(PictureUploadRequestViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PictureUploadRequestViewHeader.identifier)
    }
    
    private func configureUI() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .absolute(70)))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                       heightDimension: .fractionalHeight(1/5)),
                                                     subitems: [item])
        
        group.interItemSpacing = .fixed(12)
        
        let section = NSCollectionLayoutSection(group: group)
        
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                   heightDimension: .estimated(60)),
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}

