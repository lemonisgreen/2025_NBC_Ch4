//
//  FireStoreManager.swift
//  SherlDog
//
//  Created by JIN LEE on 6/16/25.
//

import Foundation
import FirebaseFirestore
import RxSwift

enum FirestoreError: Error {
    case unknown
    case noData
}

final class FirestoreManager {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    private init() {}
}
// MARK: - 기본 쿼리 및 CRUD 메서드
extension FirestoreManager {
    
    //단일 문서 가져오기
    func fetchDocument<T: Decodable>(
        collection: String,
        documentId: String,
        type: T.Type
    ) -> Single<T> {
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

    // whereField 단일조건 쿼리
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

    // 컬렉션 가져오기
    func fetchCollection<T: Decodable>(
        collection: String,
        type: T.Type
    ) -> Single<[T]> {
        return Single.create { [weak self] single in
            self?.db.collection(collection)
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
        collection: String,
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
            self.db.collection(collection)
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

    //문서 생성
    func createDocument<T: Encodable>(
        collection: String,
        data: T,
        documentId: String? = nil
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            let docRef: DocumentReference = documentId != nil ?
                self.db.collection(collection).document(documentId!) :
                self.db.collection(collection).document()
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

    //문서 삭제
    func deleteDocument(
        collection: String,
        documentId: String
    ) -> Completable {
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

    //내부: 날짜 day -> Timestamp (시작/끝)
    private func timestampOfDay(day: Date) -> (start: Timestamp, end: Timestamp) {
        let startOfDay = Calendar.current.startOfDay(for: day)
        guard let endOfday = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) else {
            return (Timestamp(), Timestamp())
        }
        return (Timestamp(date: startOfDay), Timestamp(date: endOfday))
    }
}

// MARK: - 특정 목적별 메서드
extension FirestoreManager {

    //오늘의 내 단서 목록 가져오기
    func fetchCluesForDay(userId: String, day: Date) -> Single<[ClueModel]> {
        return fetchDocumentsForDay(
            collection: "clues",
            whereField: "userID",
            isEqualTo: userId,
            orderBy: "date",
            day: day,
            type: ClueModel.self
        )
    }

    //산책 결과 가져오기
    func fetchWalkResults(userId: String) -> Single<[WalkResult]> {
        return fetchDocuments(
            collection: "WalkResult",
            whereField: "userId",
            isEqualTo: userId,
            type: WalkResult.self
        )
    }

    //선택된 펫 프로필들 한 번에 가져오기
    func fetchSelectedPetProfiles(petProfileIds: [String]) -> Single<[PetProfile]> {
        // 여러개를 병렬로 fetch해서 배열로 합치기
        let singles = petProfileIds.map {
            fetchDocument(collection: "PetProfile", documentId: $0, type: PetProfile.self)
        }
        return Single.zip(singles)
    }

    //내 펫 전체 프로필 가져오기
    func fetchUserPetProfiles(userId: String) -> Single<[PetProfile]> {
        return fetchDocuments(
            collection: "PetProfile",
            whereField: "userId",
            isEqualTo: userId,
            type: PetProfile.self
        )
    }

    //휴먼 프로필 가져오기
    func fetchHumanProfile(userId: String) -> Single<HumanProfileModel> {
        return fetchDocument(
            collection: "HumanProfile",
            documentId: userId,
            type: HumanProfileModel.self
        )
    }

    //단일 펫프로필 ID로 문서 가져오기 (ex. ID로 새 프로필 추가)
    func fetchPetProfileById(petProfileId: String) -> Single<PetProfile> {
        return fetchDocument(
            collection: "PetProfile",
            documentId: petProfileId,
            type: PetProfile.self
        )
    }
    
    func fetchCluesForUser(userId: String) -> Single<[ClueModel]> {
        return fetchDocuments(
            collection: "clues",
            whereField: "userID",
            isEqualTo: userId,
            type: ClueModel.self
        )
    }
}
