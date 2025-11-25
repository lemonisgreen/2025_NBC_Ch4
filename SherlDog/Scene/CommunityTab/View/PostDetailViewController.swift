//
//  PostDetailViewController.swift
//  SherlDog
//
//  Created by 최규현 on 9/30/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources
import FirebaseAuth

enum MenuType {
    case post(PostMenuEvent)
    case comment(CommentEvent)
}

final class PostDetailViewController: UIViewController {
    
    private let viewModel: PostDetailViewModel
    private let likeButtonEvent = PublishRelay<Void>()
    private let commentEvent = PublishRelay<CommentEvent>()
    private let menuEvent = PublishRelay<PostMenuEvent>()
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = self.postCollectionViewDataSource()
    
    // MARK: - UI property
    private let refreshControl = UIRefreshControl()
    private lazy var postDetailCollectionView = UICollectionView(frame: .zero, collectionViewLayout: postDetailCollectionViewLayout())
    private let commentTextField = UITextField()
    private let saveButton = UIButton()
    private let isSecretToggleButton = UIButton()
    private let commentStackView = UIStackView()
    
    // MARK: - Lifecycle
    init(viewModel: PostDetailViewModel) {
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // 최초 데이터 불러오기
        refreshControl.sendActions(for: .valueChanged)
    }
}

// MARK: - bind
extension PostDetailViewController {
    private func bind() {
        // MARK: - Input
        let input = PostDetailViewModel.Input(
            refreshPost: self.refreshControl.rx.controlEvent(.valueChanged).asObservable(),
            likeEvent: self.likeButtonEvent.asObservable(),
            commentEvent: self.commentEvent.asObservable(),
            postMenuEvent: self.menuEvent.asObservable()
        )
        
        self.saveButton.rx.tap
            .map { [weak self] in
                let text = self?.commentTextField.text ?? ""
                self?.commentTextField.text = ""
                
                return CommentEvent.create(content: text, isSecret: self?.isSecretToggleButton.isSelected ?? false)
            }
            .bind(to: self.commentEvent)
            .disposed(by: disposeBag)
        
        self.isSecretToggleButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.isSecretToggleButton.isSelected.toggle()
            })
            .disposed(by: disposeBag)
        
        // MARK: - Output
        let output = self.viewModel.transform(input)
        
        output.postDetailData
            .drive(self.postDetailCollectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)
        
        output.isUpdating
            .drive(self.refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
    }
}

