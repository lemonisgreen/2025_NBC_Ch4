//
//  ClueDetailViewController.swift
//  SherlDog
//
//  Created by 김재우 on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxDataSources

final class ClueDetailViewController: UIViewController {
    
    private let viewModel: ClueDetailViewModel
    private let disposeBag = DisposeBag()
    
    private let dataSource = RxCollectionViewSectionedReloadDataSource<ClueDetailViewModel.ClueDataSource>(
        configureCell: { dataSource, collectionView, indexPath, item  in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClueDetailCell.identifier, for: indexPath) as? ClueDetailCell else { return .init() }
            
            cell.settingCell(image: item.image, content: item.content)
            
            return cell
        }
    )
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout())
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init(viewModel: ClueDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.navigationBar.isHidden = true
    }

    private func setupUI() {
        view.backgroundColor = .keycolorInverse
        
        view.addSubviews([
            collectionView,
            loadingIndicator
        ])
        
        // 로딩 인디케이터 설정
        loadingIndicator.color = .gray
        loadingIndicator.hidesWhenStopped = true
        
        collectionView.backgroundColor = .keycolorInverse
        collectionView.register(ClueDetailCell.self, forCellWithReuseIdentifier: ClueDetailCell.identifier)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
//            $0.height.equalTo(600)
//            $0.top.leading.trailing.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(collectionView)
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    private func bindViewModel() {
        // 로딩 상태 바인딩
        viewModel.output.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
        
        // 단서 데이터 바인딩
        viewModel.output.cellData
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        // 에러 메시지 바인딩
        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.loadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
    }
    
    private func collectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .fractionalHeight(1)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                             heightDimension: .estimated(600)),
                                                           subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.orthogonalScrollingBehavior = .groupPaging
            
            return section
        }
    }
}
