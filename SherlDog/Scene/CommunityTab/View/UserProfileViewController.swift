//
//  UserProfileViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/3/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import FirebaseAuth
import Kingfisher

class UserProfileViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate {
    
    private let viewModel: UserProfileViewModel
    
    init(userId: String) {
        self.viewModel = UserProfileViewModel(userId: userId)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let disposeBag = DisposeBag()
    private let maxProfileCount = 3
    private let menuEvent = PublishRelay<PostMenuEvent>()
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let navigationMoreButton = UIButton()
    private let profileImageView = UIImageView()
    private let assistantNickNameLabel = UILabel()
    private let assistantNickNameField = UITextField()
    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let pageControl = UIPageControl()
    private let postCollectionButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        configureNavigationMenu()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    
    private func bind() {
        
        navigationBackButton.rx.tap
            .bind { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
        
        postCollectionButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                
                let userId = self.viewModel.userId
                let userPostVC = UserPostsViewController(userId: userId)
                self.navigationController?.pushViewController(userPostVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        viewModel.output.humanProfile
            .compactMap { $0 }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] humanProfile in
                guard let self = self else { return }
                self.assistantNickNameField.text = humanProfile.nickname
                
                if !humanProfile.image.isEmpty, let url = URL(string: humanProfile.image) {
                    self.loadImage(from: url)
                } else {
                    self.profileImageView.image = UIImage.petProfile
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.petProfiles
            .observe(on: MainScheduler.instance)
            .bind(to: collectionView.rx.items) { collectionView, index, profile in
                guard let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: DetectiveCardCell.identifier,
                    for: IndexPath(item: index, section: 0)
                ) as? DetectiveCardCell else {
                    return UICollectionViewCell()
                }
                cell.configure(with: profile)
                return cell
            }
            .disposed(by: disposeBag)
        
        // 펫프로필 갯수에 따른 인덱스닷 생성
        viewModel.output.petProfiles
            .map { $0.count }
            .bind(to: pageControl.rx.numberOfPages)
            .disposed(by: disposeBag)
        
        // 옆으로 얼만큼 스크롤 되어야 인덱스 닷이 넘어가는지에 대한 설정
        collectionView.rx.contentOffset
            .withLatestFrom(viewModel.output.petProfiles) { offset, profiles in
                let pageIndex = self.viewModel.calculatePageIndex(from: offset)
                // ProfileAdd 셀이 있어도 실제 프로필 개수 내에서만 계산
                return min(pageIndex, profiles.count - 1)
            }
            .filter { $0 >= 0 }
            .bind(to: pageControl.rx.currentPage)
            .disposed(by: disposeBag)
        
        // 인덱스닷 누르면 해당 순서의 카드로 넘어가는 스크롤 설정
        pageControl.rx.controlEvent(.valueChanged)
            .map { [weak self] in self?.pageControl.currentPage ?? 0 }
            .subscribe(onNext: { [weak self] pageIndex in
                guard let self = self else { return }
                let indexPath = IndexPath(item: pageIndex, section: 0)
                self.collectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: true
                )
            })
            .disposed(by: disposeBag)
        
        menuEvent
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                case .report(let userId):
                    let reportData = ReportModel(collection: self.viewModel.userId,
                                                 documentId: userId)
                    FirestoreManager.shared.createDocument(
                        collection: .reportLog,
                        data: reportData,
                        documentId: userId
                    )
                    .subscribe(onCompleted: { [weak self] in
                        self?.completeAlert(type: .report(SDLiteral.CommunityView.report)) {
                            self?.navigationController?.popViewController(animated: true)
                        }
                    }, onError: { error in
                        print("신고 실패: \(error)")
                    })
                    .disposed(by: self.disposeBag)
                    
                case .block(let userId):
                    BlockManager.shared.blockUser(userId)
                        .subscribe(onCompleted: { [weak self] in
                            self?.completeAlert(type: .block(SDLiteral.CommunityView.block)) {
                                self?.navigationController?.popViewController(animated: true)
                            }
                        }, onError: { error in
                            print("차단 실패: \(error)")
                        })
                        .disposed(by: self.disposeBag)
                    
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
    }
    
    private func loadImage(from url: URL) {
        let processor = DownsamplingImageProcessor(size: self.profileImageView.bounds.size) // 크기 지정 다운 샘플링
        
        self.profileImageView.kf.indicatorType = .activity
        KF.url(url)
            .placeholder(UIImage.petProfile)
            .setProcessor(processor)
            .cacheOriginalImage()
            .fade(duration: 0.25)
            .onFailureImage(UIImage.petProfile)
            .onSuccess { result in }
            .onFailure { error in }
            .set(to: self.profileImageView)
    }
    
    // 인덱스 닷 누르면 해당 순서의 멍카드 화면 중앙으로 이동
    private func scrollToItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        
        guard collectionView.numberOfItems(inSection: 0) > index else { return }
        
        collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    private func scrollToLastProfile() {
        let profileCount = viewModel.output.petProfiles.value.count
        if profileCount > 0 {
            let lastIndex = profileCount - 1
            let indexPath = IndexPath(item: lastIndex, section: 0)
            collectionView.scrollToItem(
                at: indexPath,
                at: .centeredHorizontally,
                animated: true
            )
            
            // 페이지 컨트롤도 업데이트
            pageControl.currentPage = lastIndex
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let collectionView = scrollView as? UICollectionView else { return }
        
        let cellWidth: CGFloat = 336
        let cellSpacing: CGFloat = 12
        let totalCellWidth = cellWidth + cellSpacing
        let leftInset = collectionView.contentInset.left
        
        let proposedOffsetX = targetContentOffset.pointee.x
        let index = round((proposedOffsetX + leftInset) / totalCellWidth)
        
        let maxIdx = max(0, collectionView.numberOfItems(inSection: 0) - 1)
        let targetIndex = Int(max(0, min(index, CGFloat(maxIdx))))
        
        DispatchQueue.main.async {
            let indexPath = IndexPath(item: targetIndex, section: 0)
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    //MARK: - UI
    private func setupUI() {
        [
            profileImageView,
            assistantNickNameLabel,
            assistantNickNameField,
            collectionView,
            pageControl,
            postCollectionButton
        ].forEach {
            view.addSubview($0)
        }
        
        view.backgroundColor = .keycolorBackground
        
        navigationBackButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationBackButtonImage), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.UserProfileViewController.navigationTitle
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        navigationMoreButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationMoreButtonImage), for: .normal)
        navigationMoreButton.imageView?.tintColor = .textPrimary
        navigationMoreButton.showsMenuAsPrimaryAction = true
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationMoreButton)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        profileImageView.image = UIImage(named: "petProfile")
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.backgroundColor = .keycolorBackground
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 66
        profileImageView.layer.masksToBounds = true
        
        assistantNickNameLabel.text = SDLiteral.UserProfileViewController.assistantNickNameLabel
        assistantNickNameLabel.font = .body1
        assistantNickNameLabel.textColor = .textPrimary
        
        assistantNickNameField.backgroundColor = .gray50
        assistantNickNameField.layer.cornerRadius = 6
        assistantNickNameField.leftView = UIView(frame: .init(x: 0, y: 0, width: 12, height: 0))
        assistantNickNameField.leftViewMode = .always
        assistantNickNameField.textColor = .textPrimary
        assistantNickNameField.isUserInteractionEnabled = false
        assistantNickNameField.tintColor = .clear
        
        layout.scrollDirection = .horizontal
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 336, height: 208)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 0
        
