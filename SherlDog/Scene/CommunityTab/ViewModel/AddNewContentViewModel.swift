//
//  AddNewContentViewModel.swift
//  SherlDog
//
//  Created by 최규현 on 8/7/25.
//

import RxSwift
import RxRelay
import UIKit
import FirebaseFirestore
import FirebaseAuth
import PhotosUI
import RxDataSources
import Differentiator

final class AddNewContentViewModel {
    
    enum Mode {
        case add
        case edit(category: CommunityViewModel.CommunitySectionType, post: CommunityModel)
    }
    
    enum Input {
        case addButtonTap
        case dropdownTap
        case profileSelect([Int])
        case addPicture
        case selectedPictures([PHPickerResult])
        case deleteButtonTap(Int)
        case editCase(category: CommunityViewModel.CommunitySectionType, post: CommunityModel)
    }
    
    struct Output {
        let mode = BehaviorRelay<Mode>(value: .add)
        let petSelectCellData = BehaviorRelay<[PetSelectSection]>(value: [])
        let isExpanded = BehaviorRelay<Bool>(value: false)
        let selectedIndex = BehaviorRelay<[Int]>(value: [])
        let selectedProfile = BehaviorRelay<[PetProfile]>(value: [])
        let selectedImageIdentifiers = BehaviorRelay<[String]>(value: [])
        let isLoading = BehaviorRelay<Bool>(value: false)
        let maxPictureCount: Int = 5
        let openAlbum = PublishRelay<Void>()
        let picturesCellDisplay = BehaviorRelay<[UIImage]>(value: [])
        let existingImages = BehaviorRelay<[UIImage]>(value: [])
        let existingImageURLs = BehaviorRelay<[String]>(value: [])
        let newPictures = BehaviorRelay<[UIImage]>(value: [])
        let uploadComplete = PublishRelay<Void>()
        let error = PublishRelay<String>()
    }
    
    struct PetSelectItem<Base>: IdentifiableType, Equatable {
        let base: Base
        var identity = UUID()
        
        static func == (lhs: AddNewContentViewModel.PetSelectItem<Base>, rhs: AddNewContentViewModel.PetSelectItem<Base>) -> Bool {
            lhs.identity == rhs.identity
        }
    }
    
    typealias PetSelectSection = AnimatableSectionModel<String, PetSelectItem<PetProfile>>
    
    let text = BehaviorRelay<String>(value: "")
    var dataBox = [PetSelectSection]()
    private var imagesForEdit: [UIImage] = []
    
    private let disposeBag = DisposeBag()
    
    let input = PublishRelay<Input>()
    let output = Output()
    
    init() {
        transform()
        bindPetSelectSections()
        fetchProfiles()
    }
    
