//
//  DetectiveCardCollectionViewCell.swift
//  SherlDog
//
//  Created by 최영락 on 6/16/25.
//
import SnapKit
import UIKit
import RxSwift
import RxCocoa

class DetectiveCardCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "DetectiveCardCollectionViewCell"
    
    private let detectiveCardView = DetectiveCardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(detectiveCardView)
        detectiveCardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func configure(with profile: PetProfile) {
        detectiveCardView.detectiveNumber.text = profile.petProfileId
        detectiveCardView.detectiveName.text = profile.name
        detectiveCardView.detectiveBreed.text = profile.breed
        detectiveCardView.detectiveAge.text = "\(profile.age)세"
        detectiveCardView.detectiveIntroduce.text = "# \(profile.introduce)"
        
        // 프로필 이미지 설정
        detectiveCardView.detectivePhotoImageView.backgroundColor = .gray400
        // TODO: 실제 이미지 로딩 시 profile.image 사용
    }
}
