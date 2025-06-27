import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth
import RxSwift

class FirebaseImageManager {
    static let shared = FirebaseImageManager()
    private let storage = Storage.storage()
    private let storageRef: StorageReference

    private init() {
        storageRef = storage.reference()
    }

    // MARK: - Type지정 Upload
    func uploadImage(_ image: UIImage, type: UploadImageFor, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        // 타임스탬프로 유니크한 파일명 생성
        let timestamp = Int(Date().timeIntervalSince1970)
        let imagePath = "\(type)/\(userId)/\(type)_\(timestamp).jpg"
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

    // MARK: - 펫 이미지 업로드
    func uploadPetImage(_ image: UIImage,
                        petId: String,
                        completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        let imagePath = "pets/\(userId)/\(petId)/profile.jpg"
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
                } else if let downloadURL = url?.absoluteString {
                    completion(.success(downloadURL))
                } else {
                    completion(.failure(ImageError.urlGenerationFailed))
                }
            }
        }
    }
    // MARK: - WalkResult 이미지 업로드 (타임스탬프 포함)
    func uploadWalkResultImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let imagePath = "walkResult/\(userId)/walkResult_\(timestamp).jpg"
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
    
    // MARK: - Clue 이미지 업로드 (타임스탬프 포함)
    func uploadClueImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let imagePath = "clue/\(userId)/clue_\(timestamp).jpg"
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
    
    // MARK: - InvLog 이미지 업로드 (타임스탬프 포함)
    func uploadInvLogImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData))
            return
        }

        let timestamp = Int(Date().timeIntervalSince1970)
        let imagePath = "invLog/\(userId)/invLog_\(timestamp).jpg"
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
    
    // MARK: - 이미지 다운로드
    func downloadImage(userId: String, type: UploadImageFor, completion: @escaping (UIImage?) -> Void) {
        let imagePath = "\(type)/\(userId)/\(type).jpg"
        let imageRef = storageRef.child(imagePath)
    
        imageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let _ = error {
                completion(nil)
                return
            }

            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }

    // MARK: - 펫 이미지 다운로드
    func downloadPetImage(petId: String, userId: String, completion: @escaping (UIImage?) -> Void) {
        let imagePath = "pets/\(userId)/\(petId)/profile.jpg"
        let imageRef = storageRef.child(imagePath)
    
        imageRef.getData(maxSize: 5 * 1024 * 1024) { data, error in
            if let error = error {
                completion(nil)
                return
            }

            if let data = data, let image = UIImage(data: data) {
                completion(image)
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: - 이미지 삭제
    func deleteImage(urlString: String) -> Completable {
        return Completable.create { completable in
            let storageRef = Storage.storage().reference(forURL: urlString)
            
            storageRef.delete { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            }
            
            return Disposables.create()
        }
        
    }

}

// MARK: - UploadType
enum UploadImageFor {
    case assistant, clue, invLog, walkResult

    var type: String {
        switch self {
        case .assistant: return "assistant"
        case .clue: return "clue"
        case .invLog: return "invLog"
        case .walkResult: return "walkResult"
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
