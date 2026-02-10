//
//  UserPostsViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/26/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxDataSources
import FirebaseAuth

final class UserPostsViewController: UIViewController {
    
    private let likeButtonEvent = PublishRelay<CommunityModel>()
    private let menuEvent = PublishRelay<PostMenuEvent>()
    private let manualRefresh = PublishRelay<Void>()
    
    private let viewModel: UserPostsViewModel
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = setDataSource()
    private let refreshControl = UIRefreshControl()
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    lazy var segmentedControl = CommunitySegmentedControl(items: CommunitySectionType.allCases.map { $0.name })
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    
    init(userId: String) {
        self.viewModel = UserPostsViewModel(userId: userId)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
        manualRefresh.accept(())
    }
}

// MARK: - Bindings
private extension UserPostsViewController {
    func bind() {
        
        navigationBackButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        let input = UserPostsViewModel.Input(
            segmentIndexChanged: self.segmentedControl.rx.selectedSegmentIndex.asObservable(),
            pullToRefresh: self.refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            manualRefresh: manualRefresh.asObservable(),
            fetchMore: Observable.empty(),
            menuEvent: self.menuEvent.asObservable(),
            likeEvent: likeButtonEvent.asObservable()
        )
        
        let output = viewModel.transform(input)
        
        Driver.combineLatest(output.selectedCategory, output.currentCellData)
            .map { category, data -> [CommunityViewModel.CommunitySection] in
                guard let result = data[category] else { return [] }
                return result
            }
            .drive(self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        output.isUpdating
            .drive(self.refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
        
        output.menuComplete
            .emit(onNext: { [weak self] type in
                switch type {
                case .delete(_), .block(_):
                    self?.completeAlert(type: type)
                default: return
                }
            })
            .disposed(by: disposeBag)
    }
}

private extension UserPostsViewController {
    typealias Section = CommunityViewModel.CommunitySection
    
    func setDataSource() -> RxCollectionViewSectionedReloadDataSource<Section> {
        return RxCollectionViewSectionedReloadDataSource<Section>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item in
                guard let self = self else { return .init() }
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else {
                    return .init()
                }
                
                let sectionModel = dataSource.sectionModels[indexPath.section].model
                let petProfile = sectionModel.petProfile
                
                cell.settingCell(item)
                cell.settingPetProfile(profile: petProfile)
                
                cell.rx.mediaDoubleTap
                    .map { _ in sectionModel }
                    .bind(to: self.likeButtonEvent)
                    .disposed(by: cell.disposeBag)
                
                return cell
            },
            configureSupplementaryView: { [weak self] dataSource, collectionView, kind, indexPath in
                guard let self = self else { return .init() }
                let sectionModel = dataSource.sectionModels[indexPath.section].model
                
                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PostHeaderView.identifier, for: indexPath) as? PostHeaderView else { return .init() }
                    
                    header.settingCell(data: sectionModel)
                    header.settingMenu(menu: self.isWriter(sectionModel.userId) ? self.myPostMenu(post: sectionModel) : self.otherPostMenu(post: sectionModel))
                    
                    return header
                    
                case UICollectionView.elementKindSectionFooter:
                    guard let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: PostFooterView.identifier, for: indexPath) as? PostFooterView else { return .init() }
                    
                    let count = dataSource.sectionModels[indexPath.section].items.count
                    let category: FirestoreCollection = {
                        let index = self.segmentedControl.selectedSegmentIndex
                        return CommunitySectionType.allCases.indices.contains(index) ? CommunitySectionType.allCases[index].toFirestoreCollection : .invLogBoard
                    }()
                    
                    footer.settingCell(data: sectionModel, collection: category, isDetail: false)
                    footer.updatePage(total: count, current: 0)
                    
                    let footerVM = PostFooterViewModel(category: category, post: sectionModel)
                    footer.bind(viewModel: footerVM)
                    
                    footer.rx.containerTap
                        .observe(on: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] in
                            let alert = CustomAlertViewController(
                                message: "Test alert",
                                subMessage: "Move to detail view",
                                buttons: [ CustomAlertViewController.AlertButton(title: SDLiteral.AlertMessage.confirm, action: nil) ]
                            )
                            self?.present(alert, animated: true)
                        })
                        .disposed(by: footer.disposeBag)
                    
                    return footer
                    
                default:
                    return .init()
                }
            }
        )
    }
}

// MARK: - Compositional Layout
private extension UserPostsViewController {
    func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 16
        return UICollectionViewCompositionalLayout { row, env in
            let item = NSCollectionLayoutItem(layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)))
            item.contentInsets = .zero
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(300)), subitems: [item])
            
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(64)),
                elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(60)),
                elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
            
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [header, footer]
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = 0
            section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
            
            section.visibleItemsInvalidationHandler = { [weak self] items, offset, environment in
                guard let self = self else { return }
                let pageWidth = environment.container.contentSize.width
                let page = Int(round(offset.x / pageWidth))
                let indexPath = IndexPath(item: 0, section: row)
                let total = self.dataSource.sectionModels[row].items.count
                if let footerView = self.collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: indexPath) as? PostFooterView {
                    footerView.updatePage(total: total, current: page)
                }
            }
            
            return section
        }
    }
}

