//
//  MyPageViewController.swift
//  SherlDog
//
//  Created by 전원식 on 6/24/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class MyPageViewController : UIViewController {
    
    let layout = UICollectionViewFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let pageControl = UIPageControl()
    private let disposeBag = DisposeBag()
    let mypageLabel = UILabel()
    let mypageSettingButton = UIButton()
    let assistantImage = UIImageView()
    let assistantLabel = UILabel()
    let assistantButton = UIButton()
    let archiveButton = UIButton()
    let findMateButton = UIButton()
    let buttonStack = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupUI()
        configureUI()
        bind()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let topLine = CALayer()
        topLine.backgroundColor = UIColor(named: "gray200")?.cgColor
        topLine.frame = CGRect(x: 0, y: 0, width: findMateButton.bounds.width, height: 1)
        findMateButton.layer.addSublayer(topLine)
    }
    
    private func setupUI() {
        [
            mypageLabel,
            mypageSettingButton,
            assistantImage,
            assistantLabel,
            assistantButton,
            collectionView,
            pageControl,
            archiveButton,
            findMateButton,
            buttonStack,
        ].forEach {
            view.addSubview($0)
        }
        mypageLabel.text = "멍탐정 사무소"
        mypageLabel.font = .highlight3
        mypageLabel.textColor = .textPrimary
        
        mypageSettingButton.setImage(UIImage(named: "setting"), for: .normal)
        
        assistantImage.image = UIImage(named: "mypageSample")
        
        assistantLabel.text = "똥봉투 조수"
        assistantLabel.font = .body5
        assistantLabel.textColor = .textPrimary
        
        assistantButton.setTitle("편집", for: .normal)
        assistantButton.setTitleColor(.keycolorPrimary3, for: .normal)
        assistantButton.titleLabel?.font = .alert2
        
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
        
        collectionView.register(DetectiveCardCell.self, forCellWithReuseIdentifier: DetectiveCardCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isPagingEnabled = true
        
        pageControl.numberOfPages = 3
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = .gray400
        pageControl.currentPageIndicatorTintColor = .gray500
        
        buttonStack.axis = .vertical
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 0
        buttonStack.addArrangedSubview(archiveButton)
        buttonStack.addArrangedSubview(findMateButton)
        
        archiveButton.setTitle("수사일지 아카이브", for: .normal)
        archiveButton.titleLabel?.font = .body3
        archiveButton.setTitleColor(.textPrimary, for: .normal)
        archiveButton.backgroundColor = .gray100
        archiveButton.setImage(UIImage(named: "note"), for: .normal)
        archiveButton.contentHorizontalAlignment = .left
        archiveButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        archiveButton.layer.cornerRadius = 12
        archiveButton.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        archiveButton.clipsToBounds = true
        archiveButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
        
        findMateButton.setTitle("탐정메이트 찾기", for: .normal)
        findMateButton.titleLabel?.font = .body3
        findMateButton.setTitleColor(.textPrimary, for: .normal)
        findMateButton.backgroundColor = .gray100
        findMateButton.setImage(UIImage(named: "search"), for: .normal)
        findMateButton.contentHorizontalAlignment = .left
        findMateButton.contentEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        findMateButton.layer.cornerRadius = 12
        findMateButton.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        findMateButton.clipsToBounds = true
        findMateButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: -8)
    }
    
    private func configureUI() {
        mypageLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(70)
            $0.leading.equalToSuperview().inset(16)
        }
        
        mypageSettingButton.snp.makeConstraints {
            $0.top.equalToSuperview().offset(55)
            $0.trailing.equalToSuperview().inset(5)
            $0.width.height.equalTo(56)
        }
        
        assistantImage.snp.makeConstraints {
            $0.top.equalTo(mypageLabel.snp.bottom).offset(24)
            $0.leading.equalToSuperview().inset(16)
        }
        
        assistantLabel.snp.makeConstraints {
            $0.top.equalTo(mypageLabel.snp.bottom).offset(34)
            $0.leading.equalTo(assistantImage.snp.trailing).offset(12)
        }
        
        assistantButton.snp.makeConstraints {
            $0.top.equalTo(mypageLabel.snp.bottom).offset(24)
            $0.trailing.equalToSuperview().inset(16)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(assistantImage.snp.bottom).offset(24)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(250)
        }
        
        pageControl.snp.makeConstraints {
            $0.top.equalTo(collectionView.snp.bottom).offset(8)
            $0.centerX.equalToSuperview()
            $0.height.equalTo(16)
        }
        
        buttonStack.snp.makeConstraints {
            $0.top.equalTo(pageControl.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(16)
            $0.height.equalTo(120)
        }

    }
    
    private func bind() {
        mypageSettingButton.rx.tap
            .bind { [weak self] in
                let settingVC = SettingViewController()
                let backItem = UIBarButtonItem()
                backItem.title = "설정"
                self?.navigationItem.backBarButtonItem = backItem
                self?.navigationController?.navigationBar.titleTextAttributes = [
                    .foregroundColor: UIColor(named: "textPrimary"),
                    .font: UIFont.highlight3
                ]
                self?.navigationController?.navigationBar.tintColor = .textPrimary
                self?.navigationController?.pushViewController(settingVC, animated: true)
            }
            .disposed(by: disposeBag)
    }

    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.width + 0.5)
        pageControl.currentPage = page
    }
}
extension MyPageViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DetectiveCardCell.identifier,
            for: indexPath
        ) as? DetectiveCardCell else {
            return UICollectionViewCell()
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width - 32, height: 208)
    }
}
