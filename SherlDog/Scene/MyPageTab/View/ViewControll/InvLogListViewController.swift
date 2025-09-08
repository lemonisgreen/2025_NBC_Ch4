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
                
                self.collectionView.visibleCells.forEach {
                    ($0 as? InvLogListCell)?.toggleSelectMode(selectable: isSelectMode)
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
        
        self.viewModel.output.deleteCompleted
            .bind(onNext: {
                print("삭제 완료") // todo: 완료 처리
            })
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
            .bind { [weak self] in
                let alert = CustomAlertViewController(
                     message: "수사일지를 삭제하시겠습니까?",
                     buttons: [
                         CustomAlertViewController.AlertButton(
                             title: "취소",
                             action: nil
                         ),
                         CustomAlertViewController.AlertButton(
                             title: "확인",
                             action: { [weak self] in
                                 guard let self,
                                        let indexPaths = self.collectionView.indexPathsForSelectedItems else { return }
                                 
                                 self.viewModel.input.accept(.delete(indexPaths))
                             }
                         )
                     ]
                 )
                
                self?.present(alert, animated: true)
            }
            .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .gray50
        
        view.addSubviews([
            separatorView,
            collectionView,
            emptyView
        ])
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = "수사일지"
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
//        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .gray50
        navigationBarAppearance.shadowColor = .clear
        
        navigationRightButtonStackView.axis = .horizontal
        navigationRightButtonStackView.spacing = 16
        navigationRightButtonStackView.alignment = .center
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationRightButtonStackView)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        separatorView.backgroundColor = .gray100
        
        collectionView.backgroundColor = .gray50
        collectionView.register(InvLogListCell.self, forCellWithReuseIdentifier: InvLogListCell.identifier)
        collectionView.allowsMultipleSelection = true
        
        modeConvertButton.setTitle("삭제", for: .normal)
        modeConvertButton.setTitleColor(.textAlert, for: .normal)
        modeConvertButton.titleLabel?.font = .title3
        
        cancelButton.setTitle("취소", for: .normal)
        cancelButton.setTitleColor(.gray500, for: .normal)
        cancelButton.titleLabel?.font = .title3
        
        deleteButton.setTitle("확인", for: .normal)
        deleteButton.setTitleColor(.keycolorPrimary2, for: .normal)
        deleteButton.titleLabel?.font = .title3
        
        navigationRightButtonStackView.addArrangedSubview(modeConvertButton)
        
        emptyView.isHidden = true
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
                
                cell.rx.cellTap
                    .subscribe(onNext: { [weak self] in
                        guard let self else { return }
                        
                        let originalData = self.viewModel.originalData[indexPath.row]
                        
                        let walkResultViewModel = DataTrackingViewModel()
                        let walkEndView = WalkEndModalViewController(dataTrackingViewModel: walkResultViewModel)
                        let nav = UINavigationController(rootViewController: walkEndView)
                        nav.modalPresentationStyle = .overFullScreen
                        
                        walkResultViewModel.fetchResult.accept(originalData.0)
                        
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
