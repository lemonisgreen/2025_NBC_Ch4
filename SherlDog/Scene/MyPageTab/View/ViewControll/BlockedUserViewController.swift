//
//  BlockedUserViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/16/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class BlockedUserViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let viewModel = BlockedUserViewModel()
    
    private let titleLabel = UILabel()
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let cancelButton = UIButton()
    private let unblockButton = UIButton()
    private let editButton = UIButton()
    private let navigationRightButtonStackView = UIStackView()
    private let emptyStateLabel = UILabel()
    private let tableView = UITableView()
    
    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
        
        viewModel.fetchBlockedUsers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchBlockedUsers()
        viewModel.setEditing(false)
    }
    
    private func bind() {

        viewModel.blockedUserIds
            .map { !$0.isEmpty }
            .subscribe(onNext: { [weak self] hasUsers in
                guard let self = self else { return }
                self.editButton.isEnabled = hasUsers
                self.editButton.setTitleColor(hasUsers ? .keycolorPrimary2 : .gray500, for: .normal)
                self.emptyStateLabel.isHidden = hasUsers
            })
            .disposed(by: disposeBag)
        
        navigationBackButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            })
            .disposed(by: disposeBag)
        
        editButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.setEditing(true)
            }
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .bind { [weak self] in
                self?.viewModel.setEditing(false)
            }
            .disposed(by: disposeBag)
        
        unblockButton.rx.tap
            .bind { [weak self] in
                let alert = CustomAlertViewController(
                    message: SDLiteral.BlockedUserViewController.unblcockAlertText,
                    buttons: [
                        CustomAlertViewController.AlertButton(
                            title: SDLiteral.AlertMessage.cancel,
                            action: nil
                        ),
                        CustomAlertViewController.AlertButton(
                            title: SDLiteral.AlertMessage.confirm,
                            action: { [weak self] in
                                self?.viewModel.unblockSelectedUsers()
                                self?.viewModel.setEditing(false)
                            }
                        )
                    ])
                self?.present(alert, animated: true, completion: nil)
            }
            .disposed(by: disposeBag)
        
        viewModel.isEditingMode
            .observe(on: MainScheduler.instance)
            .bind { [weak self] isEditing in
                guard let self = self else { return }
                self.navigationRightButtonStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
                if isEditing {
                    self.navigationRightButtonStackView.addArrangedSubview(self.cancelButton)
                    self.navigationRightButtonStackView.addArrangedSubview(self.unblockButton)
                } else {
                    self.navigationRightButtonStackView.addArrangedSubview(self.editButton)
                }
            }
            .disposed(by: disposeBag)
        
        Observable.combineLatest(
            viewModel.blockedProfiles.asObservable(),
            viewModel.selectedIndexes.asObservable(),
            viewModel.isEditingMode.asObservable()
        )
        .map { (blockedUsers: [HumanProfileModel], _, _: Bool) -> [HumanProfileModel] in
            return blockedUsers
        }
        .bind(to: tableView.rx.items(
            cellIdentifier: BlockedUserListCell.reuseIdentifier,
            cellType: BlockedUserListCell.self)
        ) { [weak self] row, user, cell in
            guard let self = self else { return }
            let isEditing = self.viewModel.isEditingMode.value
            let isSelected = self.viewModel.selectedIndexes.value.contains(row)
            cell.configure(
                withNickname: user.nickname,
                selected: isEditing ? isSelected : false,
                imageUrlString: user.image
            )
            
            cell.selectButton.isHidden = !isEditing
            
            cell.selectTapped
                .bind { [weak self] in
                    self?.viewModel.toggleSelection(row: row)
                }
                .disposed(by: cell.disposeBag)
        }
        .disposed(by: disposeBag)
    }
    
    
    private func setupUI() {
        
        view.backgroundColor = .systemBackground
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.BlockedUserViewController.navigationTitle
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        
        let navigationStack = UIStackView(arrangedSubviews: [navigationBackButton, navigationTitleLabel])
        let containerView = UIView()
        containerView.addSubview(navigationStack)
        
        navigationStack.axis = .horizontal
        navigationStack.alignment = .center
        navigationStack.spacing = 8
        navigationStack.snp.makeConstraints { $0.edges.equalToSuperview() }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorTertiaryBG
        navigationBarAppearance.shadowColor = .clear
        
        navigationRightButtonStackView.axis = .horizontal
        navigationRightButtonStackView.spacing = 16
        navigationRightButtonStackView.alignment = .center
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: containerView)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationRightButtonStackView)
        self.navigationItem.titleView = nil
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        editButton.setTitle(SDLiteral.BlockedUserViewController.navigationEditButton, for: .normal)
        editButton.setTitleColor(.keycolorPrimary2, for: .normal)
        editButton.titleLabel?.font = .title3
        
        cancelButton.setTitle(SDLiteral.BlockedUserViewController.navigationCancelButton, for: .normal)
        cancelButton.setTitleColor(.gray500, for: .normal)
        cancelButton.titleLabel?.font = .title3
        cancelButton.isHidden = false
        
        unblockButton.setTitle(SDLiteral.BlockedUserViewController.navigationUnblockButton, for: .normal)
        unblockButton.setTitleColor(.keycolorPrimary2, for: .normal)
        unblockButton.titleLabel?.font = .title3
        unblockButton.isHidden = false
        
        navigationRightButtonStackView.addArrangedSubview(editButton)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationRightButtonStackView)
        
        emptyStateLabel.text = SDLiteral.BlockedUserViewController.emptyStateLabel
        emptyStateLabel.font = .title3
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.textColor = .black
        emptyStateLabel.isHidden = true
        
        let emptyContainerView = UIView()
         emptyContainerView.addSubview(emptyStateLabel)
         
         emptyStateLabel.snp.makeConstraints {
             $0.centerX.equalToSuperview()
             $0.centerY.equalToSuperview().offset(-50)
         }
        
        tableView.register(BlockedUserListCell.self, forCellReuseIdentifier: BlockedUserListCell.reuseIdentifier)
        tableView.rowHeight = 63
        tableView.separatorStyle = .none
        tableView.backgroundColor = .keycolorTertiaryBG
        tableView.backgroundView = emptyContainerView
        
        view.addSubview(tableView)
    }
    
    private func configureUI() {
        tableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.left.right.bottom.equalToSuperview()
        }
    }
}