    private func transform() {
        self.input
            .bind(onNext: { [weak self] input in
                guard let self else { return }
                
                switch input {
                case .addButtonTap:
                    self.output.isLoading.accept(true)
                    switch self.output.mode.value {
                    case .add:
                        self.addPost()               // 기존 업로드 로직 유지
                    case let .edit(category, post):
                        self.updatePost(category: category, post: post) // 새로운 업데이트 로직
                    }
                    
                case .dropdownTap:
                    let isExpanded = !output.isExpanded.value
                    self.output.isExpanded.accept(isExpanded)
                    
                case .profileSelect(let rows):
                    let petSelectCellData = dataBox.flatMap { $0.items.map { $0.base } }
                    let selectedPets = rows.map { petSelectCellData[$0] }
                    
                    self.output.selectedIndex.accept(rows)
                    self.output.selectedProfile.accept(selectedPets)
                    
                case .addPicture:
                    self.output.openAlbum.accept(())
                    
                case .selectedPictures(let results):
                    self.loadOrderedImages(from: results)
                        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                        .subscribe(onSuccess: { [weak self] images in
                            guard let self else { return }
                            // 전시용 리스트에 append (원본 유지)
                            let updatedDisplay = self.output.existingImages.value + images
                            self.output.picturesCellDisplay.accept(updatedDisplay)
                            
                            // 업데이트 로직에서만 사용할 신규 업로드 버퍼
                            self.output.newPictures.accept(images)
                        })
                        .disposed(by: disposeBag)
                    
                case .deleteButtonTap(let row):
                    self.deletePicture(row: row)
                    
                case let .editCase(category, post):
                    self.output.mode.accept(.edit(category: category, post: post))
                    
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setEditMode(category: CommunityViewModel.CommunitySectionType, post: CommunityModel) {
        self.output.isLoading.accept(true)
        
        let petData = self.dataBox
            .flatMap { $0.items.map { $0.base } }
        let petIds = petData.map(\.petProfileId)
        let selectedPetIds = post.petProfile.map { $0.petProfileId }
        
        let selectedIndex: [Int] = petIds.enumerated()
            .compactMap { (index, id) in selectedPetIds.contains(id) ? index : nil }
        
        self.output.selectedIndex.accept(selectedIndex)
        self.output.selectedProfile.accept(selectedIndex.map { petData[$0] })
        self.output.existingImageURLs.accept(post.contentImage)
        self.text.accept(post.content)

        // 원본 이미지 다운로드 및 보관
        self.downloadImages(post.contentImage)
            .do(onSuccess: { [weak self] images in
                guard let self else { return }
                self.output.existingImages.accept(images)
                let display = images + self.output.newPictures.value
                self.output.picturesCellDisplay.accept(display)
            })
            .subscribe(onSuccess: { [weak self] _ in
                self?.output.isLoading.accept(false)
            }, onFailure: { [weak self] error in
                self?.output.isLoading.accept(false)
                self?.output.error.accept(error.localizedDescription)
            })
            .disposed(by: disposeBag)
    }
    
    private func downloadImages(_ urlStrings: [String]) -> Single<[UIImage]> {
        // 빈 배열이면 바로 성공
        guard !urlStrings.isEmpty else { return .just([]) }
        
        return Observable.from(urlStrings)
            .compactMap { URL(string: $0) }
            .flatMap { url -> Observable<UIImage> in
                let request = URLRequest(url: url)
                return URLSession.shared.rx.data(request: request)
                    .compactMap { UIImage(data: $0) } // 실패 이미지는 걸러냄
            }
            .toArray() // Single<[UIImage]>
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
    }
    
    private func deletePicture(row: Int) {
        var display = self.output.picturesCellDisplay.value
        guard row >= 0, row < display.count else { return }

        let existingCount = self.output.existingImages.value.count

        if row < existingCount {
            // 원본 삭제: UI/URL 상태 정리
            var originals = self.output.existingImages.value
            var urls = self.output.existingImageURLs.value
            originals.remove(at: row)
            if row < urls.count { urls.remove(at: row) }
            self.output.existingImages.accept(originals)
            self.output.existingImageURLs.accept(urls)
        } else {
            // 신규 삭제: 업로드 버퍼 정리
            let idx = row - existingCount
            var news = self.output.newPictures.value
            var ids = self.output.selectedImageIdentifiers.value
            if idx >= 0 && idx < news.count { news.remove(at: idx) }
            if idx >= 0 && idx < ids.count { ids.remove(at: idx) }
            self.output.newPictures.accept(news)
            self.output.selectedImageIdentifiers.accept(ids)
        }

        display.remove(at: row)
        self.output.picturesCellDisplay.accept(display)
    }
    
    private func bindPetSelectSections() {
        Observable
            .combineLatest(self.output.isExpanded, self.output.selectedProfile)
            .map { [weak self] isExpanded, profiles -> [PetSelectSection] in
                guard let self = self else { return [] }
                if isExpanded {
                    // 펼침: 보유한 전체 섹션 스냅샷을 그대로 노출
                    return self.dataBox
                    
                } else {
                    // 접힘: 헤더만 남기고 아이템은 비움. 선택된 프로필 이름을 헤더에 표시
                    let names = profiles.map(\.name).joined(separator: " ")
                    let title = names.isEmpty
                    ? SDLiteral.AddNewContentView.petSelectHeader
                    : String(format: SDLiteral.AddNewContentView.selectedPetNames, names)
                    
                    return [PetSelectSection(model: title, items: [])]
                    
                }
            }
            .observe(on: MainScheduler.asyncInstance)
            .bind(to: self.output.petSelectCellData)
            .disposed(by: self.disposeBag)
    }
    
    private func loadOrderedImages(from results: [PHPickerResult]) -> Single<[UIImage]> {
        // 사진 고유 ID 추출
        let ids = results.compactMap { $0.assetIdentifier }
        guard !ids.isEmpty else { return .just([]) }
        self.output.selectedImageIdentifiers.accept(ids)
        
        // ids 배열 순서대로 PHAsset을 담은 PHFetchResult 가져오기
        let fetched = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        
        // 사용자가 선택한 ID 순서대로 PHAsset 배열 복원
        var dics: [String: PHAsset] = [:]
        fetched.enumerateObjects { asset, _, _ in
            dics[asset.localIdentifier] = asset
        }
        
        let assetsInOrder = ids.compactMap { dics[$0] }
        
        // 각 PHAsset → 이미지 Single로 변환
        let imageSingles: [Single<UIImage?>] = assetsInOrder.map { asset in
            Single<UIImage?>.create { observer in
                let option = PHImageRequestOptions()
                option.isNetworkAccessAllowed = true
                option.deliveryMode = .highQualityFormat
                
                PHImageManager.default().requestImageDataAndOrientation(for: asset, options: option) { data, _, _, _ in
                    observer(.success(data.flatMap { UIImage(data: $0) }))
                }
                return Disposables.create()
            }
        }
        
        return Single.zip(imageSingles)
            .map { $0.compactMap { $0 } }   // nil 제거
    }
    
    private func addPost() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let selectedPets = self.output.selectedProfile.value
        
        uploadImage()
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapCompletable { [weak self] urls in
                guard let self else { return Completable.error(NSError(domain: "", code: 0, userInfo: nil)) }
                
                let uploadData = CommunityModel(userId: userId,
                                                petProfile: selectedPets,
                                                postDate: Timestamp(date: Date()),
                                                contentImage: urls,
                                                content: self.text.value)
                
                return FirestoreManager.shared.createDocument(collection: .detectiveMate,
                                                              data: uploadData)
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            }
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                self.output.isLoading.accept(false)
                self.output.uploadComplete.accept(())
                
            }, onError: { [weak self] error in
                self?.output.error.accept(error.localizedDescription)
                self?.output.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    private func updatePost(category: CommunityViewModel.CommunitySectionType, post: CommunityModel) {
        uploadNewImages(category: category)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapCompletable { [weak self] newURLs in
                guard let self,
                      let userId = Auth.auth().currentUser?.uid,
                      let collection = self.getCollection(category) else {
                    return .error(FirestoreError.unknown)
                }
                // 기존 URL + 신규 URL 합치기
                let merged = self.output.existingImageURLs.value + newURLs
                let selectedPets = self.output.selectedProfile.value

                let updated = CommunityModel(
                    userId: userId,
                    petProfile: selectedPets,
                    postDate: post.postDate,
                    contentImage: merged,
                    content: self.text.value,
                    like: post.like,
                    previewComment: post.previewComment,
                    postCode: post.postCode
                )

                // 동일 문서 id에 덮어쓰기
                return FirestoreManager.shared.findDocumentId(collection: collection,
                                                              whereField: SDLiteral.CommunityView.postCode,
                                                              isEqualTo: post.postCode)
                .flatMapCompletable { ids in
                    guard let id = ids.first else { return .error(FirestoreError.unknown) }
                    
                    return FirestoreManager.shared.updateDocument(collection: collection,
                                                                   documentId: id,
                                                                   data: updated)
                }
                .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            }
            .subscribe(onCompleted: { [weak self] in
                guard let self else { return }
                self.output.isLoading.accept(false)
                self.output.uploadComplete.accept(())
            }, onError: { [weak self] error in
                self?.output.error.accept(error.localizedDescription)
                self?.output.isLoading.accept(false)
            })
            .disposed(by: disposeBag)
    }
    
    private func uploadImage() -> Single<[String]> {
        let images = self.output.picturesCellDisplay.value
        
        let uploads: [Single<String>] = images.map { image in
            Single<String>.create { observer in
                FirebaseImageManager.shared.uploadImage(image,
                                                        type: .detectiveMate) { result in
                    switch result {
                    case .success(let imageUrl):
                        observer(.success(imageUrl))
                    case .failure(let error):
                        observer(.failure(error))
                    }
                }
                return Disposables.create()
            }
        }
        
        return Single.zip(uploads)
        
    }
    
    private func uploadNewImages(category: CommunityViewModel.CommunitySectionType) -> Single<[String]> {
        let images = self.output.newPictures.value
        guard !images.isEmpty else { return .just([]) }
        let uploadType: UploadImageType = category == .invLogBoard ? .invLogBoard : .detectiveMate
        
        let uploads: [Single<String>] = images.map { image in
            Single<String>.create { observer in
                FirebaseImageManager.shared.uploadImage(image, type: uploadType) { result in
                    switch result {
                    case .success(let imageUrl):
                        observer(.success(imageUrl))
                    case .failure(let error):
                        observer(.failure(error))
                    }
                }
                return Disposables.create()
            }
        }
        return Single.zip(uploads)
    }
    
    private func fetchProfiles() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        FirestoreManager.shared.fetchQuery(FirestoreQuery<PetProfile>(
            collection: .petProfile,
            type: .whereField(field: SDLiteral.FirestoreFieldName.userId, value: userId)
        ))
            .map { profile in
                // UI 섹션으로 매핑
                let box: [PetSelectItem] = profile.map { PetSelectItem(base: $0) }
                
                return [PetSelectSection(model: SDLiteral.AddNewContentView.petSelectHeader, items: box)]
            }
            .subscribe(onSuccess: { [weak self] sections in
                self?.dataBox = sections
                
                // 프로필 섹션이 로드된 뒤, 편집 모드라면 선택 상태를 적용
                if case let .edit(category, post) = self?.output.mode.value {
                    self?.setEditMode(category: category, post: post)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func getCollection(_ category: CommunityViewModel.CommunitySectionType) -> FirestoreCollection? {
        if let collection = FirestoreCollection.allCases.filter({ category.collectionName == $0.rawValue }).first {
            return collection
        } else {
            return nil
        }
    }
    
    private func setAgeGenderStyle(data: PetProfile) -> String {
        let age = data.age
        let formatter = DateFormatter.yyyyMMdd
        guard let ageDate = formatter.date(from: age) else { return "알 수 없음" }
        
        return "\(ageFinder(dateOfBirth: ageDate)) \(genderFinder(gender: data.gender))"
    }
    
    private func ageFinder(dateOfBirth: Date) -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        
        if let year = components.year, year > 0 {
            return "\(year)세"
            
        } else if let month = components.month, month > 0 {
            return "\(month)개월"
            
        } else {
            return "신생아"
            
        }
    }
    
    private func genderFinder(gender: String) -> String {
        switch gender {
        case "male": return "남아"
        case "female": return "여아"
        default: return "알 수 없음"
        }
    }
}
