//
//  InvLogListViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/25/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

// MARK: - InvLogListViewController
class InvLogListViewController: UIViewController {
    
    private let viewModel = InvLogListViewModel()
    private let disposeBag = DisposeBag()
    
    private lazy var dataSource = self.setDataSource()
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let cancelButton = UIButton()
    private let deleteButton = UIButton()
    private let modeConvertButton = UIButton()
    private let navigationRightButtonStackView = UIStackView()
    private let separatorView = UIView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())
    private let emptyView = EmptyInvLogView()
    private let onboardingView = UIView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureUI()
        bind()
        inputBind()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.viewModel.input.accept(.viewWillAppear)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
}

// MARK: - Method
extension InvLogListViewController {
    
    private func bind() {
        self.viewModel.output.cellData
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] sections in
                guard let self = self else { return }
                let itemCount = sections.first?.items.count ?? 0
                let isEmpty = (itemCount == 0)
                
                self.emptyView.isHidden = !isEmpty
                self.collectionView.isHidden = isEmpty
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel.output.isSelectMode
            .bind { [weak self] isSelectMode in
                guard let self else { return }
                self.collectionView.allowsSelection = isSelectMode
                self.collectionView.allowsMultipleSelection = isSelectMode
                
                self.navigationRightButtonStackView.arrangedSubviews.forEach {
                    $0.removeFromSuperview()
                }
                
                switch isSelectMode {
                case true:
                    self.navigationRightButtonStackView.addArrangedSubview(cancelButton)
                    self.navigationRightButtonStackView.addArrangedSubview(deleteButton)
                    
                case false:
                    self.navigationRightButtonStackView.addArrangedSubview(modeConvertButton)
                }
            }
            .disposed(by: disposeBag)
        
