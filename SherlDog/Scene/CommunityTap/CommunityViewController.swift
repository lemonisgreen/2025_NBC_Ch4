//
//  CommunityViewController.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - CommunityViewController
class CommunityViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    private let testCell = BehaviorRelay(value: CommunityModel.sample)  // test
    
    private let titleLabel = UILabel()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewCompositionalLayout())
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        configureUI()
        bind()
    }
}

// MARK: - Method
extension CommunityViewController {
    
    private func bind() {
        testCell.bind(to: self.collectionView.rx.items) { collectionView, row, item in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CommunityCell.identifier, for: IndexPath(row: row, section: 0)) as? CommunityCell else { return .init() }
            
//            cell.delegate = self
            cell.settingCell(data: item)
            
            return cell
        }
        .disposed(by: disposeBag)
    }
    
    private func setupUI() {
        view.backgroundColor = .gray50
        view.addSubviews([
            titleLabel,
            collectionView
        ])
        
        titleLabel.text = "커뮤니티"
        titleLabel.font = .title1
        titleLabel.textColor = .textPrimary
        
        collectionView.register(CommunityCell.self, forCellWithReuseIdentifier: CommunityCell.identifier)
    }
    
    private func configureUI() {
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.leading.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.horizontalEdges.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func collectionViewCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let inset: CGFloat = 16
        
        let item = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                            heightDimension: .estimated(300)))
        
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                                                       heightDimension: .estimated(300)),
                                                     subitems: [item])
        
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 0, leading: inset, bottom: 0, trailing: inset)
        
        return UICollectionViewCompositionalLayout(section: section)
    }
    
}

// 추후 작업 예정
//extension CommunityViewController: CommunityCellDelegate {
//    func didTapMoreShowButton(in cell: CommunityCell) {
//        guard let indexPath = self.collectionView.indexPath(for: cell) else { return }
//        var current = testCell.value
//        current[indexPath.row].isExpanded.toggle()
//        testCell.accept(current)
//    }
//}
