//
//  FirebaseImageManager.swift
//  SherlDog
//
//  Created by 최영락 on 6/17/25.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth

class FirebaseImageManager {
    static let shared = FirebaseImageManager()
    private let storage = Storage.storage()
    private let storageRef: StorageReference
    
    private init() {
        storageRef = storage.reference()
    }
    
    // MARK: - 이미지 업로드
    func uploadPetImage(_ image: UIImage,
                       petId: String,
                       completion: @escaping (Result<String, Error>) -> Void) {
        
        // 이미지를 JPEG 데이터로 변환 (압축률 0.8)
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }
        
        // 파일 경로 설정: pets/{userId}/{petId}/profile.jpg
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        let imagePath = "pets/\(userId)/\(petId)/profile.jpg"
        let imageRef = storageRef.child(imagePath)
        
        // 메타데이터 설정
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        // 업로드 실행
        let uploadTask = imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // 다운로드 URL 가져오기
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let downloadURL = url?.absoluteString {
                    completion(.success(downloadURL))
                } else {
                    completion(.failure(ImageError.urlGenerationFailed))
                }
            }
        }
    }
}

// MARK: - Custom Errors
enum ImageError: Error, LocalizedError {
    case invalidImageData
    case urlGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "이미지 데이터가 유효하지 않습니다."
        case .urlGenerationFailed:
            return "다운로드 URL 생성에 실패했습니다."
        }
    }
}
