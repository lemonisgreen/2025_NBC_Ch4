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
    
    private lazy var dataSource = self.setDataSource()
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout())
    private let pageControl = UIPageControl()
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
            pageControl,
            loadingIndicator
        ])
        
        // 로딩 인디케이터 설정
        loadingIndicator.color = .gray
        loadingIndicator.hidesWhenStopped = true
        
        collectionView.backgroundColor = .keycolorInverse
        collectionView.register(ClueDetailCell.self, forCellWithReuseIdentifier: ClueDetailCell.identifier)
        
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .keycolorPrimary5
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary2
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        pageControl.snp.makeConstraints {
            $0.bottom.equalToSuperview().inset(isIPhoneSE() ? 8 : 24)
            $0.centerX.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(collectionView)
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    private func isIPhoneSE() -> Bool {
        let screenHeight = UIScreen.main.bounds.height
        return screenHeight <= 667 // SE 1세대(568), SE 2/3세대(667)
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
        
        viewModel.output.cellData
            .map { $0.flatMap { $0.items }.count }
            .bind(to: self.pageControl.rx.numberOfPages)
            .disposed(by: disposeBag)
        
        // 인덱스닷 누르면 해당 순서의 카드로 넘어가는 스크롤 설정
        pageControl.rx.controlEvent(.valueChanged)
            .map { [weak self] in self?.pageControl.currentPage ?? 0 }
            .subscribe(onNext: { [weak self] pageIndex in
                guard let self = self else { return }
                let indexPath = IndexPath(item: pageIndex, section: 0)
                self.collectionView.scrollToItem(
                    at: indexPath,
                    at: .centeredHorizontally,
                    animated: true
                )
            })
            .disposed(by: disposeBag)
        
        // 에러 메시지 바인딩
        viewModel.output.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.loadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
    }
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<ClueDetailViewModel.ClueDataSource> {
        return RxCollectionViewSectionedReloadDataSource<ClueDetailViewModel.ClueDataSource>(
            configureCell: { dataSource, collectionView, indexPath, item  in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClueDetailCell.identifier, for: indexPath) as? ClueDetailCell else { return .init() }
                
                cell.settingCell(image: item.image, content: item.content)
                
                return cell
            }
        )
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
            
            section.visibleItemsInvalidationHandler = { [weak self] items, offset, environment in
                  let pageWidth = environment.container.contentSize.width
                  let page = Int((offset.x + (pageWidth / 2)) / pageWidth)
                  self?.pageControl.currentPage = page
              }
            
            return section
        }
    }
}