extension PostDetailViewController {
    // MARK: - Post Menu Button Setting
    private func myPostMenu(post: CommunityModel) -> UIMenu {
        let fixAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                               SDLiteral.CommunityView.fix)) { [weak self] action in
            let category: CommunitySectionType = {
                CommunitySectionType.allCases.filter({ $0.name == post.category }).first ?? .invLogBoard
            }()
            
            let editView = AddNewContentViewController(category: category, post: post)
            editView.hidesBottomBarWhenPushed = true
            self?.navigationController?.pushViewController(editView, animated: true)
        }
        
        let deleteAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.delete)) { [weak self] _ in
            self?.showMenuAlert(type: .post(.delete(post.documentId)))
        }
        
        return UIMenu(children: [fixAction, deleteAction])
    }
    
    private func otherPostMenu(post: CommunityModel) -> UIMenu {
        let blockAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                 SDLiteral.CommunityView.block)) { [weak self] _ in
            self?.showMenuAlert(type: .post(.block(post.userId)))
        }
        
        let reportAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.report)) { [weak self] _ in
            self?.showMenuAlert(type: .post(.report(post.documentId))) { [weak self] in
                self?.blockMessageAfterReport(userId: post.userId)
            }
        }
        
        return UIMenu(children: [blockAction, reportAction])
    }
    
    private func myCommentMenu(comment: CommentModel, indexPath: IndexPath) -> UIMenu {
        let fixAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                               SDLiteral.CommunityView.fix)) { [weak self] action in
            guard let cell = self?.postDetailCollectionView.cellForItem(at: indexPath) as? CommentCell else { return }
            cell.setFixMode(isFixMode: true)
            cell.contentLabel.becomeFirstResponder()
            
            // TODO: fixAction
        }
        
        let deleteAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.delete)) { [weak self] _ in
            self?.showMenuAlert(type: .comment(.delete(comment.documentId)))
        }
        
        return UIMenu(children: [fixAction, deleteAction])
    }
    
    private func otherCommentMenu(comment: CommentModel) -> UIMenu {
        let blockAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                 SDLiteral.CommunityView.block)) { [weak self] _ in
            self?.showMenuAlert(type: .comment(.block(comment.userId)))
        }
        
        let reportAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.report)) { [weak self] _ in
            self?.showMenuAlert(type: .comment(.report(comment.documentId))) { [weak self] in
                self?.blockMessageAfterReport(userId: comment.userId)
            }
        }
        
        return UIMenu(children: [blockAction, reportAction])
    }
    
    private func showMenuAlert(type: MenuType, completion: (() -> ())? = nil) {
        switch type {
        case .post(let event):
            showPostMenuAlert(type: event, completion: completion)
        case .comment(let event):
            showCommentMenuAlert(type: event, completion: completion)
        }
    }
    
    private func showCommentMenuAlert(type: CommentEvent, completion: (() -> ())? = nil) {
        switch type {
        case .fix, .error:
            return
        default:
            break
        }
        
        var title: String {
            switch type {
            case .delete: return SDLiteral.CommunityView.delete
            case .report: return SDLiteral.CommunityView.report
            case .block: return  SDLiteral.CommunityView.block
            default: return ""
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
                        self?.commentEvent.accept(type)
                        completion?()
                    }
                )
            ]
        )
        
        self.present(alert, animated: true)
    }
    private func showPostMenuAlert(type: PostMenuEvent, completion: (() -> ())? = nil) {
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
    private func postCollectionViewDataSource()
    -> RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.PostDetailSectionModel> {
        return .init(
            // MARK: - PostMediaCell
            configureCell: { dataSource, collectionView, indexPath, item in
                // item == String (이미지 URL)
                switch item {
                case .post(let imageUrl):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MediaCell.identifier, for: indexPath) as? MediaCell else { return .init() }
                    let model = dataSource.sectionModels[indexPath.section].model
                    
                    cell.settingCell(imageUrl)
                    
                    switch model {
                    case .post(let post):
                        cell.settingPetProfile(profile: post.petProfile)
                        
                    default:
                        return .init()
                    }
                    
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
                    
                case .comment(let comment):
                    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCell.identifier, for: indexPath) as? CommentCell else { return .init() }
                    
                    cell.settingCell(
                        data: comment,
                        canOpen: comment.isSecret
                        ? self.viewModel.isPosterOrCommenter(commentUserId: comment.userId)
                        : true
                    )
                    
                    cell.settingMenu(
                        menu: self.viewModel.isWriter(comment.userId)
                        ? self.myCommentMenu(comment: comment, indexPath: indexPath)
                        : self.otherCommentMenu(comment: comment)
                    )
                    
                    cell.rx.saveButtonTap
                        .bind(onNext: { [weak self] in
                            cell.setFixMode(isFixMode: false)
                            self?.commentEvent.accept(.fix(documentId: comment.documentId, content: cell.contentLabel.text ?? ""))
                        })
                        .disposed(by: cell.disposeBag)
                    
                    cell.rx.cancelButtonTap
                        .bind(onNext: {
                            cell.setFixMode(isFixMode: false)
                        })
                        .disposed(by: cell.disposeBag)
                    
                    return cell
                }
            }, configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                // 섹션 모델 == CommunityModel
                let sectionModel = dataSource.sectionModels[indexPath.section].model
                
                switch sectionModel {
                case .post(let post):
                    switch kind {
                        // MARK: - PostHeader
                    case UICollectionView.elementKindSectionHeader:
                        guard let header = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: PostHeaderView.identifier,
                            for: indexPath
                        ) as? PostHeaderView else { return .init() }
                        
                        header.settingCell(data: post)
                        header.settingMenu(
                            menu: self.viewModel.isWriter(post.userId)
                            ? self.myPostMenu(post: post)
                            : self.otherPostMenu(post: post)
                        )
                        
                        header.rx.profileTap
                            .observe(on: MainScheduler.instance)
                            .subscribe(onNext: { [weak self] in
                                // TODO: 프로필 뷰로 이동
                                let authorUserId = post.userId
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
                                $0.rawValue == post.category
                            }.first
                            
                            return collection ?? .invLogBoard
                        }()
                        
                        footer.settingCell(data: post, collection: category, isDetail: true)
                        footer.updatePage(total: count, current: 0)
                        
                        // footerViewModel
                        let viewModel = PostFooterViewModel(category: category, post: post)
                        footer.bind(viewModel: viewModel)
                        
                        return footer
                        
                    default:
                        return .init()
                    }
                    
                case .comment(let title):
                    switch kind {
                    case UICollectionView.elementKindSectionHeader:
                        guard let header = collectionView.dequeueReusableSupplementaryView(
                            ofKind: kind,
                            withReuseIdentifier: CommentHeaderView.identifier,
                            for: indexPath
                        ) as? CommentHeaderView else { return .init() }
                        
                        header.setTitle(title: title)
                        
                        return header
                    default:
                        return .init()
                    }
                }
                
            }
        )
    }
}

