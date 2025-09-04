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
    
    private let viewModel = MyPageViewModel()
    private let disposeBag = DisposeBag()
    private let maxProfileCount = 3
    
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
        view.backgroundColor = .keycolorBackground
        bind()
        setupUI()
        configureUI()
    }
    
    private func bind() {
        
        viewModel.output.humanProfile
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] humanProfile in
                DispatchQueue.main.async {
                    self?.assistantNickNameField.text = humanProfile.nickname
                    
                    if !humanProfile.image.isEmpty, let url = URL(string: humanProfile.image) {
                        self?.loadImage(from: url)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.petProfiles
            .bind(to: collectionView.rx.items) { collectionView, index, profile in
                if let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: DetectiveCardCell.identifier,
                    for: IndexPath(item: index, section: 0)
                ) as? DetectiveCardCell {
                    cell.configure(with: profile)
                    return cell
                } else {
                    return UICollectionViewCell()
                }
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
        
        navigationBackButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationBackButtonImage), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.UserProfileViewController.navigationTitle
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        navigationMoreButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationMoreButtonImage), for: .normal)
        navigationMoreButton.imageView?.tintColor = .textPrimary
        
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
        
        profileImageView.backgroundColor = .clear
        profileImageView.contentMode = .scaleAspectFit
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
        collectionView.delegate = self

        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .keycolorPrimary5
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary2
        
        postCollectionButton.setTitle(SDLiteral.UserProfileViewController.postCollectionButtonTitle, for: .normal)
        postCollectionButton.titleLabel?.font = .body3
        postCollectionButton.setTitleColor(.textPrimary, for: .normal)
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