// MARK: - UI
private extension UserPostsViewController {
    func setupUI() {
        view.backgroundColor = .white
        view.addSubviews([ segmentedControl, collectionView ])
        
        navigationBackButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationBackButtonImage), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.UserPostViewController.navigationTitle
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .clear
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        
        collectionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        collectionView.register(PostHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PostHeaderView.identifier)
        collectionView.register(PostFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: PostFooterView.identifier)
        
        collectionView.backgroundColor = .clear
        collectionView.refreshControl = refreshControl
        segmentedControl.selectedSegmentIndex = 0
    }
    
    func configureUI() {
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
    }
}

extension UserPostsViewController {
    func isWriter(_ postUserId: String) -> Bool {
        guard let currentUserId = AuthSession.currentAppUserId else { return false }
        return postUserId == currentUserId
    }
    
    func myPostMenu(post: CommunityModel) -> UIMenu {
        let fixAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle, SDLiteral.CommunityView.fix)) { [weak self] _ in
            let category: CommunitySectionType = self?.segmentedControl.selectedSegmentIndex == 0 ? .invLogBoard : .detectiveMateBoard
            let editVC = AddNewContentViewController(category: category, post: post)
            self?.navigationController?.pushViewController(editVC, animated: true)
        }
        let deleteAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle, SDLiteral.CommunityView.delete)) { [weak self] _ in
            self?.showMenuAlert(type: .delete(post.documentId))
        }
        return UIMenu(children: [fixAction, deleteAction])
    }
    
    func otherPostMenu(post: CommunityModel) -> UIMenu {
        let blockAction = UIAction(
            title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                          SDLiteral.CommunityView.block)
        ) { [weak self] _ in
            self?.showMenuAlert(type: .block(post.userId))
        }
        
        let reportAction = UIAction(
            title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                          SDLiteral.CommunityView.report)
        ) { [weak self] _ in
            self?.presentReportForPost(post)
        }
        
        return UIMenu(children: [blockAction, reportAction])
    }
    
    /// 현재 세그먼트(탭)에 맞는 컬렉션 계산
    func currentCommunityCollection() -> FirestoreCollection {
        let index = segmentedControl.selectedSegmentIndex
        let type = CommunitySectionType.allCases.indices.contains(index)
        ? CommunitySectionType.allCases[index]
        : .invLogBoard
        return type.toFirestoreCollection
    }
    
    func presentReportForPost(_ post: CommunityModel) {
        let collection = currentCommunityCollection()
        let reportVC = ReportViewController(
            target: .post(collection: collection,
                          documentId: post.documentId,
                          postUserId: post.userId)
        )
        reportVC.onReportCompleted = { [weak self] in
            self?.blockMessageAfterReport(userId: post.userId)
        }
        
        reportVC.modalPresentationStyle = .pageSheet
        reportVC.isModalInPresentation = false
        
        if let sheet = reportVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
        }
        present(reportVC, animated: true)
    }
    
    func showMenuAlert(type: PostMenuEvent, completion: (() -> ())? = nil) {
        switch type {
        case .fix, .error: return
        default: break
        }
        var title: String {
            switch type {
            case .fix: return SDLiteral.CommunityView.fix
            case .delete: return SDLiteral.CommunityView.delete
            case .report: return SDLiteral.CommunityView.report
            case .block: return SDLiteral.CommunityView.block
            case .error: return SDLiteral.CommunityView.error
            }
        }
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.menuAlertMessage, title),
            buttons: [
                CustomAlertViewController.AlertButton(title: SDLiteral.AlertMessage.cancel, action: nil),
                CustomAlertViewController.AlertButton(title: title, action: { [weak self] in
                    self?.menuEvent.accept(type)
                    completion?()
                })
            ]
        )
        self.present(alert, animated: true)
    }
    
    func blockMessageAfterReport(userId: String) {
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.completeAlert, SDLiteral.CommunityView.report),
            subMessage: SDLiteral.CommunityView.blockMessageAfterReport,
            buttons: [
                CustomAlertViewController.AlertButton(title: SDLiteral.AlertMessage.cancel, action: nil),
                CustomAlertViewController.AlertButton(title: SDLiteral.CommunityView.block, action: { [weak self] in
                    self?.menuEvent.accept(.block(userId))
                })
            ]
        )
        self.present(alert, animated: true)
    }
    
    func completeAlert(type: PostMenuEvent) {
        switch type { case .fix, .error: return default: break }
        let message: String = {
            switch type {
            case .delete:  return SDLiteral.CommunityView.delete
            case .block:   return SDLiteral.CommunityView.block
            case .report:  return SDLiteral.CommunityView.report
            default: return String()
            }
        }()
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.completeAlert, message),
            buttons: [ CustomAlertViewController.AlertButton(title: SDLiteral.AlertMessage.confirm, action: nil) ]
        )
        present(alert, animated: true)
    }
}
