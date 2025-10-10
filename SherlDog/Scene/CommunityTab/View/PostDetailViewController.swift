//
//  PostDetailViewController.swift
//  SherlDog
//
//  Created by 최규현 on 9/30/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import FirebaseAuth

final class PostDetailViewController: UIViewController {
    
    private let likeButtonEvent = PublishRelay<CommunityModel>()
    private let menuEvent = PublishRelay<PostMenuEvent>()
    private let disposeBag = DisposeBag()
    
    private lazy var postDataSource = self.postCollectionViewDataSource()
    private lazy var commentDataSource = self.commentCollectionViewDataSource()
    
    
    // MARK: - UI property
    private lazy var postCollectionView = UICollectionView(frame: .zero, collectionViewLayout: postCollectionViewLayout())
    private lazy var commentCollectionView = UICollectionView(frame: .zero, collectionViewLayout: commentCollectionViewLayout())
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
    
    private func bind() {
        
    }
}

// MARK: - Cell Menu Button Setting
extension PostDetailViewController {
    private func isWriter(_ postUserId: String) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return postUserId == currentUserId
    }
    
    private func myPostMenu(post: CommunityModel) -> UIMenu {
        let fixAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                               SDLiteral.CommunityView.fix)) { [weak self] action in
            
            // TODO: fixAction
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
        
        let reportAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.report)) { [weak self] _ in
            self?.showMenuAlert(type: .report(post.documentId)) { [weak self] in
                self?.blockMessageAfterReport(userId: post.userId)
            }
        }
        
        return UIMenu(children: [blockAction, reportAction])
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


// MARK: - CollectionView DataSource
extension PostDetailViewController {
    private func postCollectionViewDataSource() -> RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.postDataSource> {
        return RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.postDataSource>(
            
            // MARK: - PostMediaCell
            configureCell: { dataSource, collectionView, indexPath, item in
                // item == String (이미지 URL)
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else { return .init() }
                let model = dataSource.sectionModels[indexPath.section].model
                
                cell.settingCell(item)
                cell.settingPetProfile(profile: model.petProfile)
                
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
                        let collection = FirestoreCollection.allCases.filter {
                            $0.rawValue == sectionModel.category
                        }.first
                        
                        return collection ?? .invLogBoard
                    }()
                    
                    footer.settingCell(data: sectionModel, collection: category)
                    footer.updatePage(total: count, current: 0)

                    // footerViewModel
                    let viewModel = PostFooterViewModel(category: category, post: sectionModel)
                    footer.bind(viewModel: viewModel)
                    
                    return footer
                    
                default:
                    return .init()
                }
            }
        )
    }
    
    private func commentCollectionViewDataSource() -> RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.commentDataSource> {
        return RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.commentDataSource>(
            configureCell: { dataSource, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCell.identifier, for: indexPath) as? CommentCell else { return .init() }
                
                return cell
            })
    }
}

// MARK: - CollectionView Layout
extension PostDetailViewController {
    private func postCollectionViewLayout() -> UICollectionViewCompositionalLayout {
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
                let total = self.postDataSource.sectionModels[row].items.count
                
                if let footerView = self.postCollectionView.supplementaryView(
                    forElementKind: UICollectionView.elementKindSectionFooter,
                    at: indexPath
                ) as? PostFooterView {
                    footerView.updatePage(total: total, current: page)
                }
            }
            
            return section
        }
    }
    
    private func commentCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { row, env in
            // FIXME: 레이아웃 설정
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                           heightDimension: .fractionalHeight(1)),
                                                         subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
    }
}

// MARK: - UI Setup
extension PostDetailViewController {
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        view.addSubviews([
            postCollectionView,
            commentCollectionView
        ])
        
        postCollectionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        postCollectionView.register(PostHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PostHeaderView.identifier)
        postCollectionView.register(PostFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: PostFooterView.identifier)
        
        commentCollectionView.register(CommentCell.self, forCellWithReuseIdentifier: CommentCell.identifier)
    }
    
    private func configureUI() {
        
    }
}
