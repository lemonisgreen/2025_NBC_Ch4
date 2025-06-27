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
    
    private lazy var dataSource = RxCollectionViewSectionedReloadDataSource<InvLogListViewModel.InvLogListDataSource>(
        configureCell:{ dataSource, collectionView, indexPath, items in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: InvLogListCell.identifier, for: indexPath) as? InvLogListCell else { return .init() }
            
            cell.delegate = self
            // 역순으로 케이스 번호 계산
            let totalCount = dataSource.sectionModels.first?.items.count ?? 0
            let reversedIndex = totalCount - indexPath.row
            
            cell.settingCell(data: items, caseNumber: String(reversedIndex))
            
            return cell
        })
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let separatorView = UIView()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: configureCollectionViewLayout())
    
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
        
        self.viewModel.input.accept(.viewWillAppear)
    }
    
}

// MARK: - Method
extension InvLogListViewController {
    
    private func bind() {
        self.viewModel.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        self.viewModel.output.deleteCompleted
            .bind(onNext: { [weak self] in
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
    }
    
    private func setupUI() {
        view.backgroundColor = .gray50
        
        view.addSubviews([
            separatorView,
            collectionView
        ])
        
        navigationBackButton.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = "수사일지"
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .gray50
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        separatorView.backgroundColor = .gray100
        
        collectionView.backgroundColor = .gray50
        collectionView.register(InvLogListCell.self, forCellWithReuseIdentifier: InvLogListCell.identifier)
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
    }
    
    private func configureCollectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { index, environment in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1/4)))
            
            let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                           heightDimension: .fractionalHeight(1)),
                                                         subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            return section
        }
    }
}

// MARK: - CellEventDelegate
extension InvLogListViewController: InvLogListCellEventDelegate {
    func deleteButtonTapEvent(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        
        let alert = AlertManager(message: "수사일지를 삭제하시겠습니까?",
                                 buttonTitles: ["취소", "확인"],
                                 buttonActions: [nil, { [weak self] in
            self?.viewModel.input.accept(.delete(indexPath))
        }])
        
        self.present(alert, animated: true)
    }
    
    func showButtonTapEvent(_ cell: UICollectionViewCell) {
        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
        
        let originalData = self.viewModel.originalData[indexPath.row]
        
        let walkResultViewModel = DataTrackingViewModel()
        let walkEndView = WalkEndModalViewController(viewModel: walkResultViewModel)
        let nav = UINavigationController(rootViewController: walkEndView)
        nav.modalPresentationStyle = .overFullScreen
        
        walkResultViewModel.fetchResult.accept(originalData)
        
        self.present(nav, animated: true)
    }
    
    
}
