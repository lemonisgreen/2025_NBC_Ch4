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
import FirebaseAuth

final class PetProfileViewController: UIViewController {
    
    // MARK: - Properties
    private let disposeBag = DisposeBag()
    private var petProfiles: [PetProfile] = []
    private let maxProfileCount = 3 // 최대 프로필 개수 제한
    private let viewModel = RegistrationViewModel()
    
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
    private let nextButton = ComponentButton(title: "다음")
    
    let navigationBackButton = UIButton()
    let navigationTitleLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //setupNavigationBar()
        setupCollectionView()
        setupUI()
        configureUI()
        bindUI()
        loadSampleData()
    }
    
    // MARK: - UI Setup
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(DetectiveCardCollectionViewCell.self,
                                forCellWithReuseIdentifier: DetectiveCardCollectionViewCell.identifier)
        collectionView.register(ProfileAddCollectionViewCell.self,
                                forCellWithReuseIdentifier: ProfileAddCollectionViewCell.identifier)
    }
    
    private func setupUI() {
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = "멍탐정 프로필 입력하기"
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
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
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
    }
    
    private func updateCollectionViewConstraints() {
        collectionView.snp.remakeConstraints {
            if petProfiles.isEmpty {
                // 프로필이 없을 때: 상단부터 제한된 높이까지만
                $0.top.equalTo(view.safeAreaLayoutGuide)
                $0.leading.trailing.equalToSuperview()
                $0.height.equalTo(250) // 고정 높이로 설정
            } else {
                // 프로필이 있을 때: nextButton 위까지 전체 영역 사용
                $0.top.equalTo(view.safeAreaLayoutGuide)
                $0.leading.trailing.equalToSuperview()
                $0.bottom.equalTo(nextButton.snp.top).offset(-20)
            }
        }
        
        collectionView.isScrollEnabled = !petProfiles.isEmpty
    }
    
    private func bindUI() {
        
        navigationBackButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        // 프로필이 추가될 때마다 다음 버튼 활성화 상태 업데이트
        updateNextButtonState()
        
        nextButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                
                let createAssistantVC = CreateAssistantProfileViewController()
                self.navigationController?.pushViewController(createAssistantVC, animated: true)
            })
            .disposed(by: disposeBag)
    }
    
    
    private func updateNextButtonState() {
        let hasProfiles = !petProfiles.isEmpty
        
        nextButton.isEnabled = hasProfiles
        
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
        // 현재 사용자 ID 가져오기
        guard let currentUserId = Auth.auth().currentUser?.uid else {
            // 로그인되지 않은 경우 빈 배열로 시작
            petProfiles = []
            collectionView.reloadData()
            updateNextButtonState()
            return
        }
        
        // 기존 펫 프로필들 불러오기
        FirestoreManager.shared.fetchUserPetProfiles(userId: currentUserId)
            .subscribe(onSuccess: { [weak self] profiles in
                self?.petProfiles = profiles
                DispatchQueue.main.async {
                    self?.collectionView.reloadData()
                    self?.updateNextButtonState()
                }
            }, onFailure: { error in
                // 실패 시 빈 배열로 초기화
                self.petProfiles = []
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                    self.updateNextButtonState()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func bindViewModel() {
        viewModel.output.newPetProfileId
                .subscribe(onNext: { [weak self] id in
                    self?.addNewProfile(with: id ?? "")
                })
                .disposed(by: disposeBag)
        }
    
    private func addNewProfile(with petProfileID: String) {
        guard petProfiles.count < maxProfileCount else { return }
        
        FirestoreManager.shared.fetchDocument(
            collection: "PetProfile",
            documentId: petProfileID,
            type: PetProfile.self
        )
        .subscribe(onSuccess: { [weak self] newProfile in
            guard let self = self else { return }
            self.petProfiles.append(newProfile)
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.updateNextButtonState()
            }
        }, onFailure: { error in
            print("펫 프로필 불러오기 실패: \(error)")
        })
        .disposed(by: disposeBag)
    }
    
    private func deleteProfile(at index: Int) {
        guard index < petProfiles.count else { return }

        let profileToDelete = petProfiles[index]

        FirestoreManager.shared.deleteDocument(
            collection: "PetProfile",
            documentId: profileToDelete.petProfileId ?? ""
        )
        .subscribe(onCompleted: { [weak self] in
            guard let self = self else { return }
            self.petProfiles.remove(at: index)
            DispatchQueue.main.async {
                self.collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                self.updateNextButtonState()
            }
        }, onError: { error in
            print("❌ 삭제 실패: \(error)")
        })
        .disposed(by: disposeBag)
    }
    
    // MARK: - Navigation
    private func presentRegistrationView() {
        let registrationVC = RegistrationViewController()
        registrationVC.onProfileAdded = { [weak self] newProfileID in
            self?.addNewProfile(with: newProfileID)
        }
        if let sheet = registrationVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.selectedDetentIdentifier = .large
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
            self.present(registrationVC, animated: true)
        }
        registrationVC.isModalInPresentation = true
    }
    
    private func presentEditView(for profileId: String) {
        FirestoreManager.shared.fetchDocument(
            collection: "PetProfile",
            documentId: profileId,
            type: PetProfile.self
        )
        .subscribe(onSuccess: { [weak self] profile in
            print("✅ 성공적으로 불러옴: \(profile.name)")

            let registrationVC = RegistrationViewController()
            registrationVC.configure(for: .edit(profile), with: profile)

            registrationVC.profileUpdateSubject
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.loadSampleData()
                })
                .disposed(by: registrationVC.disposeBag)

            if let sheet = registrationVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.selectedDetentIdentifier = .large
                sheet.prefersGrabberVisible = false
                sheet.preferredCornerRadius = 20
            }
            registrationVC.isModalInPresentation = true

            self?.present(registrationVC, animated: true)
        }, onFailure: { error in
            print("❌ 에러 발생: \(error)")
        })
        .disposed(by: disposeBag)
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
            cell.onEditTapped = { [weak self] in
                guard let self = self else { return }
                let profile = self.petProfiles[indexPath.item]
                self.presentEditView(for: profile.petProfileId ?? "")
            }
            cell.onDeleteTapped = { [weak self] in
                guard let self = self else { return }
                self.deleteProfile(at: indexPath.item)
            }
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
            presentRegistrationView()
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
