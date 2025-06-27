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
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let registImageStamp = UIImageView()
    private let viewModel: ClueDetailViewModel
    private let disposeBag = DisposeBag()

    init(viewModel: ClueDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        bindViewModel()
    }

    private func setupUI() {
        view.backgroundColor = .keycolorInverse

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
        
        // 로딩 인디케이터 설정
        loadingIndicator.color = .gray
        loadingIndicator.hidesWhenStopped = true
        
        [polaroidBackgroundImageView, clipNoteBackgroundImageView, clueTextView, registImageStamp ,loadingIndicator].forEach {
            view.addSubview($0)
        }

        polaroidBackgroundImageView.addSubview(clueImageView)
        polaroidBackgroundImageView.addSubview(registImageStamp)
    }

    private func setupConstraints() {
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
        
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(clueImageView)
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    private func bindViewModel() {
        // 로딩 상태 바인딩
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
        
        // 단서 데이터 바인딩
        viewModel.savedClue
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] clue in
                if let clue = clue {
                    self?.updateUI(with: clue)
                } else {
                    self?.clueTextView.text = "단서를 불러오는 중..."
                }
            })
            .disposed(by: disposeBag)
        
        // 에러 메시지 바인딩
        viewModel.errorMessage
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] message in
                self?.clueTextView.text = "단서를 불러올 수 없습니다"
                self?.loadingIndicator.stopAnimating()
            })
            .disposed(by: disposeBag)
    }
    
    private func updateUI(with clue: ClueModel) {
        // 텍스트 표시
        clueTextView.text = clue.content
        
        // 이미지 로딩
        loadingIndicator.startAnimating()
        
        // 기본 이미지 먼저 표시
        clueImageView.image = UIImage(named: "clueSampleImage")
        
        // Firebase 이미지 다운로드
        downloadImage(from: clue.image) { [weak self] image in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                if let image = image {
                    self?.clueImageView.image = image
                }
            }
        }
    }
    
    private func downloadImage(from urlString: String, completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }.resume()
    }
}
