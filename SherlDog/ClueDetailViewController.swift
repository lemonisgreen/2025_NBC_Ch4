//
//  ClueDetailViewController.swift
//  SherlDog
//
//  Created by 김재우 on 6/10/25.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ClueDetailViewController: UIViewController {
    
    private let polaroidBackgroundImageView = UIImageView()
    private let clueImageView = UIImageView()
    private let clipNoteBackgroundImageView = UIImageView()
    private let clueTextView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }

    private func setupUI() {
        view.backgroundColor = .white

        polaroidBackgroundImageView.image = UIImage(named: "bigPolaroidSet")
        polaroidBackgroundImageView.contentMode = .scaleAspectFit
//        polaroidBackgroundImageView.layer.borderWidth = 1
//        polaroidBackgroundImageView.layer.borderColor = UIColor.black.cgColor // 영역 확인용

        clueImageView.image = UIImage(named: "")
        clueImageView.contentMode = .scaleAspectFill
        clueImageView.clipsToBounds = true
//        clueImageView.layer.borderWidth = 1
//        clueImageView.layer.borderColor = UIColor.black.cgColor // 영역 확인용
        clueImageView.transform = CGAffineTransform(rotationAngle: -.pi / 36) // 약 -5도
        clueImageView.layer.cornerRadius = 4

        clipNoteBackgroundImageView.image = UIImage(named: "clipSet")
        clipNoteBackgroundImageView.contentMode = .scaleAspectFill

        clueTextView.backgroundColor = .clear
        clueTextView.textColor = .black
        clueTextView.font = UIFont(name: "Pretendard-Regular", size: 14)
        clueTextView.isEditable = false
        
        [polaroidBackgroundImageView, clipNoteBackgroundImageView, clueTextView].forEach { view.addSubview($0) }

        polaroidBackgroundImageView.addSubview(clueImageView)

    }

    private func setupConstraints() {
        polaroidBackgroundImageView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(70)
            $0.leading.trailing.equalToSuperview().inset(1)
        }

        clueImageView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(60)
            $0.top.equalToSuperview().offset(70)
            $0.bottom.equalToSuperview().inset(90)
        }

        clipNoteBackgroundImageView.snp.makeConstraints {
            $0.top.equalTo(polaroidBackgroundImageView.snp.bottom).offset(16)
            $0.centerX.equalToSuperview()
            $0.bottom.equalToSuperview().inset(33)
        }

        clueTextView.snp.makeConstraints {
            $0.edges.equalTo(clipNoteBackgroundImageView).inset(26)
        }
    }
}
