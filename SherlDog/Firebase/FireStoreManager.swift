//
//  FireStoreManager.swift
//  SherlDog
//
//  Created by JIN LEE on 6/16/25.
//

import Foundation
import FirebaseFirestore
import RxSwift

final class FirestoreManager {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    private init() {}
}

extension FirestoreManager {
    /// 새 문서 생성 (자동 UID)
    func createDocument<T: Encodable>(collection: String, data: T, documentId: String? = nil) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            let docRef: DocumentReference
            if let documentId = documentId {
                docRef = self.db.collection(collection).document(documentId)
            } else {
                docRef = self.db.collection(collection).document()
            }
            do {
                try docRef.setData(from: data) { error in
                    if let error = error {
                        completable(.error(error))
                    } else {
                        completable(.completed)
                    }
                }
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
    }
    
    /// 단일 문서 읽기
    func fetchDocument<T: Decodable>(collection: String, documentId: String, type: T.Type) -> Single<T> {
        return Single.create { [weak self] single in
            self?.db.collection(collection).document(documentId).getDocument { snapshot, error in
                if let error = error {
                    single(.failure(error))
                } else if let snapshot = snapshot, let data = try? snapshot.data(as: T.self) {
                    single(.success(data))
                } else {
                    single(.failure(FirestoreError.noData))
                }
            }
            return Disposables.create()
        }
    }
    
    /// 원하는 문서만 선별적으로 읽기
    func fetchDocuments<T: Decodable>(
        collection: String,
        whereField field: String,
        isEqualTo value: Any,
        type: T.Type
    ) -> Single<[T]> {
        return Single.create { [weak self] single in
            self?.db.collection(collection)
                .whereField(field, isEqualTo: value)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(error))
                    } else if let snapshot = snapshot {
                        let items: [T] = snapshot.documents.compactMap { try? $0.data(as: T.self) }
                        single(.success(items))
                    } else {
                        single(.failure(FirestoreError.noData))
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 원하는 문서의 도큐멘트 아이디 가져오기
    func findDocumentId(
        collection: String,
        whereField field: String,
        isEqualTo value: Any
    ) -> Single<[String]> {
        return Single.create { [weak self] single in
            self?.db.collection(collection)
                .whereField(field, isEqualTo: value)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(error))
                    } else if let snapshot = snapshot {
                        let items: [String] = snapshot.documents.compactMap { $0.documentID }
                        single(.success(items))
                    } else {
                        single(.failure(FirestoreError.noData))
                    }
                }
            return Disposables.create()
        }
    }
    
    /// 컬렉션 전체 읽기
    func fetchCollection<T: Decodable>(collection: String, type: T.Type) -> Single<[T]> {
        return Single.create { [weak self] single in
            self?.db.collection(collection).getDocuments { snapshot, error in
                if let error = error {
                    single(.failure(error))
                } else if let snapshot = snapshot {
                    let items: [T] = snapshot.documents.compactMap { try? $0.data(as: T.self) }
                    single(.success(items))
                } else {
                    single(.failure(FirestoreError.noData))
                }
            }
            return Disposables.create()
        }
    }
    // 데이터 업데이트
    func updateDocument<T: Codable>(
            collection: String,
            documentId: String,
            data: T
        ) -> Completable {
            return Completable.create { completable in
                do {
                    let encodedData = try Firestore.Encoder().encode(data)
                    
                    self.db.collection(collection)
                        .document(documentId)
                        .updateData(encodedData) { error in
                            if let error = error {
                                completable(.error(error))
                            } else {
                                completable(.completed)
                            }
                        }
                } catch {
                    completable(.error(error))
                }
                
                return Disposables.create()
            }
        }
    
    // 데이터 삭제
    func deleteDocument(collection: String, documentId: String) -> Completable {
        return Completable.create { [weak self] completable in
            self?.db.collection(collection).document(documentId).delete { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    // 특정 사용자의 펫 프로필들 조회
    func fetchUserPetProfiles(userId: String) -> Single<[PetProfile]> {
        return Single.create { [weak self] single in
            self?.db.collection("PetProfile")
                .whereField("userId", isEqualTo: userId)
                .getDocuments { snapshot, error in
                    if let error = error {
                        single(.failure(error))
                    } else if let snapshot = snapshot {
                        let profiles: [PetProfile] = snapshot.documents.compactMap {
                            try? $0.data(as: PetProfile.self)
                        }
                        single(.success(profiles))
                    } else {
                        single(.failure(FirestoreError.noData))
                    }
                }
            return Disposables.create()
        }
    }
}


enum FirestoreError: Error {
    case unknown
    case noData
}
