//
//  PetProfileViewController.swift
//  SherlDog
//
//  Created by 최영락 on 6/5/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class PetProfileViewController: UIViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var petProfiles: [PetProfile] = []
    private let maxProfileCount = 3 // 최대 프로필 개수 제한
    
    // MARK: - UI Components
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.bounces = false
        collectionView.alwaysBounceVertical = false
        return collectionView
    }()
    
    private let dogImageView = UIImageView()
    private let infoLabel = UILabel()
    private let nextButton = ButtonManager(title: "다음")
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupCollectionView()
        setupUI()
        configureUI()
        bindUI()
        loadSampleData()
    }
    
    // MARK: - UI Setup
    private func setupNavigationBar() {
        navigationItem.title = "멍탐정 프로필 입력하기"
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(DetectiveCardCollectionViewCell.self,
                                forCellWithReuseIdentifier: DetectiveCardCollectionViewCell.identifier)
        collectionView.register(ProfileAddCollectionViewCell.self,
                                forCellWithReuseIdentifier: ProfileAddCollectionViewCell.identifier)
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor.keycolorBackground
        
        dogImageView.image = UIImage(named: "sherlDog")
        dogImageView.contentMode = .scaleAspectFit
        
        infoLabel.text = "멍탐정을 등록해주세요!"
        infoLabel.textColor = UIColor.textDisabled
        infoLabel.font = .body3
        infoLabel.textAlignment = .center
        
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        
        [collectionView, dogImageView, infoLabel, nextButton].forEach {
            view.addSubview($0)
        }
    }
    
    private func configureUI() {
        updateCollectionViewConstraints()
        
        dogImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(20)
            $0.size.equalTo(80)
        }
        
        infoLabel.snp.makeConstraints {
            $0.top.equalTo(dogImageView.snp.bottom).offset(12)
            $0.centerX.equalToSuperview()
        }
        
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func updateCollectionViewConstraints() {
        collectionView.snp.remakeConstraints {
            if petProfiles.isEmpty {
                // 프로필이 없을 때: 상단부터 제한된 높이까지만
                $0.top.equalTo(view.safeAreaLayoutGuide).offset(0)
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(250) // 고정 높이로 설정
            } else {
                // 프로필이 있을 때: nextButton 위까지 전체 영역 사용
                $0.top.equalTo(view.safeAreaLayoutGuide).offset(0)
                $0.leading.trailing.equalToSuperview()
                $0.bottom.equalTo(nextButton.snp.top).offset(-20)
            }
        }
        
        collectionView.isScrollEnabled = !petProfiles.isEmpty
    }
    
    private func bindUI() {
        // 프로필이 추가될 때마다 다음 버튼 활성화 상태 업데이트
        updateNextButtonState()
        
//        profileAddButton.rx.tap
//            .subscribe(onNext: { [weak self] _ in
//                let registrationVC = RegistrationViewController()
//                if let sheet = registrationVC.sheetPresentationController {
//                    sheet.detents = [.large()]
//                    sheet.selectedDetentIdentifier = .large
//                    sheet.prefersGrabberVisible = true
//                    sheet.preferredCornerRadius = 32
//                    self?.present(registrationVC, animated: true)
//                }
//            })
//            .disposed(by: disposeBag)
    }
    
    private func updateNextButtonState() {
        let hasProfiles = !petProfiles.isEmpty
        
        if hasProfiles {
            nextButton.backgroundColor = UIColor.keycolorPrimary3
            nextButton.alpha = 1.0
        } else {
            nextButton.backgroundColor = UIColor.textDisabled
            nextButton.alpha = 1.0
        }
        // 프로필 유무에 따라 dogImageView와 infoLabel 표시/숨김
        UIView.animate(withDuration: 0.3) {
            self.dogImageView.alpha = hasProfiles ? 0 : 1
            self.infoLabel.alpha = hasProfiles ? 0 : 1
        }
        
        // 컬렉션뷰 제약 조건 업데이트
        updateCollectionViewConstraints()
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Data
    private func loadSampleData() {
        // 초기에는 빈 배열로 시작 (프로필 추가 버튼만 보이도록)
        petProfiles = []
        collectionView.reloadData()
        updateNextButtonState()
    }
    
    private func addNewProfile() {
        // 최대 개수 체크
        guard petProfiles.count < maxProfileCount else {
            return
        }
        
        // 새로운 프로필 추가 (하드코딩)
        let newProfile = PetProfile(
            uid: "22061",
            userId: "user1",
            name: "새로운 멍멍이 \(petProfiles.count + 1)",
            age: Int.random(in: 1...15),
            size: ["소형", "중형", "대형"].randomElement()!,
            image: "bigLogo",
            gender: ["수컷", "암컷"].randomElement()!,
            neutered: Bool.random(),
            breed: ["골든 리트리버", "시바견", "푸들", "말티즈"].randomElement()!,
            introduce: ["활발하고 사교적인 성격", "조용하고 차분함", "장난기 많음", "순하고 착함"].randomElement()!
        )
        
        petProfiles.append(newProfile)
        
        // 안전하게 전체 리로드
        DispatchQueue.main.async {
            self.collectionView.reloadData()
            self.updateNextButtonState()
        }
    }
    
    // MARK: - Navigation
    private func presentBreedSearch() {
        addNewProfile()
    }
}

// MARK: - UICollectionViewDataSource
extension PetProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // 최대 개수에 도달하면 추가 버튼을 숨김
        if petProfiles.count >= maxProfileCount {
            return petProfiles.count
        }
        return petProfiles.count + 1 // 프로필 개수 + 추가 버튼
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item < petProfiles.count {
            // 기존 프로필 카드
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetectiveCardCollectionViewCell.identifier, for: indexPath) as! DetectiveCardCollectionViewCell
            cell.configure(with: petProfiles[indexPath.item])
            return cell
        } else {
            // 프로필 추가 버튼 (최대 개수 미만일 때만)
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProfileAddCollectionViewCell.identifier, for: indexPath) as! ProfileAddCollectionViewCell
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension PetProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item >= petProfiles.count {
            // 프로필 추가 버튼 탭
            presentBreedSearch()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if petProfiles.isEmpty {
            scrollView.contentOffset = CGPoint.zero
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension PetProfileViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 40 // 좌우 여백 20씩
        return CGSize(width: width, height: 208)
    }
}
