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
    private let petProfilesSubject = PublishSubject<[PetProfile]>()
    private var petProfiles: [PetProfile] = []
    private let disposeBag = DisposeBag()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        bind()
        fetchUserPetProfiles()
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
            mypageSettingButton,
            assistantImage,
            assistantLabel,
            assistantButton,
            collectionView,
            pageControl,
            archiveButton,
            findMateButton,
            buttonStack,
        ].forEach {
            view.addSubview($0)
        }
        mypageLabel.text = "멍탐정 사무소"
        mypageLabel.font = .highlight3
        mypageLabel.textColor = .textPrimary
        
        mypageSettingButton.setImage(UIImage(named: "setting"), for: .normal)
        
        assistantImage.image = UIImage(named: "mypageSample")
        
        assistantLabel.text = "똥봉투 조수"
        assistantLabel.font = .body5
        assistantLabel.textColor = .textPrimary
        
        assistantButton.setTitle("편집", for: .normal)
        assistantButton.setTitleColor(.keycolorPrimary3, for: .normal)
        assistantButton.titleLabel?.font = .alert2
        
        layout.scrollDirection = .horizontal
        
        collectionView.register(
            DetectiveCardCell.self,
            forCellWithReuseIdentifier: DetectiveCardCell.identifier)
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.delegate = self
        
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .gray400
        pageControl.currentPageIndicatorTintColor = .gray500
        
        buttonStack.axis = .vertical
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 0
        buttonStack.addArrangedSubview(archiveButton)
        buttonStack.addArrangedSubview(findMateButton)
        
        archiveButton.setTitle("수사일지 아카이브", for: .normal)
        archiveButton.titleLabel?.font = .body3
        archiveButton.setTitleColor(.textPrimary, for: .normal)
        archiveButton.backgroundColor = .gray100
        archiveButton.setImage(UIImage(named: "note"), for: .normal)
        archiveButton.contentHorizontalAlignment = .left
        archiveButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        archiveButton.layer.cornerRadius = 12
        archiveButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        archiveButton.clipsToBounds = true
        archiveButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        findMateButton.setTitle("탐정메이트 찾기", for: .normal)
        findMateButton.titleLabel?.font = .body3
        findMateButton.setTitleColor(.textPrimary, for: .normal)
        findMateButton.backgroundColor = .gray100
        findMateButton.setImage(UIImage(named: "search"), for: .normal)
        findMateButton.contentHorizontalAlignment = .left
        findMateButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        findMateButton.layer.cornerRadius = 12
        findMateButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        findMateButton.clipsToBounds = true
        findMateButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
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
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(208)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
        }
        
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(120)
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
                let backItem = UIBarButtonItem()
                backItem.title = "설정"
                self?.navigationItem.backBarButtonItem = backItem
                self?.navigationController?.navigationBar.titleTextAttributes = [
                    .foregroundColor: UIColor(named: "textPrimary"),
                    .font: UIFont.highlight3
                ]
                self?.navigationController?.navigationBar.tintColor = .textPrimary
                self?.navigationController?.pushViewController(settingVC, animated: true)
            }
            .disposed(by: disposeBag)
        
        // 데이터 스트림 설정
        let petProfiles = petProfilesSubject
            .startWith([]) // 초기값
            .share(replay: 1)
        
        // 컬렉션뷰 바인딩
        petProfiles
            .bind(to: collectionView.rx.items(
                cellIdentifier: DetectiveCardCell.identifier,
                cellType: DetectiveCardCell.self
            )) { row, profile, cell in
                cell.configure(with: profile)
            }
            .disposed(by: disposeBag)
        
        // 펫프로필 갯수에 따른 인덱스닷 생성
        petProfiles
            .map { $0.count }
            .bind(to: pageControl.rx.numberOfPages)
            .disposed(by: disposeBag)
        
        // 옆으로 얼만큼 스크롤 되어야 인덱스 닷이 넘어가는지에 대한 설정
        collectionView.rx.contentOffset
            .map { [weak self] offset in
                guard let self = self else { return 0 }
                
                let cardWidth: CGFloat = 336
                let spacing: CGFloat = 12
                let leftInset: CGFloat = 16
                
                // 현재 보이는 카드의 인덱스 계산
                let adjustedOffset = offset.x + leftInset
                let index = Int((adjustedOffset + cardWidth / 2) / (cardWidth + spacing))
                
                return max(0, index)
            }
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
        
        let selectedProfile = collectionView.rx.itemSelected
            .withLatestFrom(petProfiles) { indexPath, profiles -> PetProfile? in
                guard indexPath.item < profiles.count else { return nil }
                return profiles[indexPath.item]
            }
            .compactMap { $0 }
            .share()
        
        // 선택된 프로필로 수정 화면 present
        selectedProfile
            .flatMapLatest { [weak self] profile -> Observable<Void> in
                guard let self = self else { return .empty() }
                return self.presentRegistrationViewController(with: profile)
            }
            .subscribe()
            .disposed(by: disposeBag)
        
        // 셀 선택 해제 (시각적 효과)
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                self?.collectionView.deselectItem(at: indexPath, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func scrollToItem(at index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        
        // 해당 셀이 존재하는지 확인
        guard collectionView.numberOfItems(inSection: 0) > index else { return }
        
        // 중앙 정렬로 스크롤
        collectionView.scrollToItem(
            at: indexPath,
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    private func fetchUserPetProfiles() {
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        
        FirestoreManager.shared.fetchDocuments(
            collection: "PetProfile",
            whereField: "userId",
            isEqualTo: userId,
            type: PetProfile.self
        )
        .subscribe(onSuccess: { [weak self] profiles in
            guard let self = self else { return }
            self.petProfiles = profiles
            self.petProfilesSubject.onNext(profiles)
        }, onFailure: { error in
            print("펫 프로필 불러오기 실패: \(error)")
            // 빈 배열로 초기화
            self.petProfilesSubject.onNext([])
        })
        .disposed(by: disposeBag)
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
                    self?.fetchUserPetProfiles()
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

extension MyPageViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 336, height: 208)
    }
    // 섹션 인셋 설정
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    // 라인 간격 설정
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    // 아이템 간격 설정
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
