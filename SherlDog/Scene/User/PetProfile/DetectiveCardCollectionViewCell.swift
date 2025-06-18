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
        //나이 변환 코드
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let birthDate = formatter.date(from: profile.age) {
            let age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        }
        
        //생년월일 포맷 변환
        if let birthDate = formatter.date(from: profile.age) {
            let detectiveNumberFormatter = DateFormatter()
            detectiveNumberFormatter.dateFormat = "yyMMdd"
            let detectiveNumber = detectiveNumberFormatter.string(from: birthDate)
        }
        
        detectiveCardView.detectiveNumber.text = detectiveNumber
        detectiveCardView.detectiveName.text = profile.name
        detectiveCardView.detectiveBreed.text = profile.breed
        detectiveCardView.detectiveAge.text = "\(age)세"
        detectiveCardView.detectiveIntroduce.text = "# \(profile.introduce)"
        
        // 프로필 이미지 설정
        detectiveCardView.detectivePhotoImageView.backgroundColor = .gray400
        // TODO: 실제 이미지 로딩 시 profile.image 사용
    }
}
