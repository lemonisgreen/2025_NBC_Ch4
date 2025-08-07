//
//  AddNewContentViewController.swift
//  SherlDog
//
//  Created by 최규현 on 8/7/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Kingfisher
import PhotosUI

class AddNewContentViewController: UIViewController {

    private let viewModel = AddNewContentViewModel()
    private let disposeBag = DisposeBag()
    
    // MARK: - UIProperty
    private let navigationTitleLabel = UILabel()
    private let navigationBackButton = UIButton()
    private let navigationAddButton = UIButton()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let selectPetLabel = UILabel()
    private let dropDownButton = UIButton()
    private let petListTableView = UITableView()
    private let contentTextView = UITextView()
    private let addPictureButton = UIButton()
    private lazy var picturesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    
    private var petListTableViewHeightConstraint: Constraint?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
        inputBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = false
    }
    
    // MARK: - Method
    private func bind() {
        viewModel.output.petProfile
            .asDriver()
            .drive(self.petListTableView.rx.items) { tableView, row, item in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PetProfileTableViewCell.identifier, for: IndexPath(row: row, section: 0)) as? PetProfileTableViewCell else { return .init() }
                
                cell.settingCell(data: item)
                
                return cell
            }
            .disposed(by: disposeBag)
        
        viewModel.output.addedPictures
            .asDriver(onErrorJustReturn: [])
            .drive(self.picturesCollectionView.rx.items) { collectionView, row, item in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PicturesCollectionViewCell.identifier, for: IndexPath(item: row, section: 0)) as? PicturesCollectionViewCell else { return .init() }
                
                cell.setImage(item)
                
                return cell
            }
            .disposed(by: disposeBag)
        
        viewModel.output.addPicture
            .asSignal()
            .emit(onNext: { [weak self] count in
                guard let self else { return }
                guard count != 0 else {
                    self.cantAddAlert()
                    return
                }
                
                PermissionManager.requestPermission(type: .album) { [weak self] isAllowed in
                    guard let self else { return }
                    switch isAllowed {
                    case true:
                        var configuration = PHPickerConfiguration()
                        configuration.selectionLimit = count
                        configuration.filter = .any(of: [.images, .livePhotos])
                        
                        let imagePicker = PHPickerViewController(configuration: configuration)
                        imagePicker.delegate = self
                        
                        self.present(imagePicker, animated: true)
                        
                    case false:
                        let alert = CustomAlertViewController(
                            message: "앨범 권한이 필요합니다.",
                            subMessage: "설정에서 변경해주세요.",
                            buttons: [
                                CustomAlertViewController.AlertButton(
                                    title: "취소",
                                    action: nil
                                ),
                                CustomAlertViewController.AlertButton(
                                    title: "설정으로 이동",
                                    action: {
                                        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                                           UIApplication.shared.canOpenURL(settingsURL) {
                                            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                                        }
                                    }
                                )
                            ]
                        )
                        
                        self.present(alert, animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isExpended
            .compactMap { $0 }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] isExpended in
                guard let self else { return }
                let height = self.petListTableView.contentSize.height
                
                self.petListTableViewHeightConstraint?.update(offset: isExpended ? height : 0)
                
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.addPictureButton.rx.tap
            .map { .addPicture }
            .bind(to: self.viewModel.input)
            .disposed(by: disposeBag)
        
        self.navigationBackButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        self.navigationAddButton.rx.tap
            .map { .addButtonTap }
            .bind(to: self.viewModel.input)
            .disposed(by: disposeBag)
        
        self.dropDownButton.rx.tap
            .map { .dropdownTap }
            .bind(to: self.viewModel.input)
            .disposed(by: disposeBag)
    }
    
    private func cantAddAlert() {
        let alert = CustomAlertViewController(message: "더 이상 추가할 수 없습니다",
                                              buttons: [CustomAlertViewController.AlertButton(title: "확인",
                                                                                              action: nil)])
        
        self.present(alert, animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        scrollView.addSubview(contentView)
        
        contentView.addSubviews([
            selectPetLabel,
            dropDownButton,
            petListTableView,
            contentTextView,
            picturesCollectionView,
            addPictureButton
        ])
        
        view.addSubview(scrollView)
        
        // 제스쳐로 뒤로가기 활성화
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        navigationTitleLabel.text = "글 작성"
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationAddButton.setTitle("등록", for: .normal)
        navigationAddButton.setTitleColor(.textAlert, for: .normal)
        navigationAddButton.titleLabel?.font = .highlight3
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .gray50
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationAddButton)
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        selectPetLabel.text = "어떤 탐정님이 모집하는 건가요?"
        selectPetLabel.font = .title1
        selectPetLabel.textColor = .textPrimary
        
        dropDownButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        dropDownButton.tintColor = .textPrimary
        
        petListTableView.register(PetProfileTableViewCell.self, forCellReuseIdentifier: PetProfileTableViewCell.identifier)
        petListTableView.rowHeight = 44
        petListTableView.backgroundColor = .clear
        petListTableView.separatorStyle = .singleLine
        petListTableView.separatorColor = .gray200
        
        contentTextView.font = .body3
        contentTextView.backgroundColor = .gray50
        contentTextView.layer.cornerRadius = 6
        contentTextView.textContainerInset = .init(top: 12, left: 8, bottom: 12, right: 8)
        contentTextView.textColor = .textPrimary
        
        picturesCollectionView.register(PicturesCollectionViewCell.self, forCellWithReuseIdentifier: PicturesCollectionViewCell.identifier)
        picturesCollectionView.backgroundColor = .clear
        
        addPictureButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addPictureButton.setBackgroundColor(.gray200, for: .normal)
    }
    
    private func configureUI() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints {
            $0.edges.width.equalToSuperview()
        }
        
        selectPetLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(16)
            $0.leading.equalToSuperview().inset(16)
        }
        
        dropDownButton.snp.makeConstraints {
            $0.top.bottom.equalTo(selectPetLabel)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        petListTableView.snp.makeConstraints {
            $0.top.equalTo(selectPetLabel.snp.bottom).offset(4)
            $0.leading.trailing.equalToSuperview().inset(16)
            self.petListTableViewHeightConstraint = $0.height.equalTo(0).constraint
        }
        
        contentTextView.snp.makeConstraints {
            $0.height.equalTo(200)
            $0.top.equalTo(petListTableView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        addPictureButton.snp.makeConstraints {
            let width: CGFloat = (UIScreen.main.bounds.width - (16 * 2)) / 4
            
            $0.height.equalTo(100)
            $0.width.equalTo(width)
            $0.top.equalTo(contentTextView.snp.bottom).offset(16)
            $0.leading.equalToSuperview().inset(16)
        }
        
        picturesCollectionView.snp.makeConstraints {
            $0.height.equalTo(addPictureButton)
            $0.top.equalTo(addPictureButton)
            $0.leading.equalTo(addPictureButton.snp.trailing).offset(8)
            $0.trailing.bottom.equalToSuperview().inset(16)
        }
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { row, environment in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1/3.2),
                                                                             heightDimension: .fractionalHeight(1)),
                                                           subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 8
            
            return section
        }
    }
}

extension AddNewContentViewController: PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        results.forEach { result in
            if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                result.itemProvider.loadObject(ofClass: UIImage.self) { item, error in
                    guard let image = item as? UIImage else { return }
                    self.viewModel.input.accept(.selectedPictures(image))
                }
            }
        }
    }
    
}
