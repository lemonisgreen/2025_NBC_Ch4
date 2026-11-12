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
    private let menuEvent = PublishRelay<PostMenuEvent>()
    private let menuViewModel = PostMenuViewModel()
    var onCluesChanged: (() -> Void)?
    
    private lazy var dataSource = self.setDataSource()
    
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewLayout())
    private let pageControl = UIPageControl()
    private let emptyView = EmptyClueView()
    private let loadingIndicator = CustomLoadingIndicator()

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
        view.backgroundColor = .white
        
        view.addSubviews([
            collectionView,
            pageControl,
            emptyView,
            loadingIndicator
        ])
        
        emptyView.isHidden = true
        
        // 로딩 인디케이터 설정
        loadingIndicator.isHidden = true
      
        collectionView.backgroundColor = .clear
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
            $0.bottom.equalToSuperview().inset(UIScreen.isIPhoneSE ? 8 : 24)
            $0.centerX.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        emptyView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    private func bindViewModel() {
        menuViewModel.handleMenuEvent(menuEvent.asObservable(), collection: .just(.clues))
            .emit(onNext: { [weak self] event in
                guard let self else { return }
                if case .error = event {
                    self.showError("요청을 처리하지 못했습니다. 다시 시도해주세요.")
                    return
                }
                self.viewModel.applyMenuResult(event)
                self.onCluesChanged?()
            })
            .disposed(by: disposeBag)

        // 로딩 상태 바인딩
        viewModel.output.isLoading
            .asDriver(onErrorJustReturn: false)
            .map { !$0 }
            .drive(self.loadingIndicator.rx.isHidden)
            .disposed(by: disposeBag)
        
        // 단서 데이터 바인딩
        viewModel.output.cellData
            .observe(on: MainScheduler.instance)
            .bind(to: self.collectionView.rx.items(dataSource: dataSource))
            .disposed(by: disposeBag)
        
        viewModel.output.cellData
            .map { $0.flatMap { $0.items }.count }
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] count in
                guard let self = self else { return }
                let isEmpty = (count == 0)
                self.emptyView.isHidden = !isEmpty
                self.collectionView.isHidden = isEmpty
                self.pageControl.isHidden = isEmpty
                self.pageControl.numberOfPages = count
                self.pageControl.currentPage = min(self.pageControl.currentPage, max(0, count - 1))
            })
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
                self?.loadingIndicator.isHidden = true
                self?.showError(message)
            })
            .disposed(by: disposeBag)
    }
    
    private func setDataSource() -> RxCollectionViewSectionedReloadDataSource<ClueDetailViewModel.ClueDataSource> {
        return RxCollectionViewSectionedReloadDataSource<ClueDetailViewModel.ClueDataSource>(
            configureCell: { [weak self] dataSource, collectionView, indexPath, item  in
                guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ClueDetailCell.identifier, for: indexPath) as? ClueDetailCell else { return .init() }
                
                cell.settingCell(imageURL: item.imageURL, content: item.content)
                cell.settingHeaderView(data: item.header)
                if let self {
                    cell.settingMenu(menu: PostMenuManager.shared.makeMenu(
                        clue: item.clue, viewController: self,
                        onEdit: { [weak self] in self?.editClue(item.clue) },
                        onEvent: { [weak self] event in
                            guard let self else { return }
                            // 신고 화면에서 저장을 완료한 이벤트는 중복 저장하지 않는다.
                            if case .report = event {
                                self.viewModel.applyMenuResult(event)
                            } else {
                                self.menuEvent.accept(event)
                            }
                        }
                    ))
                }
                
                return cell
            }
        )
    }
    
    private func editClue(_ clue: ClueModel) {
        let editor = ClueInputViewController(data: clue)
        editor.onClueUpdated = { [weak self] updated in
            self?.viewModel.updateClue(updated)
            self?.onCluesChanged?()
        }
        editor.modalPresentationStyle = .pageSheet
        editor.sheetPresentationController?.detents = [.large()]
        present(editor, animated: true)
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "알림", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }

    private func collectionViewLayout() -> UICollectionViewCompositionalLayout {
        return UICollectionViewCompositionalLayout { _, _ in
            let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                heightDimension: .estimated(400)))
            
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                             heightDimension: .estimated(400)),
                                                           subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            
            section.orthogonalScrollingBehavior = .groupPaging
            
            section.visibleItemsInvalidationHandler = { [weak self] items, offset, environment in
                  let pageWidth = environment.container.contentSize.width
                  let page = Int(round(offset.x / pageWidth))
                  self?.pageControl.currentPage = page
              }
            
            return section
        }
    }
}
