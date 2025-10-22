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

final class PostDetailViewController: UIViewController {
    
    private let viewModel: PostDetailViewModel
    private let likeButtonEvent = PublishRelay<Void>()
    private let commentEvent = PublishRelay<CommentEvent>()
    private let menuEvent = PublishRelay<PostMenuEvent>()
    private let disposeBag = DisposeBag()
    
    private lazy var postDataSource = self.postCollectionViewDataSource()
    private lazy var commentDataSource = self.commentCollectionViewDataSource()
    
    
    // MARK: - UI property
    private let refreshControl = UIRefreshControl()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private lazy var postCollectionView = UICollectionView(frame: .zero, collectionViewLayout: postCollectionViewLayout())
    private lazy var commentCollectionView = UICollectionView(frame: .zero, collectionViewLayout: commentCollectionViewLayout())
//    private let collectionViewStackView = UIStackView()
    private let commentTextField = UITextField()
    private let saveButton = UIButton()
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
                
                return CommentEvent.create(text)
            }
            .bind(to: self.commentEvent)
            .disposed(by: disposeBag)
        
        // MARK: - Output
        let output = self.viewModel.transform(input)
        
        output.postData
            .drive(self.postCollectionView.rx.items(dataSource: self.postDataSource))
            .disposed(by: disposeBag)
        
        output.commentData
            .drive(self.commentCollectionView.rx.items(dataSource: self.commentDataSource))
            .disposed(by: disposeBag)
        
        output.isUpdating
            .drive(self.refreshControl.rx.isRefreshing)
            .disposed(by: disposeBag)
    }
}

extension PostDetailViewController {
    private func isWriter(_ postUserId: String) -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return postUserId == currentUserId
    }
    
    // MARK: - Post Menu Button Setting
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
    
    private func myCommentMenu(comment: CommentModel) -> UIMenu {
        let fixAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                               SDLiteral.CommunityView.fix)) { [weak self] action in
            
            // TODO: fixAction
        }
        
        let deleteAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.delete)) { [weak self] _ in
            self?.showMenuAlert(type: .delete(comment.documentId))
        }
        
        return UIMenu(children: [fixAction, deleteAction])
    }
    
    private func otherCommentMenu(comment: CommentModel) -> UIMenu {
        let blockAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                 SDLiteral.CommunityView.block)) { [weak self] _ in
            self?.showMenuAlert(type: .block(comment.userId))
        }
        
        let reportAction = UIAction(title: String(format: SDLiteral.CommunityView.menuButtonTitle,
                                                  SDLiteral.CommunityView.report)) { [weak self] _ in
            self?.showMenuAlert(type: .report(comment.documentId)) { [weak self] in
                self?.blockMessageAfterReport(userId: comment.userId)
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
    private func postCollectionViewDataSource() -> RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.PostDataSource> {
        return RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.PostDataSource>(
            
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
    
    private func commentCollectionViewDataSource() -> RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.CommentDataSource> {
        return RxCollectionViewSectionedReloadDataSource<PostDetailViewModel.CommentDataSource>(
            configureCell: { dataSource, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommentCell.identifier, for: indexPath) as? CommentCell else { return .init() }
                
                cell.settingCell(data: item)
                cell.settingMenu(
                    menu: self.isWriter(item.userId)
                    ? self.myCommentMenu(comment: item)
                    : self.otherCommentMenu(comment: item)
                )
                
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
            let inset: CGFloat = 16
            
            // FIXME: 레이아웃 설정
            let item = NSCollectionLayoutItem(
                layoutSize: .init(widthDimension: .fractionalWidth(1),
                                  heightDimension: .fractionalHeight(1))
            )
            
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: .init(widthDimension: .fractionalWidth(1),
                                  heightDimension: .estimated(80)),
                subitems: [item]
            )
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
            section.interGroupSpacing = 0
            
            return section
        }
    }
}

// MARK: - UI Setup
extension PostDetailViewController {
    private func setupUI() {
        view.backgroundColor = .keycolorInverse
        
//        [
//            postCollectionView,
//            commentCollectionView
//        ].forEach { collectionViewStackView.addArrangedSubview($0) }
        
        [
            commentTextField,
            saveButton
        ].forEach { commentStackView.addArrangedSubview($0) }
        
        contentView.addSubviews([
            postCollectionView,
            commentCollectionView,
//            collectionViewStackView
        ])
        
        scrollView.addSubview(contentView)
        view.addSubviews([
            scrollView,
            commentStackView
        ])
        
        scrollView.refreshControl = refreshControl
        
//        collectionViewStackView.axis = .vertical
//        collectionViewStackView.spacing = 4
//        collectionViewStackView.alignment = .top
        
        postCollectionView.backgroundColor = .keycolorInverse
        postCollectionView.register(MediaCell.self, forCellWithReuseIdentifier: MediaCell.identifier)
        postCollectionView.register(PostHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: PostHeaderView.identifier)
        postCollectionView.register(PostFooterView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: PostFooterView.identifier)
        
        commentCollectionView.backgroundColor = .keycolorInverse
        commentCollectionView.register(CommentCell.self, forCellWithReuseIdentifier: CommentCell.identifier)
        
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
        commentTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        saveButton.setTitle(SDLiteral.PostDetailViewController.commentSaveButtonTitle,
                            for: .normal)
        saveButton.setTitleColor(.keycolorPrimary1, for: .normal)
        saveButton.titleLabel?.font = .body4
    }
    
    private func configureUI() {
        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(commentStackView.snp.top).offset(-12)
        }
        
        contentView.snp.makeConstraints {
            $0.edges.width.equalToSuperview()
        }
        
//        collectionViewStackView.snp.makeConstraints {
//            $0.top.leading.trailing.bottom.equalToSuperview()
//        }
        
        postCollectionView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.height.equalTo(500)
        }
        
        commentCollectionView.snp.makeConstraints {
            $0.height.equalTo(300)
            $0.top.equalTo(postCollectionView.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
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
