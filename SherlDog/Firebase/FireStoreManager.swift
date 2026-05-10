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

struct FirestoreQuery<T: Decodable> {
    let collection: FirestoreCollection
    let type: FirestoreQueryType
    let modelType: T.Type = T.self
}

enum FirestoreCollection: String, CaseIterable {
    case users = "users"
    case clues = "clues"
    case humanProfile = "HumanProfile"
    case petProfile = "PetProfile"
    case walkResult = "WalkResult"
    case detectiveMate = "DetectiveMate"
    case invLogBoard = "InvLogBoard"
    case blockLog = "BlockLog"
    case reportLog = "ReportLog"
}

enum FirestoreQueryType {
    case document(id: String)
    case whereField(field: String, value: Any?)
    case collection(sortField: String?, descending: Bool, blockedIds: [String])
    case clue(before: Int, bounds: (s: Double, w: Double, n: Double, e: Double))
}

final class FirestoreManager {
    static let shared = FirestoreManager()
    let db = Firestore.firestore()
    
    var userId: String {
        return AuthSession.currentAppUserId ?? ""
    }
    
    private init() {}
    
    private func getActualValue<T>(field: String, value: Any?) -> T? {
        if let val = value as? T {
            return val
        }
        if value == nil && field == "userId", T.self == String.self {
            return userId as? T
        }
        return nil
    }
    
    func fetchQuery<T>(_ query: FirestoreQuery<T>) -> Single<[T]> {
        switch query.type {
            
        case let .document(id):
            let documentId = (id.isEmpty && !userId.isEmpty) ? userId : id
            
            return Single.create { [weak self] single in
                self?.db.collection(query.collection.rawValue).document(documentId).getDocument { snapshot, error in
                    if let error = error { single(.failure(error)) }
                    else if let snapshot = snapshot, let data = try? snapshot.data(as: T.self) { single(.success([data])) }
                    else if let snapshot, snapshot.exists == false { single(.success([])) }
                    else { single(.failure(NSError(domain: "NoData", code: -1))) }
                }
                return Disposables.create()
            }
            
        case let .whereField(field, value):
            let actualValue: Any
            if value == nil && field == "userId" {
                actualValue = userId
            } else {
                guard let castedValue: Any = getActualValue(field: field, value: value) else {
                    return Single.error(FirestoreError.noData)
                }
                actualValue = castedValue
            }
            
            return Single.create { [weak self] single in
                self?.db.collection(query.collection.rawValue)
                    .whereField(field, isEqualTo: actualValue)
                    .getDocuments { snapshot, error in
                        if let error = error { single(.failure(error)) }
                        else if let snapshot = snapshot {
                            let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
                            single(.success(items))
                        } else { single(.failure(NSError(domain: "NoData", code: -1))) }
                    }
                return Disposables.create()
            }
            
        case let .collection(sortField, descending, blocked):
            return Single.create { [weak self] single in
                guard let self else {
                    single(.failure(FirestoreError.unknown))
                    return Disposables.create()
                }
                var queryByCollection: Query = self.db.collection(query.collection.rawValue)
                
                if let sortField, !sortField.isEmpty {
                    queryByCollection = queryByCollection.order(by: sortField, descending: descending)
                }
                
                if !blocked.isEmpty {
                    queryByCollection = queryByCollection.whereField(SDLiteral.FirestoreFieldName.userId, notIn: blocked)
                }
                
                queryByCollection
                    .getDocuments { snapshot, error in
                        if let error = error { single(.failure(error)) }
                        else if let snapshot = snapshot {
                            let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
                            single(.success(items))
                        } else { single(.failure(NSError(domain: "NoData", code: -1))) }
                    }
                return Disposables.create()
            }
            
        case let .clue(before, bounds):
            let (start, end) = Self.timestampOfDay(day: Date(), before: before)
            let field = ClueModel.CodingKeys.self
            
            return Single.create { [weak self] single in
                self?.db.collection(query.collection.rawValue)
                    .whereField(field.date.rawValue, isGreaterThanOrEqualTo: start)
                    .whereField(field.date.rawValue, isLessThan: end)
                    .whereField(field.latitude.rawValue, isGreaterThan: bounds.s)
                    .whereField(field.longitude.rawValue, isGreaterThan: bounds.w)
                    .whereField(field.latitude.rawValue, isLessThan: bounds.n)
                    .whereField(field.longitude.rawValue, isLessThan: bounds.e)
                    .getDocuments { snapshot, error in
                        if let error = error { single(.failure(error)) }
                        else if let snapshot = snapshot {
                            let items = snapshot.documents.compactMap { try? $0.data(as: T.self) }
                            single(.success(items))
                        } else { single(.failure(NSError(domain: "NoData", code: -1))) }
                    }
                return Disposables.create()
            }
        }
    }
    
    // 원하는 문서의 도큐멘트 아이디 가져오기
    func findDocumentId(
        collection: FirestoreCollection,
        whereField field: String = "userId",
        isEqualTo value: Any? = nil
    ) -> Single<[String]> {
        let actualValue: Any
        if value == nil && field == "userId" {
            actualValue = userId
        } else if let value = value {
            actualValue = value
        } else {
            return Single.error(FirestoreError.noData)
        }
        
        return Single.create { [weak self] single in
            self?.db.collection(collection.rawValue)
                .whereField(field, isEqualTo: actualValue)
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
            
            let collection: CollectionReference = self.db.collection(collection.rawValue)
            let docRef: DocumentReference = (documentId == nil || documentId!.isEmpty)
            ? collection.document()
            : collection.document(documentId!)
            
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
    func updateDocument<T: Encodable>(
        collection: FirestoreCollection,
        documentId: String?,
        data: T
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            let docId = (documentId == nil || documentId!.isEmpty) ? self.userId : documentId!
            
            do {
                let encoded = try Firestore.Encoder().encode(data)
                let ref = self.db.collection(collection.rawValue).document(docId)
                
                ref.updateData(encoded) { error in
                    if let ns = error as NSError? {
                        if ns.domain == FirestoreErrorDomain,
                           ns.code == FirestoreErrorCode.notFound.rawValue {
                            ref.setData(encoded, merge: true) { setErr in
                                if let setErr = setErr { completable(.error(setErr)) }
                                else { completable(.completed) }
                            }
                        } else {
                            completable(.error(ns))
                        }
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
        documentId: String?
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self = self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            let docId = (documentId == nil || documentId!.isEmpty) ? self.userId : documentId!
            self.db.collection(collection.rawValue).document(docId).delete { error in
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
    static func timestampOfDay(day: Date, before: Int) -> (start: Timestamp, end: Timestamp) {
        let day = day.addingTimeInterval(TimeInterval(-1 * before * 24 * 60 * 60))
        
        let startOfDay = Calendar.current.startOfDay(for: day)
        let today = Calendar.current.startOfDay(for: Date())
        guard let endOfday = Calendar.current.date(byAdding: .day, value: 1, to: today) else {
            return (Timestamp(), Timestamp())
        }
        return (Timestamp(date: startOfDay), Timestamp(date: endOfday))
    }
}
