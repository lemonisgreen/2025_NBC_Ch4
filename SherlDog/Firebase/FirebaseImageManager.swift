//
//  FirebaseImageManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/10/25.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth
import RxSwift
import os.signpost

// MARK: - UploadType
enum UploadImageType {
    case assistant, clue, invLogBoard, walkResult, petProfile, detectiveMate
    
    var folder: String {
        switch self {
        case .assistant: return "assistant"
        case .clue: return "clue"
        case .invLogBoard: return "invLogBoard"
        case .walkResult: return "walkResult"
        case .petProfile: return "pets"
        case .detectiveMate: return "detectiveMate"
        }
    }
    
    var filePrefix: String {
        switch self {
        case .assistant: return "assistant_"
        case .clue: return "clue_"
        case .invLogBoard: return "invLogBoard_"
        case .walkResult: return "walkResult_"
        case .petProfile: return "profile.jpg"
        case .detectiveMate: return "detectiveMate_"
        }
    }
}

enum ImageError: Error, LocalizedError {
    case invalidImageData
    case urlGenerationFailed
    case noUserId
    case noPetId
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "이미지 데이터가 유효하지 않습니다."
        case .urlGenerationFailed:
            return "다운로드 URL 생성에 실패했습니다."
        case .noUserId:
            return "로그인 정보가 없습니다."
        case .noPetId:
            return "펫 ID가 필요합니다."
        }
    }
}

class FirebaseImageManager {
    static let shared = FirebaseImageManager()
    private let storage = Storage.storage()
    private let storageRef: StorageReference
    
    var userId: String {
        return Auth.auth().currentUser?.uid ?? ""
    }
    
    private init() {
        storageRef = storage.reference()
    }
    
    // MARK: - 공통 업로드
    func uploadImage(
        _ image: UIImage,
        type: UploadImageType,
        petId: String? = nil,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }
        
        let actualUserId = userId
        guard !actualUserId.isEmpty else {
            completion(.failure(ImageError.noUserId))
            return
        }
        
        var imagePath: String
        if type == .petProfile {
            guard let petId = petId else {
                completion(.failure(ImageError.noPetId))
                return
            }
            imagePath = "\(type.folder)/\(actualUserId)/\(petId)/\(type.filePrefix)" // pets/userId/petId/profile.jpg
        } else {
            let uuid = UUID().uuidString
            imagePath = "\(type.folder)/\(userId)/\(type.filePrefix)\(uuid).jpg"
        }
        
        let imageRef = storageRef.child(imagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let downloadUrl = url?.absoluteString {
                    completion(.success(downloadUrl))
                } else {
                    completion(.failure(ImageError.urlGenerationFailed))
                }
            }
        }
    }
    
    // MARK: - 이미지 URL 다운로
    func downloadImageURL(
        userId: String? = nil,
        type: UploadImageType,
        petId: String? = nil,
        completion: @escaping (URL?) -> Void) {
            let actualUserId = userId ?? self.userId
            guard !actualUserId.isEmpty else {
                completion(nil)
                return
            }
            var path: String
            if type == .assistant || type == .clue || type == .invLogBoard || type == .walkResult {
                path = "\(type.folder)/\(actualUserId)"
                completion(nil)
                return
            }
            else if type == .petProfile {
                guard let petId = petId else {
                    completion(nil)
                    return
                }
                path = "pets/\(actualUserId)/\(petId)/profile.jpg"
            } else {
                completion(nil)
                return
            }
            
            let imageRef = storageRef.child(path)
            imageRef.downloadURL { url, error in
                if let _ = error {
                    completion(nil)
                } else {
                    completion(url)
                }
            }
        }
    
    // MARK: - 이미지 삭제
    func deleteImageByURL(_ urlString: String) -> Completable {
        return Completable.create { completable in
            let storageRef = Storage.storage().reference(forURL: urlString)
            storageRef.delete { error in
                if let error = error { completable(.error(error)) }
                else { completable(.completed) }
            }
            return Disposables.create()
        }
    }
}
