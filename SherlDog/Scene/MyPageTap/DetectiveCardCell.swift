//
//  DetectiveCardCell.swift
//  SherlDog
//
//  Created by 전원식 on 6/25/25.
//
import UIKit
import SnapKit

class DetectiveCardCell: UICollectionViewCell {
    static let identifier = "DetectiveCardCell"
    let cardView = DetectiveCardView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(cardView)
        contentView.backgroundColor = .textInverse
        backgroundColor = .clear
        cardView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    func configure(with profile: PetProfile) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        var age: Int = 0
        var detectiveNumber: String = "?"
        
        if let birthDate = formatter.date(from: profile.age) {
            age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            let detectiveNumberFormatter = DateFormatter()
            detectiveNumberFormatter.dateFormat = "yyMMdd"
            detectiveNumber = detectiveNumberFormatter.string(from: birthDate)
        }
        
        cardView.detectiveNumber.text = detectiveNumber
        cardView.detectiveName.text = profile.name
        cardView.detectiveBreed.text = profile.breed
        cardView.detectiveAge.text = "\(age)세"
        cardView.detectiveIntroduce.text = "# \(profile.introduce)"
        FirebaseImageManager.shared.downloadPetImage(petId: profile.petProfileId, userId: profile.userId) { [weak self] image in
            DispatchQueue.main.async {
                self?.cardView.detectivePhotoImageView.image = image
            }
        }
    }
}
