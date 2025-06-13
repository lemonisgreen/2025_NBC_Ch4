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
    private let dataSource = RxCollectionViewSectionedReloadDataSource<PictureUploadRequestViewModel.RequestDataSource>(
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
        outputBind()
        inputBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }

}

// MARK: - Method
extension PictureUploadRequestView {

    private func outputBind() {
        self.viewModel?.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel?.output.sender
            .subscribe(onNext: { sender in
                guard let sender else { return }
                switch sender {
                    
                case .pictureRequest, .pictureRequestWithIcon:
                    self.collectionView.allowsMultipleSelection = false
                    self.setButton.isEnabled = false
                    
                case .sherlDogRequest:
                    self.collectionView.allowsMultipleSelection = true
                    self.setButton.isEnabled = false
                    
                case .sherlDogResult:
                    self.collectionView.allowsSelection = false
                    self.setButton.isEnabled = true
                }
            })
            .disposed(by: disposeBag)
        
        self.viewModel?.output.buttonName
            .subscribe(onNext: { [weak self] name in
                guard let self else { return }
                
                self.setButton.setTitle(name, for: .normal)
                self.setButton.backgroundColor = .keycolorPrimary3
            })
            .disposed(by: disposeBag)
        
        self.viewModel?.output.moveToView
            .subscribe(onNext: { [weak self] list in
                switch list {
                case .camera:
                    let cameraView = UINavigationController(rootViewController: CameraViewController(to: .communityShare))
                    cameraView.modalPresentationStyle = .fullScreen
                    self?.present(cameraView, animated: true)
                    
                case .album:
                    print("album")
                    
                case .avatar:
                    self?.navigationController?.pushViewController(SelectAvatarViewController(), animated: true)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.fetchButtonEnable()
            })
            .disposed(by: disposeBag)
        
        self.collectionView.rx.itemDeselected
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.fetchButtonEnable()
            })
            .disposed(by: disposeBag)
        
        self.setButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self else { return }
                // 함께 수사한 탐정 모달이면 창 닫고 끝냄
                guard self.viewModel?.output.sender.value != .sherlDogResult else {
                    self.dismiss(animated: true)
                    return
                }
                
                var selectedIndex: [Int] = []
                
                collectionView.indexPathsForSelectedItems?.forEach {
                    selectedIndex.append($0.row)
                }
                
                self.viewModel?.input.accept(.setButtonTapped(selectedIndex))
            }
            .disposed(by: disposeBag)
    }
    
    private func fetchButtonEnable() {
        guard self.viewModel?.output.sender.value != .sherlDogResult else {
            self.setButton.isEnabled = true
            return
        }
        
        guard let count = self.collectionView.indexPathsForSelectedItems?.count else { return }
        if count > 0 {
            self.setButton.isEnabled = true
        } else {
            self.setButton.isEnabled = false
        }
    }

    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(collectionView)
        view.addSubview(setButton)
        
        setButton.layer.cornerRadius = 6
        setButton.layer.masksToBounds = true

        collectionView.register(PictureUploadRequestViewCell.self,
                                forCellWithReuseIdentifier: PictureUploadRequestViewCell.identifier)
        collectionView.register(PictureUploadRequestViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PictureUploadRequestViewHeader.identifier)
    }

    private func configureUI() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
        }
        
        setButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(21.5)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
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

