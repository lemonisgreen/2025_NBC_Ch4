//
//  FireStoreManager.swift
//  SherlDog
//
//  Created by JIN LEE on 6/16/25.
//

import Foundation
import FirebaseFirestore
import RxSwift
import FirebaseAuth

enum FirestoreError: Error {
    case unknown
    case noData
}

enum FirestoreCollection: String {
    case clues = "clues"
    case walkResult = "WalkResult"
    case petProfile = "PetProfile"
    case humanProfile = "HumanProfile"
    case invLog = "InvLog"
}

final class FirestoreManager {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    
    var userId: String {
           return Auth.auth().currentUser?.uid ?? ""
       }
    
    private init() {}
}
// MARK: - 기본 쿼리 및 CRUD 메서드
extension FirestoreManager {
    
    //단일 문서 가져오기
    func fetchDocument<T: Decodable>(
        collection: FirestoreCollection,
        documentId: String,
        type: T.Type
    ) -> Single<T> {
        return Single.create { [weak self] single in
            self?.db.collection(collection.rawValue).document(documentId).getDocument { snapshot, error in
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

    // whereField 단일조건 쿼리
    func fetchDocuments<T: Decodable>(
        collection: FirestoreCollection,
        whereField field: String,
        isEqualTo value: Any,
        type: T.Type
    ) -> Single<[T]> {
        return Single.create { [weak self] single in
            self?.db.collection(collection.rawValue)
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

    // 컬렉션 가져오기
    func fetchCollection<T: Decodable>(
        collection: FirestoreCollection,
        type: T.Type
    ) -> Single<[T]> {
        return Single.create { [weak self] single in
            self?.db.collection(collection.rawValue)
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

    //날짜 범위 fetch for day
    func fetchDocumentsForDay<T: Decodable>(
        collection: FirestoreCollection,
        whereField field: String,
        isEqualTo value: Any,
        orderBy: String,
        day: Date,
        descending: Bool = false,
        type: T.Type
    ) -> Single<[T]> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(FirestoreError.unknown))
                return Disposables.create()
            }
            let (start, end) = self.timestampOfDay(day: day)
            self.db.collection(collection.rawValue)
                .whereField(field, isEqualTo: value)
                .whereField(orderBy, isGreaterThanOrEqualTo: start)
                .whereField(orderBy, isLessThan: end)
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
    
    // 원하는 문서의 도큐멘트 아이디 가져오기
      func findDocumentId(
          collection: FirestoreCollection,
          whereField field: String,
          isEqualTo value: Any
      ) -> Single<[String]> {
          return Single.create { [weak self] single in
              self?.db.collection(collection.rawValue)
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

    //문서 생성
    func createDocument<T: Encodable>(
        collection: FirestoreCollection,
        data: T,
        documentId: String? = nil
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            let docRef: DocumentReference = documentId != nil ?
            self.db.collection(collection.rawValue).document(documentId!) :
            self.db.collection(collection.rawValue).document()
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

    //문서 수정
    func updateDocument<T: Codable>(
        collection: FirestoreCollection,
        documentId: String,
        data: T
    ) -> Completable {
        return Completable.create { completable in
            do {
                let encodedData = try Firestore.Encoder().encode(data)
                self.db.collection(collection.rawValue)
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

    //문서 삭제
    func deleteDocument(
        collection: FirestoreCollection,
        documentId: String
    ) -> Completable {
        return Completable.create { [weak self] completable in
            self?.db.collection(collection.rawValue).document(documentId).delete { error in
                if let error = error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }

    //내부: 날짜 day -> Timestamp (시작/끝)
    private func timestampOfDay(day: Date) -> (start: Timestamp, end: Timestamp) {
        let startOfDay = Calendar.current.startOfDay(for: day)
        guard let endOfday = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return (Timestamp(), Timestamp())
        }
        return (Timestamp(date: startOfDay), Timestamp(date: endOfday))
    }
}

extension FirestoreManager {
    
    func fetchCluesForDay(userId: String, day: Date) -> Single<[ClueModel]> {
        return fetchDocumentsForDay(
            collection: .clues,
            whereField: "userID",
            isEqualTo: userId,
            orderBy: "date",
            day: day,
            type: ClueModel.self
        )
    }
    
    func fetchWalkResults(userId: String) -> Single<[WalkResult]> {
        return fetchDocuments(
            collection: .walkResult,
            whereField: "userId",
            isEqualTo: userId,
            type: WalkResult.self
        )
    }
    
    func fetchSelectedPetProfiles(petProfileIds: [String]) -> Single<[PetProfile]> {
        let singles = petProfileIds.map {
            fetchDocument(collection: .petProfile, documentId: $0, type: PetProfile.self)
        }
        return Single.zip(singles)
    }
    
    func fetchUserPetProfiles(userId: String) -> Single<[PetProfile]> {
        return fetchDocuments(
            collection: .petProfile,
            whereField: "userId",
            isEqualTo: userId,
            type: PetProfile.self
        )
    }
    
    func fetchHumanProfile(userId: String) -> Single<HumanProfileModel> {
        return fetchDocument(
            collection: .humanProfile,
            documentId: userId,
            type: HumanProfileModel.self
        )
    }
    
    func fetchPetProfileById(petProfileId: String) -> Single<PetProfile> {
        return fetchDocument(
            collection: .petProfile,
            documentId: petProfileId,
            type: PetProfile.self
        )
    }
    
    func fetchCluesForUser(userId: String) -> Single<[ClueModel]> {
        return fetchDocuments(
            collection: .clues,
            whereField: "userID",
            isEqualTo: userId,
            type: ClueModel.self
        )
    }
}
