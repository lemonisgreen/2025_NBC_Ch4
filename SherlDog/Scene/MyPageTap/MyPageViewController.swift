//
//  MyPageViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import FirebaseAuth

class MyPageViewController : UIViewController {
    private let viewModel = MyPageViewModel()
    private let disposeBag = DisposeBag()
    private let maxProfileCount = 3
    
    let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let pageControl = UIPageControl()
    let mypageLabel = UILabel()
    let mypageSettingButton = UIButton()
    let assistantImage = UIImageView()
    let assistantLabel = UILabel()
    let assistantButton = UIButton()
    let archiveButton = UIButton()
    let findMateButton = UIButton()
    let buttonStack = UIStackView()
    
    // 멍탐정 카드 collectionItem
    enum CollectionViewItem {
        case profile(PetProfile)
        case addProfile
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .keycolorInverse
        setupUI()
        configureUI()
        bind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refresh()
        viewModel.refreshHumanProfile()
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topLine = CALayer()
        topLine.backgroundColor = UIColor(named: "gray200")?.cgColor
        topLine.frame = CGRect(x: 0, y: 0, width: findMateButton.bounds.width, height: 1)
        findMateButton.layer.addSublayer(topLine)
    }
    
    private func setupUI() {
        [
            mypageLabel,
            assistantImage,
            assistantLabel,
            assistantButton,
            collectionView,
            pageControl,
            archiveButton,
            findMateButton,
            buttonStack,
            mypageSettingButton
        ].forEach {
            view.addSubview($0)
        }
        mypageLabel.text = "멍탐정 사무소"
        mypageLabel.font = .highlight3
        mypageLabel.textColor = .textPrimary
        
        mypageSettingButton.setImage(UIImage(named: "setting"), for: .normal)
        
        assistantImage.backgroundColor = .keycolorPrimary4
        assistantImage.layer.cornerRadius = 8
        assistantImage.layer.masksToBounds = true
        
        assistantLabel.font = .title3
        assistantLabel.textColor = .textPrimary
        
        assistantButton.setTitle("편집", for: .normal)
        assistantButton.setTitleColor(.keycolorPrimary3, for: .normal)
        assistantButton.titleLabel?.font = .body3
        
        layout.scrollDirection = .horizontal
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 336, height: 208)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 0
        
        collectionView.register(
            DetectiveCardCell.self,
            forCellWithReuseIdentifier: DetectiveCardCell.identifier)
        collectionView.register(
            ProfileAddCollectionViewCell.self,
            forCellWithReuseIdentifier: ProfileAddCollectionViewCell.identifier)
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.backgroundColor = .keycolorInverse
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .keycolorPrimary5
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary2
        
        buttonStack.axis = .vertical
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 0
        buttonStack.addArrangedSubview(archiveButton)
        //buttonStack.addArrangedSubview(findMateButton)
        
        archiveButton.setTitle("수사일지 아카이브", for: .normal)
        archiveButton.titleLabel?.font = .body3
        archiveButton.setTitleColor(.textPrimary, for: .normal)
        archiveButton.backgroundColor = .gray100
        archiveButton.setImage(UIImage(named: "note"), for: .normal)
        archiveButton.contentHorizontalAlignment = .left
        archiveButton.setContentInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        archiveButton.layer.cornerRadius = 12
        //archiveButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        archiveButton.clipsToBounds = true
        archiveButton.setTitleInsets(.init(top: 0, left: 8, bottom: 0, right: -8))
        
