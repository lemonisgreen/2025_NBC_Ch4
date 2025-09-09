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
import RxDataSources

final class AddNewContentViewController: UIViewController {

    private let viewModel = AddNewContentViewModel()
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = setDataSource()
    
    // MARK: - UIProperty
    private let navigationTitleLabel = UILabel()
    private let navigationBackButton = UIButton()
    private let navigationAddButton = UIButton()
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private lazy var petListCollectionView = UICollectionView(frame: .zero, collectionViewLayout: petSelectCollectionViewLayout())
    private let contentTextView = UITextView()
    private let textViewPlaceholderLabel = UILabel()
    private let selectedPictureCountLabel = UILabel()
    private let addPictureButton = UIButton()
    private lazy var picturesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: picturesCollectionViewCompositionalLayout())
    private let loadingIndicator = CustomLoadingIndicator()
    
    
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
    
    // Add mode
    init() {
        super.init(nibName: nil, bundle: nil)
        
        self.addModeSetting()
    }
    
    // Edit mode
    init(category: CommunityViewModel.CommunitySectionType, post: CommunityModel) {
        super.init(nibName: nil, bundle: nil)
        
        self.viewModel.input.accept(.editCase(category: category, post: post))
        self.editModeBind()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Method
    private func bind() {
        viewModel.output.uploadComplete
            .asSignal()
            .emit(onNext: { [weak self] in
                self?.completeAlert()
            })
            .disposed(by: disposeBag)
        
        viewModel.output.isLoading
            .map { !$0 }
            .asDriver(onErrorJustReturn: true)
            .drive(onNext: { [weak self] state in
                guard let self else { return }
                self.loadingIndicator.isHidden = state
                self.navigationAddButton.isEnabled = state
                self.navigationBackButton.isEnabled = state
                self.navigationController?.interactivePopGestureRecognizer?.isEnabled = state
            })
            .disposed(by: disposeBag)
        
        viewModel.output.petSelectCellData
            .asDriver()
            .drive(self.petListCollectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.output.petSelectCellData
            .asDriver()
            .drive { [weak self] sections in
                guard let self else { return }
                let headerH: CGFloat = 50
                let rowH: CGFloat = 50
                let rowSpacing: CGFloat = 8
                let itemCount = sections.first?.items.count ?? 0
                let rowsHeight = (CGFloat(itemCount) * rowH) + (CGFloat(max(0, itemCount - 1)) * rowSpacing)
                let total = headerH + rowsHeight
                
                UIView.animate(withDuration: 0.2) {
                    self.petListCollectionView.snp.updateConstraints { $0.height.equalTo(total) }
                    self.view.layoutIfNeeded()
                }
            }
            .disposed(by: disposeBag)
        
        viewModel.output.isExpanded
            .asSignal(onErrorJustReturn: false)
            .emit { [weak self] isExpanded in
                guard let self,
                      let header = self.petListCollectionView.supplementaryView(
                        forElementKind: UICollectionView.elementKindSectionHeader,
                        at: IndexPath(row: 0, section: 0)) as? PetSelectHeaderView else { return }
                
                header.setDisclosure(isExpanded: isExpanded)
                
                self.petListCollectionView.layer.borderColor = isExpanded
                ? UIColor.gray100.cgColor
                : UIColor.gray300.cgColor
            }
            .disposed(by: disposeBag)
        
        viewModel.output.picturesCellDisplay
            .asDriver(onErrorJustReturn: [])
            .drive(self.picturesCollectionView.rx.items) { collectionView, row, item in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PicturesCollectionViewCell.identifier, for: IndexPath(item: row, section: 0)) as? PicturesCollectionViewCell else { return .init() }
                
                cell.setImage(item)
                
                cell.rx.deleteButtonTap
                    .map { .deleteButtonTap(row) }
                    .bind(to: self.viewModel.input)
                    .disposed(by: cell.disposeBag)
                
                return cell
            }
            .disposed(by: disposeBag)
        
        viewModel.output.picturesCellDisplay
            .map { String(format: SDLiteral.AddNewContentView.pictureCount, $0.count) }
            .bind(to: self.selectedPictureCountLabel.rx.text)
            .disposed(by: disposeBag)
        
        viewModel.output.openAlbum
            .withLatestFrom(self.viewModel.output.selectedImageIdentifiers)
            .asSignal(onErrorJustReturn: [])
            .emit(onNext: { [weak self] ids in
                guard let self else { return }
                let existingCount = self.viewModel.output.existingImages.value.count
                
                PermissionManager.requestPermission(type: .album) { [weak self] isAllowed in
                    guard let self else { return }
                    switch isAllowed {
                    case true:
                        var configuration = PHPickerConfiguration(photoLibrary: .shared())
                        configuration.selectionLimit = 5 - existingCount
                        configuration.selection = .ordered
                        configuration.filter = .images
                        configuration.preferredAssetRepresentationMode = .current
                        configuration.preselectedAssetIdentifiers = ids
                        
                        let imagePicker = PHPickerViewController(configuration: configuration)
                        imagePicker.delegate = self
                        
                        self.present(imagePicker, animated: true)
                        
                    case false:
                        let alert = CustomAlertViewController(
                            message: String(format: SDLiteral.AlertMessage.permissionDenied,
                                            SDLiteral.AlertMessage.album),
                            subMessage: SDLiteral.AlertMessage.permissionSetting,
                            buttons: [
                                CustomAlertViewController.AlertButton(
                                    title: SDLiteral.AlertMessage.cancel,
                                    action: nil
                                ),
                                CustomAlertViewController.AlertButton(
                                    title: SDLiteral.AlertMessage.moveToSetting,
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
        
        self.petListCollectionView.rx.willDisplayCell
            .withLatestFrom(self.viewModel.output.selectedIndex) { ($0, $1) }
            .observe(on: MainScheduler.asyncInstance)
            .bind { [weak self] event, selectedRows in
                guard let self = self else { return }
                let indexPath = event.at
                
                if selectedRows.contains(indexPath.item) {
                    self.petListCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                }
            }
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.petListCollectionView.rx.itemSelected
            .compactMap { _ in
                guard let indexs = self.petListCollectionView.indexPathsForSelectedItems else { return nil }
                let rows = indexs.map { $0.row }
                return .profileSelect(rows)
            }
            .bind(to: self.viewModel.input)
            .disposed(by: disposeBag)
        
        self.petListCollectionView.rx.itemDeselected
            .compactMap { _ in
                guard let indexs = self.petListCollectionView.indexPathsForSelectedItems else { return nil }
                let rows = indexs.map { $0.row }
                return .profileSelect(rows)
            }
            .bind(to: self.viewModel.input)
            .disposed(by: disposeBag)
        
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
        
        self.contentTextView.rx.text.orEmpty
            .distinctUntilChanged()
            .bind(to: self.viewModel.text)
            .disposed(by: disposeBag)
        
        self.contentTextView.rx.text.orEmpty
            .map { !$0.isEmpty }
            .bind(to: self.textViewPlaceholderLabel.rx.isHidden)
            .disposed(by: disposeBag)
    }
    
    private func editModeBind() {
        self.navigationAddButton.setTitle(SDLiteral.AddNewContentView.editButtonTitle, for: .normal)
        self.navigationTitleLabel.text = SDLiteral.AddNewContentView.titleByEditMode
        
        viewModel.text
            .skip(while: { $0 == "" })
            .take(1)
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [weak self] text in
                self?.contentTextView.text = text
            })
            .disposed(by: disposeBag)
    }
    
    private func addModeSetting() {
        navigationTitleLabel.text = SDLiteral.AddNewContentView.title
        navigationAddButton.setTitle(SDLiteral.AddNewContentView.addButtonTitle, for: .normal)
    }
    
    private func completeAlert() {
        let alert = CustomAlertViewController(message: SDLiteral.AlertMessage.completePost,
                                              buttons: [CustomAlertViewController.AlertButton(
                                                title: SDLiteral.AlertMessage.confirm,
                                                action: { [weak self] in
                                                    self?.navigationController?.popViewController(animated: true)
                                                })])
        
        self.present(alert, animated: true)
    }
    
    private func setupUI() {
        view.backgroundColor = .keycolorBackground
        
        scrollView.addSubview(contentView)
        
        contentTextView.addSubview(textViewPlaceholderLabel)
        
        contentView.addSubviews([
            petListCollectionView,
            contentTextView,
            picturesCollectionView,
            selectedPictureCountLabel,
            addPictureButton,
            loadingIndicator
        ])
        
        view.addSubview(scrollView)
        
        // 키보드 숨기기 활성화
        self.hideKeyboardWhenTappedAroundRx(disposeBag: disposeBag)
        
        // 제스쳐로 뒤로가기 활성화
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        let navigationStack = UIStackView()
        let containerView = UIView()
        
        containerView.addSubview(navigationStack)
        
        navigationStack.addArrangedSubview(navigationBackButton)
        navigationStack.addArrangedSubview(navigationTitleLabel)
        navigationStack.axis = .horizontal
        navigationStack.alignment = .center
        navigationStack.spacing = 8
        navigationStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        navigationAddButton.setTitleColor(.textAlert, for: .normal)
        navigationAddButton.titleLabel?.font = .highlight3
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationItem.titleView = nil
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: containerView)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationAddButton)
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        petListCollectionView.register(PetSelectCardCell.self,
                                       forCellWithReuseIdentifier: PetSelectCardCell.identifier)
        petListCollectionView.register(PetSelectHeaderView.self,
                                       forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                                       withReuseIdentifier: PetSelectHeaderView.identifier)
        petListCollectionView.allowsMultipleSelection = true
        petListCollectionView.backgroundColor = .white
        petListCollectionView.layer.cornerRadius = 12
        petListCollectionView.clipsToBounds = true
        petListCollectionView.layer.borderColor = UIColor.gray300.cgColor
        petListCollectionView.layer.borderWidth = 1
        
        contentTextView.font = .body3
        contentTextView.backgroundColor = .gray50
        contentTextView.layer.cornerRadius = 6
        contentTextView.textContainerInset = .init(top: 12, left: 4, bottom: 12, right: 4)
        contentTextView.textColor = .textPrimary
        
        textViewPlaceholderLabel.text = SDLiteral.AddNewContentView.textViewPlaceholder
        textViewPlaceholderLabel.font = .body6
        textViewPlaceholderLabel.textColor = .gray500
        textViewPlaceholderLabel.numberOfLines = 0
        
        selectedPictureCountLabel.text = String(format:SDLiteral.AddNewContentView.pictureCount, 0)
        selectedPictureCountLabel.font = .alert2
        selectedPictureCountLabel.textColor = .gray400
        
        picturesCollectionView.register(PicturesCollectionViewCell.self, forCellWithReuseIdentifier: PicturesCollectionViewCell.identifier)
        picturesCollectionView.backgroundColor = .clear
        
        addPictureButton
            .setImage(UIImage(systemName: "plus")?
                .withTintColor(.white, renderingMode: .alwaysOriginal),
                      for: .normal)
        addPictureButton.setBackgroundColor(.gray300, for: .normal)
        addPictureButton.clipsToBounds = true
        addPictureButton.layer.cornerRadius = 2
        addPictureButton.layer.borderColor = UIColor.gray400.cgColor
        addPictureButton.layer.borderWidth = 1
    }
    
    private func configureUI() {
        scrollView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints {
            $0.edges.width.equalToSuperview()
        }
        
        petListCollectionView.snp.makeConstraints {
            $0.height.equalTo(54)
            $0.top.equalToSuperview().inset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.bottom.equalTo(contentTextView.snp.top).offset(-16)
        }
        
        contentTextView.snp.makeConstraints {
            $0.height.equalTo(400)
            $0.top.equalTo(petListCollectionView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        textViewPlaceholderLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(12)
            $0.leading.equalToSuperview().inset(8)
        }
        
        selectedPictureCountLabel.snp.makeConstraints {
            $0.top.equalTo(contentTextView.snp.bottom).offset(4)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        addPictureButton.snp.makeConstraints {
            $0.height.equalTo(96)
            $0.width.equalTo(76)
            $0.top.equalTo(selectedPictureCountLabel.snp.bottom).offset(2)
            $0.leading.equalToSuperview().inset(16)
        }
        
        picturesCollectionView.snp.makeConstraints {
            $0.height.equalTo(104)
            $0.top.equalTo(addPictureButton).offset(-8)
            $0.leading.equalTo(addPictureButton.snp.trailing).offset(8)
            $0.trailing.bottom.equalToSuperview().inset(16)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    // MARK: - CollectionView Layout
    private func petSelectCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { row, env in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                                                heightDimension: .estimated(50)))

            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                                                           heightDimension: .estimated(50)),
                                                         subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 0, leading: 12, bottom: 0, trailing: 12)
            section.interGroupSpacing = 8

            // Header
            let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                                       heightDimension: .estimated(50)),
                                                                     elementKind: UICollectionView.elementKindSectionHeader,
                                                                     alignment: .top)
            section.boundarySupplementaryItems = [header]

            return section
        }
        return layout
    }
    
    private func picturesCollectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { row, environment in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .absolute(76),
                                                                             heightDimension: .fractionalHeight(1)),
                                                           subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 8
            
            return section
        }
    }
}

