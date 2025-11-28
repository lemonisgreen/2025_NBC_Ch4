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
import FirebaseAuth

// 셀 메뉴 버튼 타입
enum PostMenuEvent {
    case fix
    case delete(String)
    case report(String)
    case block(String)
    case error
}

// MARK: - CommunityViewController
final class CommunityViewController: UIViewController {
    
//    private let likeButtonEvent = PublishRelay<CommunityModel>()
    private let menuEvent = PublishRelay<PostMenuEvent>()
    private let manualRefresh = PublishRelay<Void>()
    
    private let viewModel = CommunityViewModel()
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = setDataSource()
    private let refreshControl = UIRefreshControl()
    
    // MARK: - UIProperty
    private lazy var segmentedControl = CommunitySegmentedControl(items: CommunitySectionType.allCases.map { $0.name })
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    private let addButton = UIButton()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
        manualRefresh.accept(())
    }
}

// MARK: - Bindings
extension CommunityViewController {
    
    private func bind() {
        // MARK: - Inputs
        let input = CommunityViewModel.Input(segmentIndexChanged: self.segmentedControl.rx.selectedSegmentIndex.asObservable(),
                                             pullToRefresh: self.refreshControl.rx.controlEvent(.valueChanged).asObservable(),
                                             manualRefresh: manualRefresh.asObservable(),
                                             fetchMore: Observable.empty(),
                                             menuEvent: self.menuEvent.asObservable())
        
        self.addButton.rx.tap
            .asSignal()
            .emit(onNext: { [weak self] in
                let addNewContentViewController = AddNewContentViewController()
                addNewContentViewController.hidesBottomBarWhenPushed = true
                self?.navigationController?.pushViewController(addNewContentViewController, animated: true)
            })
            .disposed(by: disposeBag)
        
        
        // MARK: - Outputs
        let output = viewModel.transform(input)
        
        Driver.combineLatest(
            output.selectedCategory,
            output.currentCellData
        )
        .map { category, data in
            guard let result = data[category] else { return [] }
            
            return result
        }
        .drive(self.collectionView.rx.items(dataSource: dataSource))
        .disposed(by: disposeBag)
        
        output.selectedCategory
            .map {
                switch $0 {
                case .invLogBoard: return true
                case .detectiveMateBoard: return false
                }
            }
            .drive(self.addButton.rx.isHidden)
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

// MARK: - Cell Menu Button Setting
extension CommunityViewController {
    private func isWriter(_ postUserId: String) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return postUserId == currentUserId
    }
    
    private func myPostMenu(post: CommunityModel) -> UIMenu {
        let fixAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                               SDLiteral.CommunityView.fix)) { [weak self] action in
            let category: CommunitySectionType = {
                self?.segmentedControl.selectedSegmentIndex == 0 ? .invLogBoard : .detectiveMateBoard
            }()
            
            let editView = AddNewContentViewController(category: category, post: post)
            editView.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(editView, animated: true)
        }
        
        let deleteAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.delete)) { [weak self] _ in
            self?.showMenuAlert(type: .delete(post.documentId))
        }
        
        return UIMenu(children: [fixAction, deleteAction])
    }
    
    private func otherPostMenu(post: CommunityModel) -> UIMenu {
        let blockAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                 SDLiteral.CommunityView.block)) { [weak self] _ in
            self?.showMenuAlert(type: .block(post.userId))
        }
        
        let reportAction = UIAction(
            title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                          SDLiteral.CommunityView.report)
        ) { [weak self] _ in
            guard let self else { return }
            
            self.showMenuAlert(type: .report(post.documentId)) { [weak self] in
                self?.presentReportForPost(post)
            }
        }
        
        return UIMenu(children: [blockAction, reportAction])
    }
    
    func presentReportForPost(_ post: CommunityModel) {
        let category: CommunitySectionType = .invLogBoard
        let reportVC = ReportViewController(
            target: .post(collection: category.toFirestoreCollection,
                          documentId: post.documentId,
                          postUserId: post.userId)
        )
        
        reportVC.onReportCompleted = { [weak self] in
                self?.blockMessageAfterReport(userId: post.userId)
            }
        reportVC.modalPresentationStyle = .pageSheet
        reportVC.isModalInPresentation = true
        
        if let sheet = reportVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
        }
        present(reportVC, animated: true)
    }
    
    private func showMenuAlert(type: PostMenuEvent, completion: (() -> ())? = nil) {
        switch type {
        case .fix, .error:
            return
        default:
            break
        }
        
        var title: String {
            switch type {
            case .fix: return    SDLiteral.CommunityView.fix
            case .delete: return SDLiteral.CommunityView.delete
            case .report: return SDLiteral.CommunityView.report
            case .block: return  SDLiteral.CommunityView.block
            case .error: return  SDLiteral.CommunityView.error
            }
        }
        
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.menuAlertMessage, title),
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.AlertMessage.cancel,
                    action: nil
                ),
                CustomAlertViewController.AlertButton(
                    title: title,
                    action: { [weak self] in
                        self?.menuEvent.accept(type)
                        completion?()
                    }
                )
            ]
        )
        
        self.present(alert, animated: true)
    }
    
    private func blockMessageAfterReport(userId: String) {
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.completeAlert,
                            SDLiteral.CommunityView.report),
            subMessage: SDLiteral.CommunityView.blockMessageAfterReport,
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.AlertMessage.cancel,
                    action: nil),
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.CommunityView.block,
                    action: { [weak self] in
                        self?.menuEvent.accept(.block(userId))
                    }
                )
            ]
        )
        
        self.present(alert, animated: true)
    }
    
    private func completeAlert(type: PostMenuEvent) {
        switch type {
        case .fix, .error:
            return
        default:
            break
        }
        
        var message: String {
            switch type {
            case .delete: SDLiteral.CommunityView.delete
            case .block:  SDLiteral.CommunityView.block
            case .report: SDLiteral.CommunityView.report
            default: String()
            }
        }
        
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.completeAlert, message),
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.AlertMessage.confirm,
                    action: nil
                )
            ]
        )
        
        self.present(alert, animated: true)
    }
}