        findMateButton.setTitle("탐정메이트 찾기", for: .normal)
        findMateButton.titleLabel?.font = .body3
        findMateButton.setTitleColor(.textPrimary, for: .normal)
        findMateButton.backgroundColor = .gray100
        findMateButton.setImage(UIImage(named: "search"), for: .normal)
        findMateButton.contentHorizontalAlignment = .left
        findMateButton.setContentInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        findMateButton.layer.cornerRadius = 12
        findMateButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        findMateButton.clipsToBounds = true
        findMateButton.setTitleInsets(.init(top: 0, left: 8, bottom: 0, right: -8))
    }
    
    private func configureUI() {
        mypageLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(70)
            $0.leading.equalToSuperview().inset(16)
        }
        
        mypageSettingButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(55)
            $0.trailing.equalToSuperview().inset(5)
            $0.width.height.equalTo(56)
        }
        
        assistantImage.snp.makeConstraints {
            $0.top.equalTo(mypageLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(16)
            $0.height.width.equalTo(40)
        }
        
        assistantLabel.snp.makeConstraints {
            $0.top.equalTo(mypageLabel.snp.bottom).offset(34)
            $0.leading.equalTo(assistantImage.snp.trailing).offset(12)
        }
        
        assistantButton.snp.makeConstraints {
            $0.top.equalTo(mypageLabel.snp.bottom).offset(24)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(assistantImage.snp.bottom).offset(24)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(0)
            $0.height.equalTo(250)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
        }
        
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(60)
        }
    }
    
    private func bind() {
        archiveButton.rx.tap
            .bind(onNext: { [weak self] in
                guard let self else { return }
                
                let archiveView = InvLogListViewController()
                self.navigationController?.pushViewController(archiveView, animated: true)
            })
            .disposed(by: disposeBag)
        
        mypageSettingButton.rx.tap
            .bind { [weak self] in
                let settingVC = SettingViewController()
                self?.navigationController?.pushViewController(settingVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        viewModel.output.humanProfile
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] humanProfile in
                DispatchQueue.main.async {
                    self?.assistantLabel.text = humanProfile.nickname
                    
                    if !humanProfile.image.isEmpty, let url = URL(string: humanProfile.image) {
                        self?.loadImage(from: url)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        assistantButton.rx.tap
            .withLatestFrom(viewModel.output.humanProfile)
        
            .bind { [weak self] humanProfile in
                guard let self = self else { return }
                let createAssistantVC = CreateAssistantProfileViewController()
                if let profile = humanProfile {
                    createAssistantVC.configure(with: profile)
                }
                self.navigationController?.pushViewController(createAssistantVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        viewModel.output.petProfiles
            .map { [weak self] profiles -> [CollectionViewItem] in
                guard let self = self else { return [] }
                
                var items: [CollectionViewItem] = profiles.map { .profile($0) }
                
                if profiles.count < self.maxProfileCount {
                    items.append(.addProfile)
                }
                return items
            }
            .bind(to: collectionView.rx.items) { collectionView, index, item in
                switch item {
                case .profile(let profile):
                    if let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: DetectiveCardCell.identifier,
                        for: IndexPath(item: index, section: 0)
                    ) as? DetectiveCardCell {
                        cell.configure(with: profile)
                        return cell
                    } else {
                        return UICollectionViewCell()
                    }
                    
                case .addProfile:
                    let cell = collectionView.dequeueReusableCell(
                        withReuseIdentifier: ProfileAddCollectionViewCell.identifier,
                        for: IndexPath(item: index, section: 0)
                    ) as! ProfileAddCollectionViewCell
                    return cell
                }
            }
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .withLatestFrom(viewModel.output.petProfiles) { indexPath, profiles -> CollectionViewItem? in
                var items: [CollectionViewItem] = profiles.map { .profile($0) }
                if profiles.count < self.maxProfileCount {
                    items.append(.addProfile)
                }
                
                guard indexPath.item < items.count else { return nil }
                return items[indexPath.item]
            }
            .compactMap { $0 }
            .subscribe(onNext: { [weak self] item in
                switch item {
                case .profile(let profile):
                    self?.presentRegistrationViewController(with: profile)
                        .subscribe(onNext: { _ in
                        })
                        .disposed(by: self?.disposeBag ?? DisposeBag())
                case .addProfile:
                    self?.presentRegistrationView()
                }
                
                // 선택 해제
                if let selectedIndexPath = self?.collectionView.indexPathsForSelectedItems?.first {
                    self?.collectionView.deselectItem(at: selectedIndexPath, animated: true)
                }
            })
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
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.assistantImage.image = image
                }
            }
        }
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
    
    private func presentRegistrationView() {
        let registrationVC = RegistrationViewController()
        
        registrationVC.onProfileAdded = { [weak self] newProfileID in
            self?.viewModel.handleNewProfileAdded(with: newProfileID)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.scrollToLastProfile()
            }
        }
        
        if let sheet = registrationVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
        }
        registrationVC.isModalInPresentation = true
        
        present(registrationVC, animated: true)
    }
    
    private func presentRegistrationViewController(with profile: PetProfile) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            guard let self = self else {
                observer.onCompleted()
                return Disposables.create()
            }
            
            let registrationVC = RegistrationViewController()
            registrationVC.configure(for: .edit(profile), with: profile)
            
            // 수정 완료 시 데이터 새로고침을 위한 Observable 구독
            registrationVC.profileUpdateSubject
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.viewModel.profileDidUpdate()
                    observer.onNext(())
                    observer.onCompleted()
                })
                .disposed(by: registrationVC.disposeBag)
            
            if let sheet = registrationVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.selectedDetentIdentifier = .large
                sheet.prefersGrabberVisible = false
                sheet.preferredCornerRadius = 20
            }
            registrationVC.isModalInPresentation = true
            
            self.present(registrationVC, animated: true)
            
            return Disposables.create()
        }
    }
}
extension UIButton {
    
    private func applyEdgeInsets( // 내부적으로 contentInsets 와 titleEdgeInsets 를 설정하는 함수
        content: NSDirectionalEdgeInsets? = nil,
        title: UIEdgeInsets? = nil
    ) {
        if #available(iOS 15.0, *) {
            if let content = content {
                var config = self.configuration ?? .plain()
                config.contentInsets = content
                self.configuration = config
            }
            // iOS15 이상에서는 titleEdgeInsets는 의미 없음
        } else {
            if let content = content {
                self.contentEdgeInsets = UIEdgeInsets(
                    top: content.top,
                    left: content.leading,
                    bottom: content.bottom,
                    right: content.trailing
                )
            }
            if let title = title {
                self.titleEdgeInsets = title
            }
        }
    }
    
    func setContentInsets(_ insets: NSDirectionalEdgeInsets) {
        applyEdgeInsets(content: insets, title: nil)
    }
    
    func setTitleInsets(_ insets: UIEdgeInsets) {
        applyEdgeInsets(content: nil, title: insets)
    }
}
