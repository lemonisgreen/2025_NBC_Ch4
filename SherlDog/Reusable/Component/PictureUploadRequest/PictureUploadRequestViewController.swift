//
//  PictureUploadRequestViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/10/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import RxDataSources
import Differentiator

// MARK: - PictureUploadView
class PictureUploadRequestViewController: UIViewController { // 1: 240, 2: 320, 3: 400
    
    private let viewModel: PictureUploadRequestViewModel
    private let avatarViewModel: SelectAvatarViewModel
    private let cameraViewModel: CameraViewModel
    private let disposeBag = DisposeBag()
    private lazy var dataSource = self.setDataSource()
    
    private let imagePickerController = UIImagePickerController()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    private let setButton = ButtonFactory.makeButton(type: .main, title: "")
    
    // MARK: - Lifecycle
    init(viewModel: PictureUploadRequestViewModel, cameraViewModel: CameraViewModel = CameraViewModel(), avatarViewModel: SelectAvatarViewModel = SelectAvatarViewModel()) {
        self.viewModel = viewModel
        self.cameraViewModel = cameraViewModel
        self.avatarViewModel = avatarViewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        outputBind()
        inputBind()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
}

// MARK: - Method
extension PictureUploadRequestViewController {
    
    private func outputBind() {
        self.viewModel.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel.output.sender
            .subscribe(onNext: { sender in
                guard let sender else { return }
                switch sender {
                    
                case .pictureRequest, .pictureRequestForAssistant, .pictureRequestForPet:
                    self.collectionView.allowsMultipleSelection = false
                    self.setButton.isEnabled = false
                    self.setButton.isHidden = true
                    
                case .sherlDogRequest:
                    self.collectionView.allowsMultipleSelection = true
                    self.setButton.isEnabled = false
                    self.setButton.isHidden = false
                    
                case .sherlDogResult:
                    self.collectionView.allowsSelection = false
                    self.setButton.isEnabled = true
                    self.setButton.isHidden = false
                }
            })
            .disposed(by: disposeBag)
        
        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] _ in
                self?.fetchButtonEnable()
            })
            .disposed(by: disposeBag)
        
        collectionView.rx.itemDeselected
            .subscribe(onNext: { [weak self] _ in
                self?.fetchButtonEnable()
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.buttonName
            .subscribe(onNext: { [weak self] name in
                guard let self else { return }
                
                self.setButton.setTitle(name, for: .normal)
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.moveToView
            .subscribe(onNext: { [weak self] list in
                guard let self,
                      let sender = self.viewModel.output.sender.value else { return }
                
                switch sender {
                case .pictureRequest:
                    cameraViewModel.input.accept(.sender(.communityShare))
                    
                case .pictureRequestForAssistant, .pictureRequestForPet:
                    cameraViewModel.input.accept(.sender(.profile))
                    
                case .sherlDogRequest, .sherlDogResult: break
                }
                
                switch list {
                case .camera:
                    PermissionManager.requestPermission(type: .camera) { [weak self] isAllowed in
                        guard let self else { return }
                        switch isAllowed {
                        case true:
                            let cameraView = UINavigationController(rootViewController: CameraViewController(viewModel: self.cameraViewModel))
                            cameraView.modalPresentationStyle = .fullScreen
                            self.present(cameraView, animated: true)
                            
                        case false:
                            let alert = CustomAlertViewController(
                                message: "카메라 권한이 필요합니다.",
                                subMessage: "설정에서 변경해주세요.",
                                buttons: [
                                    CustomAlertViewController.AlertButton(
                                        title: "확인",
                                        action: nil
                                    )
                                ]
                            )
                            
                            self.present(alert, animated: true)
                        }
                    }
                    
                case .album:
                    PermissionManager.requestPermission(type: .album) { [weak self] isAllowed in
                        guard let self else { return }
                        switch isAllowed {
                        case true:
                            let albumView = UINavigationController(rootViewController: AlbumViewController(viewModel: cameraViewModel))
                            self.present(albumView, animated: true)
                            
                        case false:
                            let alert = CustomAlertViewController(
                                message: "앨범 권한이 필요합니다.",
                                subMessage: "설정에서 변경해주세요.",
                                buttons: [
                                    CustomAlertViewController.AlertButton(
                                        title: "확인",
                                        action: nil
                                    )
                                ]
                            )
                            
                            self.present(alert, animated: true)
                        }
                    }
                    
                case .avatar:
                    if sender == .pictureRequestForAssistant {
                        let selectView = SelectAvatarViewController(viewModel: avatarViewModel)
                        selectView.sheetPresentationController?.prefersGrabberVisible = true
                        self.present(selectView, animated: true)
                        
                    } else {
                        self.cameraViewModel.input.accept(.captureImage(.petAvatar))
                        self.dismiss(animated: true)
                    }
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                guard let sender = self.viewModel.output.sender.value else { return }
                
                switch sender {
                case .sherlDogRequest, .sherlDogResult:
                    break
                default:
                    self.viewModel.input.accept(.setButtonTapped([indexPath.row]))
                }
            })
            .disposed(by: disposeBag)
        
        self.collectionView.rx.itemDeselected
            .subscribe(onNext: { [weak self] _ in
                guard let self else { return }
                self.fetchButtonEnable()
            })
            .disposed(by: disposeBag)
        
        self.setButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self else { return }
                // 함께 수사한 탐정 모달이면 창 닫고 끝냄
                guard self.viewModel.output.sender.value != .sherlDogResult else {
                    self.dismiss(animated: true)
                    return
                }
                
                var selectedIndex: [Int] = []
                
                collectionView.indexPathsForSelectedItems?.forEach {
                    selectedIndex.append($0.row)
                }
                
                self.viewModel.input.accept(.setButtonTapped(selectedIndex))
                if self.viewModel.output.sender.value == .sherlDogRequest {
                    self.dismiss(animated: true)
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func fetchButtonEnable() {
        guard self.viewModel.output.sender.value != .sherlDogResult else {
            self.setButton.isEnabled = true
            return
        }
        
        guard let count = self.collectionView.indexPathsForSelectedItems?.count else { return }
        if count > 0 {
            self.setButton.isEnabled = true
        } else {
            self.setButton.isEnabled = false
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .textInverse
        view.addSubview(collectionView)
        view.addSubview(setButton)
        
        collectionView.backgroundColor = .textInverse
        collectionView.register(PictureUploadRequestViewCell.self,
                                forCellWithReuseIdentifier: PictureUploadRequestViewCell.identifier)
        collectionView.register(PictureUploadRequestViewHeader.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                withReuseIdentifier: PictureUploadRequestViewHeader.identifier)
    }
    
    private func configureUI() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(20)
        }
        
        setButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(21.5)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
    }
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<PictureUploadRequestViewModel.RequestDataSource> {
        return RxCollectionViewSectionedReloadDataSource<PictureUploadRequestViewModel.RequestDataSource>(
            configureCell: { dataSource, collectionView, indexPath, section in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PictureUploadRequestViewCell.identifier, for: indexPath) as? PictureUploadRequestViewCell else { return UICollectionViewCell() }
                
                cell.settingCell(text: section.title, imageName: section.image)
                
                return cell
            }, configureSupplementaryView: { dataSource, collectionView, title, indexPath in
                guard let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                                                   withReuseIdentifier: PictureUploadRequestViewHeader.identifier,
                                                                                   for: indexPath) as? PictureUploadRequestViewHeader else { return UICollectionReusableView() }
                let title = dataSource.sectionModels[indexPath.section].model
                header.setTitle(title: title)
                
                return header
            }
        )
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .absolute(70)))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                       heightDimension: .absolute(500)),
                                                     subitems: [item])
        
        group.interItemSpacing = .fixed(12)
        
        let section = NSCollectionLayoutSection(group: group)
        
        let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                   heightDimension: .estimated(60)),
                                                                 elementKind: UICollectionView.elementKindSectionHeader,
                                                                 alignment: .top)
        section.boundarySupplementaryItems = [header]
        
        return UICollectionViewCompositionalLayout(section: section)
    }
}
