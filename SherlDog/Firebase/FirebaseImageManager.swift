import UIKit
import Firebase
import FirebaseStorage
import FirebaseAuth
import RxSwift

// MARK: - UploadType
enum UploadImageType {
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

final class FirebaseImageManager {
    static let shared = FirebaseImageManager()
    private let storage = Storage.storage()
    private let storageRef: StorageReference
    
    private init() {
        storageRef = storage.reference()
    }
}

// MARK: - 기본(generic) 이미지 업로드/다운로드/삭제

extension FirebaseImageManager {
    // 임의의 경로에 이미지 업로드 (generic)
    func uploadImageToPath(_ image: UIImage, path: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            completion(.failure(ImageError.invalidImageData)); return
        }
        let imageRef = storageRef.child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        imageRef.putData(imageData, metadata: metadata) { _, error in
            if let error = error { completion(.failure(error)); return }
            imageRef.downloadURL { url, error in
                if let error = error { completion(.failure(error)) }
                else if let downloadUrl = url?.absoluteString { completion(.success(downloadUrl)) }
                else { completion(.failure(ImageError.urlGenerationFailed)) }
            }
        }
    }
    
    // 임의의 경로에 있는 이미지 다운로드 (downloadURL 리턴)
    func downloadImageURL(path: String, completion: @escaping (URL?) -> Void) {
        let imageRef = storageRef.child(path)
        imageRef.downloadURL { url, error in
            if let _ = error {
                completion(nil)  // 에러 발생 시 nil 반환
            } else {
                completion(url)  // 성공 시 URL 반환
            }
        }
    }
    
    // 이미지 삭제
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

// MARK: - 목적별(semantic) 이미지 작업 함수
extension FirebaseImageManager {
    
    /// assistant 이미지 업로드
    func uploadAssistantImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData)); return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "assistant/\(userId)/assistant_\(timestamp).jpg"
        uploadImageToPath(image, path: path, completion: completion)
    }
    
    /// clue 이미지 업로드
    func uploadClueImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData)); return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "clue/\(userId)/clue_\(timestamp).jpg"
        uploadImageToPath(image, path: path, completion: completion)
    }
    
    /// invLog 이미지 업로드
    func uploadInvLogImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData)); return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "invLog/\(userId)/invLog_\(timestamp).jpg"
        uploadImageToPath(image, path: path, completion: completion)
    }
    
    /// walkResult 이미지 업로드
    func uploadWalkResultImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData)); return
        }
        let timestamp = Int(Date().timeIntervalSince1970)
        let path = "walkResult/\(userId)/walkResult_\(timestamp).jpg"
        uploadImageToPath(image, path: path, completion: completion)
    }
    
    /// 펫 프로필 이미지 업로드
    func uploadPetImage(_ image: UIImage, petId: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(ImageError.invalidImageData)); return
        }
        let path = "pets/\(userId)/\(petId)/profile.jpg"
        uploadImageToPath(image, path: path, completion: completion)
    }
    
    /// 펫 프로필 이미지 URL(다운로드) 얻기
    func getPetImageURL(petId: String, userId: String, completion: @escaping (URL?) -> Void) {
        let path = "pets/\(userId)/\(petId)/profile.jpg"
        downloadImageURL(path: path, completion: completion)
    }
}
