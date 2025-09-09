
//PetProfileViewController.swift
//SherlDog

//Created by 최영락 on 6/5/25.


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
    private let petProfileViewModel = PetProfileViewModel()
    
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
    private let nextButton = ButtonFactory.makeButton(type: .main, title: "다음")
    
    let navigationBackButton = UIButton()
    let navigationTitleLabel = UILabel()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupUI()
        configureUI()
        bind()
        
        petProfileViewModel.input.loadProfiles.accept(())
    }
    
    private func bind() {
        
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
        
        petProfileViewModel.output.petProfiles
            .bind(onNext: { [weak self] profiles in
                guard let self = self else { return }
                self.petProfiles = profiles
                self.collectionView.reloadData()
                self.updateNextButtonState()
            })
            .disposed(by: disposeBag)
        
        petProfileViewModel.output.isNextButtonEnabled
            .bind(to: nextButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        petProfileViewModel.output.petProfiles
            .map { !$0.isEmpty }
            .bind(onNext: { [weak self] hasProfiles in
                UIView.animate(withDuration: 0.3) {
                    self?.dogImageView.alpha = hasProfiles ? 0 : 1
                    self?.infoLabel.alpha = hasProfiles ? 0 : 1
                }
            })
            .disposed(by: disposeBag)
        
        petProfileViewModel.output.showRegistrationScreen
            .subscribe(onNext: { [weak self] in
                self?.presentRegistrationView()
            })
            .disposed(by: disposeBag)
        
        petProfileViewModel.output.showEditScreen
            .subscribe(onNext: { [weak self] profile in
                self?.petProfileViewModel.input.editProfileId.accept(profile.petProfileId)
            })
            .disposed(by: disposeBag)
        
        petProfileViewModel.output.profileForEdit
            .subscribe(onNext: { [weak self] profile in
                let registrationVC = RegistrationViewController()
                registrationVC.configure(for: .edit(profile))
                
                registrationVC.profileUpdateSubject
                    .take(1)
                    .subscribe(onNext: { [weak self] _ in
                        self?.petProfileViewModel.input.loadProfiles.accept(())
                    })
                    .disposed(by: registrationVC.disposeBag)
                
                registrationVC.sheetPresentationController?.setModalSize(type: .large, grabber: false)
                registrationVC.isModalInPresentation = true
                
                self?.present(registrationVC, animated: true)
            })
            .disposed(by: disposeBag)
        
        petProfileViewModel.output.errorMessage
            .subscribe(onNext: { message in
                print("Error: \(message)")
            })
            .disposed(by: disposeBag)
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
    
    // MARK: - Navigation
    private func presentRegistrationView() {
        let registrationVC = RegistrationViewController()
        registrationVC.onProfileAdded = { [weak self] newProfileID in
            self?.petProfileViewModel.input.addProfile.accept(newProfileID)
        }
        
        registrationVC.sheetPresentationController?.setModalSize(type: .large, grabber: false)
        registrationVC.isModalInPresentation = true
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
        
        let navigationStack = UIStackView()
        let containerView = UIView()
        
        containerView.addSubview(navigationStack)
        
        navigationStack.addArrangedSubview(navigationBackButton)
        navigationStack.addArrangedSubview(navigationTitleLabel)
        navigationStack.axis = .horizontal
        navigationStack.alignment = .center
        navigationStack.spacing = 8
        navigationStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: containerView)
        self.navigationItem.titleView = nil
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DetectiveCardCollectionViewCell.identifier, for: indexPath) as! DetectiveCardCollectionViewCell
            let profile = petProfiles[indexPath.item]
            cell.configure(with: profile)
            
            cell.onEditTapped = { [weak self] in
                self?.petProfileViewModel.input.editProfileId.accept(profile.petProfileId)
            }
            
            cell.onDeleteTapped = { [weak self] in
                self?.petProfileViewModel.input.deleteProfile.accept(indexPath.item)
            }
            
            return cell
        } else {
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