        collectionView.register(
            DetectiveCardCell.self,
            forCellWithReuseIdentifier: DetectiveCardCell.identifier)
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.backgroundColor = .keycolorBackground
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .keycolorPrimary5
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary2
        
        postCollectionButton.setTitle(SDLiteral.UserProfileViewController.postCollectionButtonTitle, for: .normal)
        postCollectionButton.titleLabel?.font = .body3
        postCollectionButton.setTitleColor(.textPrimary, for: .normal)
        postCollectionButton.setTitleColor(.textPrimary, for: .highlighted)
        postCollectionButton.backgroundColor = .gray100
        postCollectionButton.setImage(UIImage(named: SDLiteral.UserProfileViewController.postCollectionButtonImage), for: .normal)
        postCollectionButton.contentHorizontalAlignment = .left
        postCollectionButton.setContentInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        postCollectionButton.layer.cornerRadius = 12
        postCollectionButton.clipsToBounds = true
    }
    
    private func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.height.width.equalTo(132)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8)
            $0.centerX.equalToSuperview()
        }
        
        assistantNickNameLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
        }
        
        assistantNickNameField.snp.makeConstraints {
            $0.height.equalTo(46)
            $0.top.equalTo(assistantNickNameLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(assistantNickNameField.snp.bottom).offset(16)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(0)
            $0.height.equalTo(240)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
        }
        
        postCollectionButton.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(64)
        }
    }
    
}

