//
//  ClueDetailViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import RxSwift
import RxCocoa
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class ClueDetailViewModel {
    
    private let disposeBag = DisposeBag()
    
    // MARK: - Inputs
    enum Input {
        
    }
    
    // MARK: - Outputs
    struct Output {
//        let savedClue = BehaviorRelay<ClueModel?>(value: nil)
        let savedClue = BehaviorRelay(value: [ClueModel]())
//        let image = BehaviorRelay<UIImage?>(value: nil)
        let image = BehaviorRelay(value: [UIImage]())
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = PublishRelay<String>()
    }
    
    private var images = [UIImage]()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init(clue: ClueModel) {
        output.savedClue.accept([clue])
    }
    
    // 새로운 초기화 메서드 추가
    init(coordinate: CLLocationCoordinate2D) {
        // 좌표만으로 새 단서를 만드는 경우
        output.savedClue.accept([])
    }
    
    // 오늘 남긴 단서 표시
    init() {
        fetchCluesData()
    }
    
    private func updateUI(with clue: ClueModel) {
        // Firebase 이미지 다운로드
        downloadImage(from: clue.image) { [weak self] image in
            DispatchQueue.main.async {
                if let image = image {
                    self?.output.image.accept([image])
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
    
    private func fetchCluesData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirestoreManager.shared.fetchDocuments(collection: "clues",
                                               whereField: "userId",
                                               isEqualTo: userId,
                                               type: ClueModel.self)
        .flatMap { [weak self] clue in
            self?.images.removeAll()
            
            return Single<([ClueModel], [UIImage])>.create { [weak self] observer in
                clue.forEach {
                    self?.downloadImage(from: $0.image) { image in
                        if let image {
                            self?.images.append(image)
                        }
                    }
                }
                if let self {
                    observer(.success((clue, self.images)))
                }
                return Disposables.create()
            }
        }
        .subscribe(onSuccess: { [weak self] clues, images in
            guard let self else { return }
            let date = Timestamp(date: Date())
            
            self.output.savedClue.accept(clues.filter { $0.date == date })
            self.output.image.accept(images)
        })
        .disposed(by: disposeBag)
    }
}
