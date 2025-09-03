//
//  UserProfileViewController.swift
//  SherlDog
//
//  Created by JIN LEE on 9/3/25.
//

import UIKit
import SnapKit

class UserProfileViewController: UIViewController, UICollectionViewDelegate, UIScrollViewDelegate {
    
    private let navigationBackButton = UIButton()
    private let navigationTitleLabel = UILabel()
    private let navigationMoreButton = UIButton()
    private let profileImageView = UIImageView()
    private let assistantNickNameLabel = UILabel()
    private let assistantNickNameField = UITextField()
    private let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let pageControl = UIPageControl()
    private let postCollectionButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .keycolorBackground

        setupUI()
        configureUI()
    }
    
    private func bind() {
        
    }
    
    private func setupUI() {
        [
            profileImageView,
            assistantNickNameLabel,
            assistantNickNameField,
            collectionView,
            pageControl,
            postCollectionButton
        ].forEach {
            view.addSubview($0)
        }
        
        navigationBackButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationBackButtonImage), for: .normal)
        navigationBackButton.imageView?.tintColor = .textPrimary
        
        navigationTitleLabel.text = SDLiteral.UserProfileViewController.navigationTitle
        navigationTitleLabel.textAlignment = .left
        navigationTitleLabel.font = .highlight3
        navigationTitleLabel.textColor = .textPrimary
        navigationTitleLabel.snp.makeConstraints { $0.width.equalTo(UIScreen.main.bounds.width * (4 / 5)) }
        
        navigationMoreButton.setImage(UIImage(systemName: SDLiteral.UserProfileViewController.navigationMoreButtonImage), for: .normal)
        navigationMoreButton.imageView?.tintColor = .textPrimary
        
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = .keycolorBackground
        navigationBarAppearance.shadowColor = .clear
        
        self.navigationController?.navigationBar.isHidden = false
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: navigationBackButton)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: navigationMoreButton)
        self.navigationItem.titleView = navigationTitleLabel
        self.navigationItem.standardAppearance = navigationBarAppearance
        self.navigationItem.scrollEdgeAppearance = navigationBarAppearance
        
        profileImageView.backgroundColor = .keycolorPrimary4
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.layer.cornerRadius = 66
        profileImageView.layer.masksToBounds = true
        
        assistantNickNameLabel.text = SDLiteral.UserProfileViewController.assistantNickNameLabel
        assistantNickNameLabel.font = .body1
        assistantNickNameLabel.textColor = .textPrimary
        
        assistantNickNameField.backgroundColor = .gray50
        assistantNickNameField.layer.cornerRadius = 6
        assistantNickNameField.leftView = UIView(frame: .init(x: 0, y: 0, width: 12, height: 0))
        assistantNickNameField.leftViewMode = .always
        assistantNickNameField.textColor = .textPrimary
        
        collectionView.register(
            DetectiveCardCell.self,
            forCellWithReuseIdentifier: DetectiveCardCell.identifier)
        collectionView.register(
            ProfileAddCollectionViewCell.self,
            forCellWithReuseIdentifier: ProfileAddCollectionViewCell.identifier)
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate.fast
        collectionView.backgroundColor = .keycolorInverse
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true
        collectionView.delegate = self
        
        pageControl.numberOfPages = 0
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .keycolorPrimary5
        pageControl.currentPageIndicatorTintColor = .keycolorPrimary2
        
        postCollectionButton.setTitle(SDLiteral.UserProfileViewController.postCollectionButtonTitle, for: .normal)
        postCollectionButton.titleLabel?.font = .body3
        postCollectionButton.setTitleColor(.textPrimary, for: .normal)
        postCollectionButton.backgroundColor = .gray100
        postCollectionButton.setImage(UIImage(named: SDLiteral.UserProfileViewController.postCollectionButtonImage), for: .normal)
        postCollectionButton.contentHorizontalAlignment = .left
        postCollectionButton.setContentInsets(.init(top: 16, leading: 16, bottom: 16, trailing: 16))
        postCollectionButton.layer.cornerRadius = 12
        postCollectionButton.clipsToBounds = true
    }
    
    private func configureUI() {
        profileImageView.snp.makeConstraints {
            $0.height.width.equalTo(132)
            $0.top.equalTo(view.safeAreaLayoutGuide).inset(8)
            $0.centerX.equalToSuperview()
        }
        
        assistantNickNameLabel.snp.makeConstraints {
            $0.top.equalTo(profileImageView.snp.bottom).offset(8)
            $0.leading.equalToSuperview().inset(16)
        }
        
        assistantNickNameField.snp.makeConstraints {
            $0.height.equalTo(46)
            $0.top.equalTo(assistantNickNameLabel.snp.bottom).offset(6)
            $0.leading.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(assistantNickNameField.snp.bottom).offset(16)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(0)
            $0.height.equalTo(240)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(24)
        }
        
        postCollectionButton.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(64)
        }
    }

}
