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
import os.signpost

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
        let cellData = BehaviorRelay<[ClueDataSource]>(value: [])
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
    init(day: Date) {
        fetchCluesData(day: day)
    }
    
    private func updateUI(with clue: ClueModel) {
        // Firebase 이미지 다운로드
        downloadImage(from: clue.image)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .subscribe(onSuccess: { [weak self] image in
                self?.data.append(ClueCellData(image: image, content: clue.content))
            })
            .disposed(by: disposeBag)
    }
    
    private func downloadImage(from urlString: String) -> Single<UIImage> {
        guard let url = URL(string: urlString) else {
            return .just(UIImage())
        }
        return Single<UIImage>.create { single in
            let log = OSLog(subsystem: "com.rak.SherlDog.imageLoading", category: .pointsOfInterest)
            let signpostID = OSSignpostID(log: log)
            os_signpost(.begin, log: log, name: "단서 이미지 다운로드", signpostID: signpostID)
            
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data, let image = UIImage(data: data) {
                    os_signpost(.end, log: log, name: "단서 이미지 다운로드", signpostID: signpostID)
                    single(.success(image))
                } else {
                    single(.success(UIImage()))
                }
            }.resume()
            
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
    }
    
    private func fetchCluesData(day: Date) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        self.images.removeAll()
        
        FirestoreManager.shared.fetchDocumentsForDay(collection: "clues",
                                                     whereField: "userID",
                                                     isEqualTo: userId,
                                                     orderBy: "date",
                                                     day: day,
                                                     type: ClueModel.self)
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
        .flatMap { clues -> Single<[ClueCellData]> in
            let imageSingles = clues.map { clue in
                self.downloadImage(from: clue.image)
                    .map { ClueCellData(image: $0, content: clue.content) }
            }
            return Single.zip(imageSingles)
        }
        .subscribe(onSuccess: { [weak self] cellDatas in
            guard let self else { return }
            let section = ClueDataSource(model: "", items: cellDatas)
            self.output.cellData.accept(cellDatas.isEmpty ? [] : [section])
        })
        .disposed(by: disposeBag)
    }
}
