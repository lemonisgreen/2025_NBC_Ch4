//
//  ClueDetailViewModel.swift
//  SherlDog
//
//  Created by 김재우 on 6/19/25.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Differentiator
import CoreLocation
import FirebaseAuth
import FirebaseFirestore
import UIKit

final class ClueDetailViewModel {
    
    private let disposeBag = DisposeBag()
    
    struct ClueCellData {
        let image: UIImage
        let content: String
    }
    
    // MARK: - Inputs
    enum Input {
        
    }
    
    // MARK: - Outputs
    struct Output {
        let cellData = BehaviorRelay<[ClueDataSource]>(value: [ClueDataSource(model: "",
                                                                              items: [ClueCellData(image: UIImage(),
                                                                                                   content: "")])])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let errorMessage = PublishRelay<String>()
    }
    
    typealias ClueDataSource = SectionModel<String, ClueCellData>
    private var images = [UIImage]()
    private var data = [ClueCellData]() {
        didSet {
            self.output.cellData.accept([ClueDataSource(model: "", items: self.data)])
        }
    }
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init(clue: ClueModel) {
        updateUI(with: clue)
    }
    
    // 새로운 초기화 메서드 추가
    init(coordinate: CLLocationCoordinate2D) {
        // 좌표만으로 새 단서를 만드는 경우
        
    }
    
    // 오늘 남긴 단서 표시
    init() {
        fetchCluesData()
    }
    
    private func updateUI(with clue: ClueModel) {
        // Firebase 이미지 다운로드
        downloadImage(from: clue.image) { [weak self] image in
            guard let self else { return }
            DispatchQueue.main.async {
                if let image = image {
                    self.data.append(ClueCellData(image: image, content: clue.content))
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
        self.images.removeAll()
        
        FirestoreManager.shared.fetchDocuments(collection: "clues",
                                               whereField: "userID",
                                               isEqualTo: userId,
                                               orderBy: "date",
                                               type: ClueModel.self)
        .flatMap { [weak self] clue in
            let now = Date()
            let calendar = Calendar.current
            
            let start = calendar.startOfDay(for: now)
            guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return Single<([ClueModel], [UIImage])>.just(([], []))}
            
            let clue = clue.filter {
                let date = $0.date as Timestamp
                return date.dateValue() >= start && date.dateValue() < end
            }
            
            return Single<([ClueModel], [UIImage])>.create { [weak self] observer in
                clue.forEach {
                    self?.downloadImage(from: $0.image) { image in
                        if let image {
                            self?.images.append(image)
                        } else {
                            self?.images.append(UIImage())
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
            
            print(clues.count)
            print(images.count)
            
            for (clue, image) in zip(clues, images) {
                self.data.append(ClueCellData(image: image, content: clue.content))
            }
        })
        .disposed(by: disposeBag)
    }
}
