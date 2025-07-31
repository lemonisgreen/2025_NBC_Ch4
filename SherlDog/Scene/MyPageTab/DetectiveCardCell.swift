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
    
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    
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
        cardView.onEditTapped = { [weak self] in
            self?.onEditTapped?()
        }

        cardView.onDeleteTapped = { [weak self] in
            self?.onDeleteTapped?()
        }
    }
    
    func configure(with profile: PetProfile) {
        var age: Int = 0
        var detectiveNumber: String = "?"
        
        if let birthDate = DateFormatter.yyyyMMdd.date(from: profile.age) {
            age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            detectiveNumber = DateFormatter.yyMMdd.string(from: birthDate)
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
