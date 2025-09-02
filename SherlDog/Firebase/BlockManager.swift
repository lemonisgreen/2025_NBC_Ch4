//
//  BlockManager.swift
//  SherlDog
//
//  Created by 최규현 on 9/1/25.
//

import Foundation
import FirebaseFirestore
import RxSwift
import FirebaseAuth

final class BlockManager {
    static let shared = BlockManager()
    
    private let db = Firestore.firestore()
    private let myUserId = Auth.auth().currentUser?.uid ?? ""
    private let collectionName = "blockedUsers"
    
    private init() {}
}
// MARK: - Method
extension BlockManager {
    // 사용자 차단
    func blockUser(_ userId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db.collection(SDLiteral.CollectionName.users.rawValue)
                .document(self.myUserId)
                .collection(self.collectionName)
                .document(userId)
                .setData([:]) { error in
                    if let error {
                        completable(.error(error))
                    } else {
                        completable(.completed)
                    }
                }
            
            return Disposables.create()
        }
    }

    // 차단 해제
    func unblockUser(_ userId: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db.collection(SDLiteral.CollectionName.users.rawValue)
                .document(self.myUserId)
                .collection(self.collectionName)
                .document(userId)
                .delete() { error in
                    if let error {
                        completable(.error(error))
                    } else {
                        completable(.completed)
                    }
                }
            
            return Disposables.create()
        }
    }

    // 차단 목록 불러오기
    func fetchBlockedUsers() -> Single<[String]> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db
                .collection(SDLiteral.CollectionName.users.rawValue)
                .document(self.myUserId)
                .collection(self.collectionName)
                .getDocuments() { snapshot, error in
                    if let snapshot {
                        single(.success(snapshot.documents.map { $0.documentID }))
                    } else if let error {
                        single(.failure(error))
                    } else {
                        single(.failure(FirestoreError.noData))
                    }
                }
            
            return Disposables.create()
        }
    }

}
