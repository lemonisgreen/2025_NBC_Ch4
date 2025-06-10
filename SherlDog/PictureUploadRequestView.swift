//
//  PictureUploadRequestView.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
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
    private let dataSource = RxCollectionViewSectionedReloadDataSource<PictureUploadRequestViewModel.RequestSection>(
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
    private let setButton = UIButton()

    init(viewModel: PictureUploadRequestViewModel?) {
        self.viewModel = viewModel
        self.viewModel?.input.accept(.sender(.pictureRequest)) // test

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
        self.viewModel?.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel?.output.buttonName
            .subscribe(onNext: { [weak self] name in
                guard let self else { return }
                
                self.setButton.setTitle(name, for: .normal)
            })
            .disposed(by: disposeBag)
        
        self.collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self, let sender = self.viewModel?.output.sender.value else { return }
                
                switch sender {
                case .pictureRequest, .pictureRequestWithIcon:
                    
                    self.collectionView.visibleCells.enumerated().forEach { index, item in
                        if index == indexPath.row {
                            item.isSelected.toggle()
                        } else {
                            item.isSelected = false
                        }
                    }
                    
                case .sherlDogRequest:
                    self.collectionView.visibleCells[indexPath.row].isSelected.toggle()
                    
                case .sherlDogResult: return    // .sherlDogResult is read only
                }
                
            })
            .disposed(by: disposeBag)
        
        self.setButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self else { return }
                
                var selectedIndex: [Int] = []
                
                self.collectionView.visibleCells.enumerated().forEach { index, item in
                    if item.isSelected {
                        selectedIndex.append(index)
                    }
                }
                
                self.viewModel?.input.accept(.setButtonTapped(selectedIndex))
            }
            .disposed(by: disposeBag)
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(setButton)

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

