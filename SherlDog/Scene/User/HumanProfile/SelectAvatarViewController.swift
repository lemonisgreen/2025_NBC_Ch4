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
    private let dataSource = RxCollectionViewSectionedReloadDataSource<SelectAvatarViewModel.SelectAvatarDataSource>(
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
    
    private let backButton = ComponentSubButton(title: "이전")
    private let choiceButton = ComponentButton(title: "선택하기")
    private let horizontalStackView = UIStackView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    
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
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel.output.moveToDetailView
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                let detailView = DetailAvatarViewController(viewModel: self.viewModel)
                detailView.modalPresentationStyle = .pageSheet
                if let sheet = detailView.sheetPresentationController {
                    sheet.detents = [.custom { _ in 610 }]
                    sheet.selectedDetentIdentifier = .medium
                    sheet.preferredCornerRadius = 20
                    sheet.prefersGrabberVisible = true
                }
                self.present(detailView, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.collectionView.rx.itemSelected
            .take(1)
            .subscribe(onNext: { [weak self] _ in
                self?.choiceButton.isEnabled = true
            })
            .disposed(by: disposeBag)

        self.backButton.rx.tap
            .subscribe { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        self.choiceButton.rx.tap
            .subscribe { [weak self] _ in
                guard let index = self?.collectionView.indexPathsForSelectedItems?.first?.row else { return }
                self?.viewModel.input.accept(.goNext(index))
            }
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .textInverse
        
        [backButton, choiceButton]
            .forEach { horizontalStackView.addArrangedSubview($0) }
        
        [collectionView, horizontalStackView]
            .forEach { view.addSubview($0) }
        
        collectionView.backgroundColor = .textInverse
        collectionView.register(SelectAvatarCell.self, forCellWithReuseIdentifier: SelectAvatarCell.identifier)
        collectionView.register(PictureUploadRequestViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PictureUploadRequestViewHeader.identifier)
        
        choiceButton.isEnabled = false
        
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 16
        horizontalStackView.distribution = .fill
    }
    
    private func configureUI() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
        }
        
        horizontalStackView.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
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
