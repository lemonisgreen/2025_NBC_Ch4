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
    private let myUserId = AuthSession.currentAppUserId ?? ""
    private let collectionName = "blockedUsers"
    private let profileCollection = "HumanProfile"
    
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
            
            self.db.collection(FirestoreCollection.users.rawValue)
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
            
            self.db.collection(FirestoreCollection.users.rawValue)
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

    func fetchBlockedUserIds() -> Single<[String]> {
           return Single.create { [weak self] single in
               guard let self else {
                   single(.failure(FirestoreError.unknown))
                   return Disposables.create()
               }

               self.db
                   .collection(FirestoreCollection.users.rawValue)
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
    
// UserId로 assistatnProfile 불러오기
    func fetchUserProfile(userId: String) -> Single<HumanProfileModel> {
        return Single.create { single in
            self.db.collection(self.profileCollection).document(userId)
                .getDocument { snapshot, error in
                    if let error = error {
                        single(.failure(error))
                    } else if let snapshot = snapshot, snapshot.exists,
                              let data = snapshot.data() {
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: data)
                            let profile = try JSONDecoder().decode(HumanProfileModel.self, from: jsonData)
                            single(.success(profile))
                        } catch {
                            single(.failure(error))
                        }
                    } else {
                        single(.failure(FirestoreError.noData))
                    }
                }
            return Disposables.create()
        }
    }
}