// MARK: - DataSource
extension CommunityViewController {
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunitySection> {
        return RxCollectionViewSectionedReloadDataSource<CommunityViewModel.CommunitySection>(
            
            // MARK: - PostMediaCell
            configureCell: { dataSource, collectionView, indexPath, item in
                // item == String (이미지 URL)
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else { return .init() }
                let model = dataSource.sectionModels[indexPath.section].model
                
                let category = CommunitySectionType.allCases[self.segmentedControl.selectedSegmentIndex]

                cell.configureForCommunityPost(
                    imageURL: item,
                    petProfiles: petProfile,
                    category: category
                )
                
                cell.rx.mediaDoubleTap
                    .filter { $0.state == .ended }
                    .observe(on: MainScheduler.instance)
                    .subscribe(onNext: { [weak collectionView] _ in
                        guard let collectionView else { return }
                        let footerIndex = IndexPath(item: 0, section: indexPath.section)
                        if let footer = collectionView.supplementaryView(
                            forElementKind: UICollectionView.elementKindSectionFooter,
                            at: footerIndex
                        ) as? PostFooterView {
                            footer.externalLikeEvent.accept(())
                        }
                    })
                    .disposed(by: cell.disposeBag)
                
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                // 섹션 모델 == CommunityModel
                let sectionModel = dataSource.sectionModels[indexPath.section].model
                
                switch kind {
                    // MARK: - PostHeader
                case UICollectionView.elementKindSectionHeader:
                    guard let header = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PostHeaderView.identifier,
                        for: indexPath
                    ) as? PostHeaderView else { return .init() }
                    
                    header.settingCell(data: sectionModel)
                    header.settingMenu(
                        menu: self.isWriter(sectionModel.userId)
                        ? self.myPostMenu(post: sectionModel)
                        : self.otherPostMenu(post: sectionModel)
                    )
                    
                    header.rx.profileTap
                        .observe(on: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] in
                            // TODO: 프로필 뷰로 이동
                            let authorUserId = sectionModel.userId
                            let userProfileViewComtroll = UserProfileViewController(userId: authorUserId)
                            userProfileViewComtroll.hidesBottomBarWhenPushed = true
                            self?.navigationController?.pushViewController(userProfileViewComtroll, animated: true)
                        })
                        .disposed(by: header.disposeBag)
                    
                    return header
                    
                    // MARK: - PostFooter
                case UICollectionView.elementKindSectionFooter:
                    guard let footer = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PostFooterView.identifier,
                        for: indexPath
                    ) as? PostFooterView else { return .init() }
                    
                    let count = dataSource.sectionModels[indexPath.section].items.count
                    let category: FirestoreCollection = {
                        let index = self.segmentedControl.selectedSegmentIndex
                        
                        return CommunitySectionType.allCases.indices.contains(index)
                        ? CommunitySectionType.allCases[index].toFirestoreCollection
                        : .invLogBoard
                    }()
                    
                    footer.settingCell(data: sectionModel, collection: category, isDetail: false)
                    footer.updatePage(total: count, current: 0)

                    // footerViewModel
                    let viewModel = PostFooterViewModel(category: category, post: sectionModel)
                    
                    footer.bind(viewModel: viewModel)

                    footer.rx.likeButtonTap
                        .map { sectionModel }
                        .bind(to: self.likeButtonEvent)
                        .disposed(by: footer.disposeBag)
                    
                    footer.rx.containerTap
                        .observe(on: MainScheduler.instance)
                        .subscribe(onNext: { [weak self] in
                            // TODO: 상세 뷰로 이동
                            let viewModel = PostDetailViewModel(post: sectionModel)
                            let viewController = PostDetailViewController(viewModel: viewModel)
                            viewController.hidesBottomBarWhenPushed = true
                            
                            self?.navigationController?.pushViewController(viewController, animated: true)
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
extension CommunityViewController {
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 16
        
        return UICollectionViewCompositionalLayout { row, env in
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
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
            
            // 푸터
            let footer = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                  heightDimension: .estimated(60)),
                elementKind: UICollectionView.elementKindSectionFooter,
                alignment: .bottom
            )
            
            // 섹션
            let section = NSCollectionLayoutSection(group: group)
            section.boundarySupplementaryItems = [header, footer]
            section.orthogonalScrollingBehavior = .groupPagingCentered
            section.interGroupSpacing = 0
            section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
            
            // 페이지 컨트롤 설정
            section.visibleItemsInvalidationHandler = { [weak self] item, offset, environment in
                guard let self else { return }
                let pageWidth = environment.container.contentSize.width
                let page = Int(round(offset.x / pageWidth))
                let indexPath = IndexPath(item: 0, section: row)
                let total = self.dataSource.sectionModels[row].items.count
                
                if let footerView = self.collectionView.supplementaryView(
                    forElementKind: UICollectionView.elementKindSectionFooter,
                    at: indexPath
                ) as? PostFooterView {
                    footerView.updatePage(total: total, current: page)
                }
            }
            
            return section
        }
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
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PostHeaderView.identifier)
        collectionView.register(PostFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: PostFooterView.identifier)
        collectionView.backgroundColor = .textInverse
        collectionView.refreshControl = refreshControl
        
        addButton.setImage(.postAdd, for: .normal)
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
