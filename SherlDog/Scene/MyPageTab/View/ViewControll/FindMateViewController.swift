//
//  FindMateViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/24/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import FirebaseAuth

final class FindMateViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel = CommunityViewModel()
    private lazy var dataSource = setDataSource()
    private let refreshControl = UIRefreshControl()
    private let manualRefresh = PublishRelay<Void>()
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let collectionView = UICollectionView(frame: .zero,
                                                  collectionViewLayout: UICollectionViewLayout())
    
    private let menuEvent = PublishSubject<PostMenuEvent>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //self.navigationController?.navigationBar.isHidden = true
        manualRefresh.accept(())
    }
}

// MARK: - UI
private extension FindMateViewController {
    func setupUI() {
        
        navigationBackButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationBackButtonImage), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.FindMateViewController.navigationTitle
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        
        collectionView.setCollectionViewLayout(collectionViewCompositionalLayout(), animated: false)
        collectionView.backgroundColor = .keycolorBackground
        collectionView.refreshControl = refreshControl
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        collectionView.register(PostHeaderView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PostHeaderView.identifier)
        collectionView.register(PostFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: PostFooterView.identifier)
        
        view.backgroundColor = .keycolorBackground
        
        view.addSubview(collectionView)
        
        collectionView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
}

// MARK: - Bind
private extension FindMateViewController {
    func bind() {
        
        navigationBackButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        guard let currentUserId = Auth.auth().currentUser?.uid else { return }
        
        let input = CommunityViewModel.Input(
                    segmentIndexChanged: Observable.just(
                        CommunitySectionType.allCases.firstIndex(of: .detectiveMateBoard) ?? 1
                    ),
                    pullToRefresh: refreshControl.rx.controlEvent(.valueChanged).asObservable(),
                    manualRefresh: manualRefresh.asObservable(),
                    fetchMore: Observable.empty(),
                    menuEvent: menuEvent.asObservable(),
//                    likeEvent: Observable.never()
                )
        
        let output = viewModel.transform(input)
        
        output.currentCellData
            .map { dict -> [CommunityViewModel.CommunitySection] in
                let data = dict[.detectiveMateBoard] ?? []
                return data.filter { $0.model.userId == currentUserId }
            }
            .drive(collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        output.isUpdating
            .drive(refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
    }
}

// MARK: - DataSource
private extension FindMateViewController {
    func setDataSource() -> RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunitySection> {
        return RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunitySection>(
            configureCell: { dataSource, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: MediaCell.identifier,
                    for: indexPath
                ) as? MediaCell else { return UICollectionViewCell() }
                
                let petProfile = dataSource.sectionModels[indexPath.section].model.petProfile
                cell.settingCell(item)
                cell.settingPetProfile(profile: petProfile)
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                switch kind {
                    
                case UICollectionView.elementKindSectionHeader:
                    guard let header = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PostHeaderView.identifier,
                        for: indexPath
                    ) as? PostHeaderView else { return UICollectionReusableView() }
                    let model = dataSource.sectionModels[indexPath.section].model
                    header.settingCell(data: model)
                    
                    header.configButton.menu = self.myPostMenu(post: model)
                            header.configButton.showsMenuAsPrimaryAction = true  // ← 탭 시 바로 메뉴 팝업
                            header.configButton.isContextMenuInteractionEnabled = true
                    return header
                    
                case UICollectionView.elementKindSectionFooter:
                    guard let footer = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PostFooterView.identifier,
                        for: indexPath
                    ) as? PostFooterView else { return UICollectionReusableView() }
                    let model = dataSource.sectionModels[indexPath.section].model
                    footer.settingCell(data: model, collection: FirestoreCollection.detectiveMate, isDetail: false)
                    footer.updatePage(total: dataSource.sectionModels[indexPath.section].items.count, current: 0)
                    return footer
                default:
                    return UICollectionReusableView()
                }
            }
        )
    }
    
    private func myPostMenu(post: CommunityModel) -> UIMenu {
        let fixAction = UIAction(
            title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                          SDLiteral.CommunityView.fix)
        ) { [weak self] _ in
            guard let self else { return }
            let editView = AddNewContentViewController(
                category: .detectiveMateBoard,
                post: post
            )
            self.navigationController?.pushViewController(editView, animated: true)
        }

        let deleteAction = UIAction(
            title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                          SDLiteral.CommunityView.delete),
            attributes: .destructive
        ) { [weak self] _ in
            self?.showDeleteConfirmAlert(documentId: post.documentId)
        }

        return UIMenu(children: [fixAction, deleteAction])
    }
    
    private func showDeleteConfirmAlert(documentId: String) {
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.menuAlertMessage,
                            SDLiteral.CommunityView.delete),
            buttons: [
                .init(title: SDLiteral.AlertMessage.cancel, action: nil),
                .init(title: SDLiteral.CommunityView.delete, action: { [weak self] in
                    self?.menuEvent.onNext(.delete(documentId))
                })
            ]
        )
        present(alert, animated: true)
    }
}


// MARK: - Layout
private extension FindMateViewController {
    func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 16
        return UICollectionViewCompositionalLayout { sectionIndex, env in
            let item = NSCollectionLayoutItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                  heightDimension: .fractionalHeight(1.0))
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                  heightDimension: .estimated(300)),
                subitems: [item]
            )
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                  heightDimension: .estimated(64)),
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                  heightDimension: .estimated(60)),
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [header, footer]
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
            return section
        }
    }
}