// MARK: - petSelectCollectionView DataSource
extension AddNewContentViewController {
    private func setDataSource() -> RxCollectionViewSectionedAnimatedDataSource<AddNewContentViewModel.PetSelectSection> {
        return RxCollectionViewSectionedAnimatedDataSource<AddNewContentViewModel.PetSelectSection>(
            configureCell: { _, collectionView, indexPath, item in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PetSelectCardCell.identifier, for: indexPath) as? PetSelectCardCell else { return .init() }
                
                cell.settingCell(data: item.base)
                
                return cell
            },
            configureSupplementaryView: { dataSource, collectionView, kind, indexPath in
                let sectionModel = dataSource.sectionModels[indexPath.section].model
                switch kind {
                case UICollectionView.elementKindSectionHeader:
                    guard let header = collectionView.dequeueReusableSupplementaryView(
                        ofKind: kind,
                        withReuseIdentifier: PetSelectHeaderView.identifier,
                        for: indexPath
                    ) as? PetSelectHeaderView else { return .init() }
                    
                    header.setTitle(title: sectionModel)
                    
                    header.rx.dropdownEvent
                        .map { _ in .dropdownTap }
                        .bind(to: self.viewModel.input)
                        .disposed(by: header.disposeBag)
                    
                    return header
                    
                default:
                    return .init()
                }
            }
        )
    }
}

// MARK: - PHPickerViewControllerDelegate
extension AddNewContentViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        self.viewModel.input.accept(.selectedPictures(results))
    }
}
