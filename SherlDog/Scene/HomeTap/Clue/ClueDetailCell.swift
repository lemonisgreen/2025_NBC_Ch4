//
//  ClueDetailCell.swift
//  SherlDog
//
//  Created by 최규현 on 6/27/25.
//

import UIKit

class ClueDetailCell: UICollectionViewCell {
    static let identifier: String = "ClueDetailCell"
    
    private let polaroidBackgroundImageView = UIImageView()
    private let clueImageView = UIImageView()
    private let registImageStamp = UIImageView()
    private let clipNoteBackgroundImageView = UIImageView()
    private let clueTextView = UITextView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupUI()
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func settingCell(image: UIImage, content: String) {
        self.clueImageView.image = image
        self.clueTextView.text = content
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        
        polaroidBackgroundImageView.addSubviews([
            clueImageView,
            registImageStamp
        ])
        
        contentView.addSubviews([
            polaroidBackgroundImageView,
            clipNoteBackgroundImageView,
            clueTextView
        ])
        
        polaroidBackgroundImageView.image = UIImage(named: "bigPolaroidSet")
        polaroidBackgroundImageView.contentMode = .scaleAspectFill
        polaroidBackgroundImageView.clipsToBounds = false
        
        clueImageView.contentMode = .scaleAspectFill
        clueImageView.clipsToBounds = true
        clueImageView.backgroundColor = .systemGray6
        clueImageView.transform = CGAffineTransform(rotationAngle: -.pi / 36)
        clueImageView.layer.cornerRadius = 4

        clipNoteBackgroundImageView.image = UIImage(named: "clipSet")
        clipNoteBackgroundImageView.contentMode = .scaleAspectFill

        clueTextView.textColor = .black
        clueTextView.backgroundColor = .clear
        clueTextView.font = .body6
        clueTextView.isEditable = false
        clueTextView.isScrollEnabled = true
        clueTextView.text = "단서를 불러오는 중..."
        
        let transToFigma = CGFloat.pi / 180
        registImageStamp.contentMode = .scaleAspectFit
        registImageStamp.image = .stamp
        registImageStamp.transform = CGAffineTransform(rotationAngle: transToFigma * -8.01)
        registImageStamp.alpha = 0.5
       
    }

    private func configureUI() {
        polaroidBackgroundImageView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(46)
            $0.leading.trailing.equalToSuperview().inset(36)
        }
        
        clueImageView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(40)
            $0.centerY.equalToSuperview()
            $0.height.equalTo(clueImageView.snp.width).multipliedBy(1.1).priority(.required)
        }
        
        clipNoteBackgroundImageView.snp.makeConstraints {
            $0.top.equalTo(polaroidBackgroundImageView.snp.bottom).offset(36)
            $0.leading.trailing.equalToSuperview().inset(14)
            $0.height.equalTo(132)
        }
        
        clueTextView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(38)
            $0.top.equalTo(clipNoteBackgroundImageView).inset(42)
            $0.bottom.equalTo(clipNoteBackgroundImageView).inset(20)
        }
        
        registImageStamp.snp.makeConstraints {
            $0.width.height.equalTo(48)
            $0.trailing.equalTo(clueImageView.snp.trailing).offset(12)
            $0.bottom.equalTo(clueImageView.snp.bottom).offset(12)
        }
    }
}
