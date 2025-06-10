//
//  MainViewController.swift
//  SherlDog
//
//  Created by 김재우 on 6/5/25.
//

import UIKit
import SnapKit
import NMapsMap
import RxCocoa
import RxSwift

class MainViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    
    // 지도 배경
    private let mapView = NMFMapView()

    // 상단 카드 뷰
    private let statusView = UIView()
    
    // 거리(m), 시간(분), 걸음 수, 강아지 이미지, 멍탕점과 함께 수사 중
    private let distanceLabel = UILabel()
    private let timeLabel = UILabel()
    private let stepsLabel = UILabel()
    private let image: [String] = []
    private let statusLabel = UILabel()
    
    // distance, time, steps
    private let distance = UILabel()
    private let time = UILabel()
    private let steps = UILabel()
    
    // 스택 뷰
    private let titleStack = UIStackView()
    private let valueStack = UIStackView()
    private let statusStack = UIStackView()
    private let detectiveImageStack = UIStackView()
    
    // 버튼
    private let endButton = UIButton()
    private let clueButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    private func setupUI() {
        [mapView, statusView, endButton, clueButton].forEach {
            view.addSubview($0)
        }

        // 지도 배경 설정
        mapView.positionMode = .normal

        // statusView 설정
        statusView.backgroundColor = .white
        statusView.layer.cornerRadius = 20
        
        // titleStack 설정
        [distanceLabel, timeLabel, stepsLabel].forEach {
            $0.textAlignment = .center
            $0.font = .pretendard(ofSize: 14, weight: .regular)
            $0.textColor = .gray
        }
        distanceLabel.text = "거리(km)"
        timeLabel.text = "시간"
        stepsLabel.text = "걸음 수"
        titleStack.axis = .horizontal
        titleStack.distribution = .fillEqually
        [distanceLabel, timeLabel, stepsLabel].forEach { titleStack.addArrangedSubview($0) }

        // ValueStack 설정
        [distance, time, steps].forEach {
            $0.textAlignment = .center
            $0.font = .pretendard(ofSize: 20, weight: .bold)
            $0.textColor = UIColor(named: "gray600")
        }
        distance.text = "0.45"
        time.text = "00:12:23"
        steps.text = "1234"
        valueStack.axis = .horizontal
        valueStack.distribution = .fillEqually
        [distance, time, steps].forEach { valueStack.addArrangedSubview($0) }

        // detectiveImageStack 설정
        detectiveImageStack.axis = .horizontal
        detectiveImageStack.alignment = .center

        // StatusStack 설정
        statusLabel.text = "멍탐정과 함께 수사 중"
        statusLabel.textAlignment = .center
        statusLabel.font = .pretendard(ofSize: 16, weight: .medium)
        statusLabel.textColor = UIColor(named: "gray600")
        statusStack.axis = .horizontal
        statusStack.spacing = 8
        statusStack.alignment = .center
        statusStack.distribution = .fill
                
        detectiveImageStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        detectiveImageStack.spacing = image.count > 1 ? -8 : 0

        image.forEach { name in
            let imageView = UIImageView(image: UIImage(named: name))
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 12
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 1
            imageView.snp.makeConstraints { $0.size.equalTo(24) }
            detectiveImageStack.addArrangedSubview(imageView)
        }

        statusLabel.text = image.count > 1 ? "멍탐정들과 함께 수사 중" : "멍탐정과 함께 수사 중"
        
        [detectiveImageStack, statusLabel].forEach { statusStack.addArrangedSubview($0) }

        // 스택 + 상태 넣기
        [titleStack, valueStack, statusStack].forEach { statusView.addSubview($0) }

        // 버튼 설정
        endButton.setTitle("수사 종료하기", for: .normal)
        endButton.setTitleColor(.white, for: .normal)
        endButton.backgroundColor = .keycolorPrimary2
        endButton.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 18)
        endButton.layer.cornerRadius = 6

        clueButton.setTitle("단서 남기기", for: .normal)
        clueButton.setTitleColor(.white, for: .normal)
        clueButton.backgroundColor = .white
        clueButton.titleLabel?.font = UIFont(name: "Pretendard-Bold", size: 18)
        clueButton.setTitleColor(UIColor(named: "keycolorPrimary2"), for: .normal)
        clueButton.layer.borderWidth = 1
        clueButton.layer.borderColor = UIColor(named: "keycolorPrimary2")?.cgColor
        clueButton.layer.cornerRadius = 6
    }

    private func setupConstraints() {
        mapView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        statusView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.height.equalTo(136) // estimated height
        }

        titleStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(16)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        valueStack.snp.makeConstraints {
            $0.top.equalTo(titleStack.snp.bottom).offset(18)
            $0.leading.trailing.equalToSuperview().inset(20)
        }

        statusStack.snp.makeConstraints {
            $0.top.equalTo(valueStack.snp.bottom).offset(12)
            $0.bottom.equalToSuperview().inset(10)
            $0.centerX.equalToSuperview()
        }

        clueButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(80)
            $0.trailing.equalTo(view.snp.centerX).offset(-8)
            $0.height.equalTo(48)
        }

        endButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(clueButton)
            $0.leading.equalTo(view.snp.centerX).offset(8)
            $0.height.equalTo(48)
        }
    }
    
}