// MARK: - 메뉴 설정 & Alert
extension UserProfileViewController {
    /// 내 프로필인지 확인
    private func isMyProfile() -> Bool {
        guard let currentUserId = Auth.auth().currentUser?.uid else { return false }
        return currentUserId == viewModel.userId
    }
    
    private func configureNavigationMenu() {
        if isMyProfile() {
            navigationItem.rightBarButtonItem = nil
        } else {
            navigationMoreButton.menu = UIMenu(children: [
                UIAction(title: "차단하기") { [weak self] _ in
                    guard let self = self else { return }
                    self.showMenuAlert(type: .block(self.viewModel.userId))
                },
                UIAction(title: "신고하기") { [weak self] _ in
                    guard let self = self else { return }
                    self.showMenuAlert(type: .report(self.viewModel.userId)) { [weak self] in
                        self?.blockMessageAfterReport(userId: self?.viewModel.userId ?? "")
                    }
                }
            ])
        }
    }
    
    private func showMenuAlert(type: PostMenuEvent, completion: (() -> ())? = nil) {
        switch type {
        case .block, .report:
            break // 계속 진행
        default:
            return // 다른 케이스면 리턴
        }
        
        let title: String = {
            switch type {
            case .block: return SDLiteral.CommunityView.block
            case .report: return SDLiteral.CommunityView.report
            default: return ""
            }
        }()
        
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.menuAlertMessage, title),
            buttons: [
                .init(title: SDLiteral.AlertMessage.cancel, action: nil),
                .init(title: title, action: { [weak self] in
                    self?.menuEvent.accept(type)
                    completion?()
                })
            ]
        )
        present(alert, animated: true)
    }
    
    private func blockMessageAfterReport(userId: String) {
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.completeAlert, SDLiteral.CommunityView.report),
            subMessage: SDLiteral.CommunityView.blockMessageAfterReport,
            buttons: [
                .init(title: SDLiteral.AlertMessage.cancel, action: nil),
                .init(title: SDLiteral.CommunityView.block, action: { [weak self] in
                    guard let self = self else { return }
                    self.menuEvent.accept(.block(userId))
                })
            ]
        )
        present(alert, animated: true)
    }
    
    private func completeAlert(type: PostMenuEvent, completion: (() -> Void)? = nil) {
        let message: String = {
            switch type {
            case .block: return SDLiteral.CommunityView.block
            case .report: return SDLiteral.CommunityView.report
            default: return ""
            }
        }()
        
        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.completeAlert, message),
            buttons: [
                .init(title: SDLiteral.AlertMessage.cancel, action: completion)
            ]
        )
        present(alert, animated: true)
    }
}
