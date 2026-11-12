//
//  PostHeaderView.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Kingfisher
import FirebaseFirestore
import FirebaseAuth

final class PostHeaderView: UICollectionReusableView {
    static let identifier = "PostHeaderView"
    
    var disposeBag = DisposeBag()
    
    private let headerContentView = PostHeaderContentView()

    var configButton: UIButton {
        headerContentView.configButton
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        configureUI()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        headerContentView.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    // MARK: - Public
    func settingCell(data: CommunityModel) {
        let headerData = PostHeaderModel(
            profileImage: data.profileImage,
            name: data.name,
            petProfile: data.petProfile,
            postDate: data.postDate
        )
        
        headerContentView.configure(data: headerData)
    }
    
    func settingMenu(menu: UIMenu) {
        headerContentView.settingMenu(menu: menu)
    }
}

// MARK: - UI
private extension PostHeaderView {
    func setupUI() {
        addSubview(headerContentView)
    }
    
    func configureUI() {
        headerContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
}

extension PostHeaderView {
    fileprivate var profileTap: ControlEvent<Void> {
        headerContentView.profileTap
    }
}

extension Reactive where Base: PostHeaderView {
    var profileTap: ControlEvent<Void> {
        return base.profileTap
    }
}