// MARK: - CollectionView Layout
extension PostDetailViewController {
    private func postDetailCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 16
        
        return UICollectionViewCompositionalLayout { sectionIndex, env in
            switch sectionIndex {
            case 0: // 포스트 섹션
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
                    let indexPath = IndexPath(item: 0, section: sectionIndex)
                    let total = self.dataSource.sectionModels[sectionIndex].items.count
                    
                    if let footerView = self.postDetailCollectionView.supplementaryView(
                        forElementKind: UICollectionView.elementKindSectionFooter,
                        at: indexPath
                    ) as? PostFooterView {
                        footerView.updatePage(total: total, current: page)
                    }
                }
                
                return section
                
            case 1: // 댓글 섹션
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1),
                                      heightDimension: .fractionalHeight(1))
                )
                
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1),
                                      heightDimension: .estimated(80)),
                    subitems: [item]
                )
                
                let header = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(60)),
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
                section.interGroupSpacing = 30
                section.boundarySupplementaryItems = [header]
                
                return section
            default:
                return nil
            }
        }
    }
}

// MARK: - UI Setup
extension PostDetailViewController {
    private func setupUI() {
        view.backgroundColor = .keycolorInverse
        
        [
            commentTextField,
            saveButton
        ].forEach { commentStackView.addArrangedSubview($0) }
        
        view.addSubviews([
            postDetailCollectionView,
            commentStackView
        ])
        
        postDetailCollectionView.refreshControl = refreshControl
        postDetailCollectionView.backgroundColor = .keycolorInverse
        postDetailCollectionView.register(MediaCell.self,
                                          forCellWithReuseIdentifier: MediaCell.identifier)
        postDetailCollectionView.register(PostHeaderView.self,
                                          forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                          withReuseIdentifier: PostHeaderView.identifier)
        postDetailCollectionView.register(PostFooterView.self,
                                          forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                          withReuseIdentifier: PostFooterView.identifier)
        
        postDetailCollectionView.register(CommentHeaderView.self,
                                          forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                          withReuseIdentifier: CommentHeaderView.identifier)
        postDetailCollectionView.register(CommentCell.self,
                                          forCellWithReuseIdentifier: CommentCell.identifier)
        
        commentStackView.axis = .horizontal
        commentStackView.spacing = 8
        commentStackView.alignment = .fill
        
        commentTextField.placeholder = SDLiteral.PostDetailViewController.commentTextFieldPlaceholder
        commentTextField.font = .body5
        commentTextField.textColor = .textPrimary
        commentTextField.layer.borderColor = UIColor.gray800.cgColor
        commentTextField.layer.borderWidth = 1
        commentTextField.layer.cornerRadius = 8
        commentTextField.leftView = UIView(frame: .init(x: 0, y: 0, width: 8, height: 0))
        commentTextField.leftViewMode = .always
        commentTextField.rightView = self.isSecretToggleButton
        commentTextField.rightViewMode = .always
        // 설정 값이 낮을수록 우선적으로 늘려짐 -> 늘려지도록(버튼사이즈를 설정 후 남은 부분에 늘려져 빈 공간을 채우도록)
        commentTextField.setContentHuggingPriority(.init(0), for: .horizontal)
        
        saveButton.setTitle(SDLiteral.PostDetailViewController.commentSaveButtonTitle,
                            for: .normal)
        saveButton.setTitleColor(.keycolorPrimary1, for: .normal)
        saveButton.titleLabel?.font = .body4
        // 설정 값이 낮을수록 우선적으로 줄여짐 -> 줄여지지 않도록(텍스트필드가 늘려져도 버튼이 줄여지지 않도록)
        saveButton.setContentCompressionResistancePriority(.init(1000), for: .horizontal)
        
        isSecretToggleButton.setImage(UIImage(systemName: "lock.open"), for: .normal)
        isSecretToggleButton.setImage(UIImage(systemName: "lock"), for: .selected)
        var config = UIButton.Configuration.plain()
        config.buttonSize = .mini
        config.baseBackgroundColor = .clear
        isSecretToggleButton.configuration = config
    }
    
    private func configureUI() {
        postDetailCollectionView.snp.makeConstraints {
            $0.top.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(commentStackView.snp.top).offset(-12)
        }
        
        commentStackView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        
        commentTextField.snp.makeConstraints {
            $0.height.equalTo(38)
        }
    }
}
