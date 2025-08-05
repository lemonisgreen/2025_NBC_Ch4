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
import Kingfisher

class DetectiveCardCollectionViewCell: UICollectionViewCell {
    
    static let identifier = "DetectiveCardCollectionViewCell"
    
    var onEditTapped: (() -> Void)?
    var onDeleteTapped: (() -> Void)?
    private let disposeBag = DisposeBag()
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
        detectiveCardView.onEditTapped = { [weak self] in
            self?.onEditTapped?()
        }
        detectiveCardView.onDeleteTapped = { [weak self] in
            guard let self = self else { return }
            print("🗑️ 삭제하기 버튼 눌림")
            // 실제 삭제 로직은 외부에서 onDeleteTapped 클로저를 통해 주입받도록 구성
            self.onDeleteTapped?()
        }
    }
    
    func configure(with profile: PetProfile) {
        var age: Int = 0
        var detectiveNumber: String = "?"
        
        if let birthDate = DateFormatter.yyyyMMdd.date(from: profile.age) {
            age = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
            detectiveNumber = DateFormatter.yyMMdd.string(from: birthDate)
        }
        
        self.backgroundColor = .clear
        detectiveCardView.detectiveNumber.text = detectiveNumber
        detectiveCardView.detectiveName.text = profile.name
        detectiveCardView.detectiveBreed.text = profile.breed
        detectiveCardView.detectiveAge.text = "\(age)세"
        detectiveCardView.detectiveIntroduce.text = "# \(profile.introduce)"
        FirebaseImageManager.shared.downloadPetImage(petId: profile.petProfileId, userId: profile.userId) { [weak self] url in
            guard let self else { return }
            
            let processor = DownsamplingImageProcessor(size: self.detectiveCardView.detectivePhotoImageView.bounds.size) // 크기 지정 다운 샘플링
            
            self.detectiveCardView.detectivePhotoImageView.kf.indicatorType = .activity
            KF.url(url)
                .placeholder(UIImage.petAvatar)
                .setProcessor(processor)
                .cacheOriginalImage()
                .fade(duration: 0.25)
                .onFailureImage(UIImage.petAvatar)
                .onSuccess { result in }
                .onFailure { error in }
                .set(to: self.detectiveCardView.detectivePhotoImageView)
        }
    }
}