        self.viewModel.output.cellData
            .map { data -> Bool in
                guard let section = data.first else { return false }
                
                return section.items.count > 0
            }
            .asDriver(onErrorJustReturn: false)
            .drive(onNext: { [weak self] state in
                self?.modeConvertButton.isEnabled = state
                
                state
                ? self?.modeConvertButton.setTitleColor(.textAlert, for: .normal)
                : self?.modeConvertButton.setTitleColor(.textDisabled, for: .normal)
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.deleteCompleted
            .bind(onNext: { [weak self] in
                let alert = CustomAlertViewController(
                    message: SDLiteral.InvLogListView.deleteComplete,
                    buttons: [
                        CustomAlertViewController.AlertButton(
                            title: SDLiteral.AlertMessage.confirm,
                            action: { [weak self] in
                                self?.viewModel.input.accept(.selectModeConvert)
                            }
                        )
                    ]
                )
                
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
        
        self.viewModel.output.needOnboarding
            .asDriver(onErrorJustReturn: false)
            .filter { $0 }
            .do(onNext: { [weak self] _ in
                self?.showOnboardingView()
                self?.onboardingView.isHidden = false
            })
            .flatMap { [weak self] _ -> Driver<Void> in
                self?.onboardingView.isUserInteractionEnabled = true
                
                let press = UILongPressGestureRecognizer()
                press.minimumPressDuration = 0
                press.allowableMovement = 2000
                
                self?.onboardingView.addGestureRecognizer(press)
                return press.rx.event
                    .filter { $0.state == .began }
                    .map { _ in }
                    .asDriver(onErrorDriveWith: .empty())
            }
            .drive { [weak self] _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self?.onboardingView.alpha = 0
                }, completion: { _ in
                    self?.onboardingView.isHidden = true
                    self?.onboardingView.alpha = 1
                })
            }
            .disposed(by: disposeBag)
    }
    
    private func inputBind() {
        self.navigationBackButton.rx.tap
            .bind(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        Observable.merge(
            self.modeConvertButton.rx.tap.asObservable(),
            self.cancelButton.rx.tap.asObservable()
        )
        .map { .selectModeConvert }
        .bind(to: self.viewModel.input)
        .disposed(by: disposeBag)
        
        self.deleteButton.rx.tap
            .map { [weak self] _ -> [IndexPath] in
                guard let self,
                      let indexPaths = self.collectionView.indexPathsForSelectedItems else { return [] }
                
                return indexPaths
            }
            .bind { [weak self] indexPaths in
                let buttons: [CustomAlertViewController.AlertButton]
                
                if indexPaths.count > 0 {
                    buttons = [
                        CustomAlertViewController.AlertButton(
                            title: SDLiteral.AlertMessage.cancel,
                            action: nil
                        ),
                        CustomAlertViewController.AlertButton(
                            title: SDLiteral.AlertMessage.confirm,
                            action: { [weak self] in
                                self?.viewModel.input.accept(.delete(indexPaths))
                            }
                        )
                    ]
                } else {
                    buttons = [
                        CustomAlertViewController.AlertButton(
                            title: SDLiteral.AlertMessage.confirm,
                            action: nil
                        )
                    ]
                }
                
                let alert = CustomAlertViewController(
                    message: indexPaths.count > 0
                    ? SDLiteral.InvLogListView.requestDelete
                    : SDLiteral.InvLogListView.requestDeleteWithoutList,
                    buttons: buttons
                )
                
                self?.present(alert, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func showOnboardingView() {
        let onboardingImageView = UIImageView()
        
        onboardingImageView.image = .invLogListOnboarding
        onboardingImageView.contentMode = .scaleAspectFit
        
        onboardingView.addSubview(onboardingImageView)
        
        onboardingView.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        onboardingImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .gray50
        
        view.addSubviews([
            separatorView,
            collectionView,
            emptyView,
            onboardingView
        ])
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.InvLogListView.title
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        
        let navigationStack = UIStackView()
        let containerView = UIView()
        
        containerView.addSubview(navigationStack)
        
        containerView.addSubview(navigationStack)
        navigationStack.addArrangedSubview(navigationBackButton)
        navigationStack.addArrangedSubview(navigationTitleLabel)
        navigationStack.axis = .horizontal
        navigationStack.alignment = .center
        navigationStack.spacing = 8
        navigationStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .gray50
        navigationBarAppearance.shadowColor = .clear
        
        navigationRightButtonStackView.axis = .horizontal
        navigationRightButtonStackView.spacing = 16
        navigationRightButtonStackView.alignment = .center
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: containerView)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationRightButtonStackView)
        self.navigationItem.titleView = nil
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        separatorView.backgroundColor = .gray100
        
        collectionView.backgroundColor = .gray50
        collectionView.register(InvLogListCell.self, forCellWithReuseIdentifier: InvLogListCell.identifier)
        collectionView.allowsMultipleSelection = true
        
        modeConvertButton.setTitle(SDLiteral.InvLogListView.deleteButton, for: .normal)
        modeConvertButton.setTitleColor(.textAlert, for: .normal)
        modeConvertButton.titleLabel?.font = .title3
        
        cancelButton.setTitle(SDLiteral.AlertMessage.cancel, for: .normal)
        cancelButton.setTitleColor(.gray500, for: .normal)
        cancelButton.titleLabel?.font = .title3
        
        deleteButton.setTitle(SDLiteral.AlertMessage.confirm, for: .normal)
        deleteButton.setTitleColor(.keycolorPrimary2, for: .normal)
        deleteButton.titleLabel?.font = .title3
        
        navigationRightButtonStackView.addArrangedSubview(modeConvertButton)
        
        emptyView.isHidden = true
        onboardingView.isHidden = true
    }
    
    private func configureUI() {
        separatorView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(0.5)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom)
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        emptyView.snp.makeConstraints {
            $0.edges.equalTo(collectionView.snp.edges)
        }
    }
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<InvLogListViewModel.InvLogListDataSource> {
        return RxCollectionViewSectionedReloadDataSource<InvLogListViewModel.InvLogListDataSource>(
            configureCell:{ dataSource, collectionView, indexPath, items in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InvLogListCell.identifier, for: indexPath) as? InvLogListCell else { return .init() }
                
                cell.settingCell(data: items)
                cell.bind(isSelectMode: self.viewModel.output.isSelectMode.asDriver(onErrorJustReturn: false))
                
                cell.rx.cellTap
                    .subscribe(onNext: { [weak self] in
                        guard let self else { return }
                        
                        let (walkResult, petProfiles) = self.viewModel.originalData[indexPath.row]
                        
                        let vm = WalkResultViewModel()
                        let walkEndVC = WalkEndModalViewController(
                            result: walkResult,
                            selectedProfiles: petProfiles,
                            viewModel: vm
                        )
                        
                        let nav = UINavigationController(rootViewController: walkEndVC)
                        nav.modalPresentationStyle = .overFullScreen
                        self.present(nav, animated: true)
                    })
                    .disposed(by: cell.disposeBag)
                
                return cell
            })
    }
    
    private func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { index, environment in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                           heightDimension: .estimated(144)),
                                                         subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
            section.interGroupSpacing = 12
            
            return section
        }
    }
}
