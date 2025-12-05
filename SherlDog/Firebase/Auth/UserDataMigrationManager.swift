//
//  UserDataMigrationManager.swift
//  SherlDog
//
//  Created by JIN LEE on 11/28/25.
//

import Foundation
import FirebaseFirestore

/// 1.0.2 시절 "UID 기반" 데이터들을
/// 새 버전의 AppUserID기반으로 옮겨주는 마이그레이션 매니저

final class UserDataMigrationManager {
    
    static let shared = UserDataMigrationManager()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// 카카오 로그인 직후 호출 -> 해당 kakaoId 로 과거에 생성된 모든 UID 기반 데이터들을 appUserId 기준으로 업데이트
    ///
    /// - Parameters:
    ///   - kakaoId: Kakao SDK 에서 받은 카카오 유저 ID (예: 4303230810)
    ///   - appUserId: "kakao:\(kakaoId)" 형태의 앱 기준 사용자 ID
    ///   - completion: 전체 마이그레이션 성공 여부
    
    func migrateAfterKakaoLogin(
        kakaoId: Int64,
        appUserId: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard kakaoId != 0, !appUserId.isEmpty else {
            completion(true)
            return
        }
        
        print("🔁 [Migration] 시작 - kakaoId: \(kakaoId), appUserId: \(appUserId)")
        
        // 1) users 컬렉션에서 kakaoId == 현재 kakaoId 인 문서들 조회
        db.collection(FirestoreCollection.users.rawValue)
            .whereField("kakaoId", isEqualTo: kakaoId)
            .getDocuments(completion: { [weak self] snapshot, error in
                guard let self else {
                    completion(false)
                    return
                }
                
                if let error = error {
                    print("❌ [Migration] users 조회 실패: \(error)")
                    completion(false)
                    return
                }
                
                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    print("ℹ️ [Migration] kakaoId \(kakaoId)에 해당하는 기존 users 문서 없음")
                    completion(true)
                    return
                }
                
                let legacyUIDs = docs.map { $0.documentID }
                print("🧩 [Migration] legacyUIDs: \(legacyUIDs)")
                
                self.migrateUsersCollection(
                    docs: docs,
                    appUserId: appUserId
                ) { usersSuccess in
                    
                    self.migrateOtherCollections(
                        legacyUIDs: legacyUIDs,
                        appUserId: appUserId
                    ) { othersSuccess in
                        
                        self.migrateHumanProfileDocuments(
                            legacyUIDs: legacyUIDs,
                            appUserId: appUserId
                        ) { humanSuccess in
                            
                            let allSuccess = usersSuccess && othersSuccess && humanSuccess
                            print(allSuccess
                                  ? "✅ [Migration] 전체 마이그레이션 완료"
                                  : "⚠️ [Migration] 일부 마이그레이션 실패")
                            completion(allSuccess)
                        }
                    }
                }
            })
    }
    
    // MARK: - users 컬렉션 마이그레이션
    
    /// users 문서들에 userId 필드를 appUserId로 맞춰주는 작업
    private func migrateUsersCollection(
        docs: [QueryDocumentSnapshot],
        appUserId: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !docs.isEmpty else {
            completion(true)
            return
        }
        
        let batch = db.batch()
        docs.forEach { doc in
            var data: [String: Any] = [
                "userId": appUserId,
                "provider": "kakao",
                "lastLoginAt": FieldValue.serverTimestamp()
            ]
            batch.updateData(data, forDocument: doc.reference)
        }
        
        batch.commit { error in
            if let error = error {
                print("❌ [Migration] users 컬렉션 업데이트 실패: \(error)")
                completion(false)
            } else {
                print("✅ [Migration] users 컬렉션 userId 업데이트 완료")
                completion(true)
            }
        }
    }
    
    // MARK: - 나머지 컬렉션 마이그레이션
    
    /// petProfile / walkResult / clues / reportLog / blockLog 등의
    /// userId / userID / reporterId / targetUserId 등을 UID -> appUserId 로 변경
    private func migrateOtherCollections(
        legacyUIDs: [String],
        appUserId: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !legacyUIDs.isEmpty else {
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        var allSuccess = true
        
        let config: [(FirestoreCollection, [String])] = [
            (.petProfile, ["userId"]),
            (.walkResult, ["userID", "userId"]),
            (.clues, ["userID", "userId"]),
            (.reportLog, ["reporterId", "targetUserId"]),
            (.blockLog, ["blockerId", "blockedId"]),
            (.detectiveMate, ["ownerId", "participantId"]),
            //(.invLogBoard, ["writerId"])
        ]
        
        for (collection, fields) in config {
            for field in fields {
                for legacyUID in legacyUIDs {
                    group.enter()
                    
                    db.collection(collection.rawValue)
                        .whereField(field, isEqualTo: legacyUID)
                        .getDocuments(completion: { snapshot, error in
                            
                            if let error = error {
                                print("❌ [Migration] \(collection.rawValue) 조회 실패 (\(field) == \(legacyUID)): \(error)")
                                allSuccess = false
                                group.leave()
                                return
                            }
                            
                            guard let docs = snapshot?.documents, !docs.isEmpty else {
                                group.leave()
                                return
                            }
                            
                            let batch = self.db.batch()
                            docs.forEach { doc in
                                batch.updateData([field: appUserId], forDocument: doc.reference)
                            }
                            
                            batch.commit { error in
                                if let error = error {
                                    print("❌ [Migration] \(collection.rawValue) 업데이트 실패 (\(field) == \(legacyUID)): \(error)")
                                    allSuccess = false
                                } else {
                                    print("✅ [Migration] \(collection.rawValue).\(field) \(legacyUID) → \(appUserId), \(docs.count)개 문서 업데이트")
                                }
                                group.leave()
                            }
                        })
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
    
    // MARK: - HumanProfile 마이그레이션 (docID 기반)
    private func migrateHumanProfileDocuments(
        legacyUIDs: [String],
        appUserId: String,
        completion: @escaping (Bool) -> Void
    ) {
        guard !legacyUIDs.isEmpty else {
            completion(true)
            return
        }
        
        let group = DispatchGroup()
        var allSuccess = true
        
        for legacyUID in legacyUIDs {
            group.enter()
            
            // 예전: HumanProfile/{legacyUID}
            let oldRef = db.collection(FirestoreCollection.humanProfile.rawValue)
                .document(legacyUID)
            
            oldRef.getDocument(completion: { [weak self] snapshot, error in
                guard let self else {
                    allSuccess = false
                    group.leave()
                    return
                }
                
                if let error = error {
                    print("❌ [Migration] HumanProfile 조회 실패 (\(legacyUID)): \(error)")
                    allSuccess = false
                    group.leave()
                    return
                }
                
                guard let snapshot = snapshot, snapshot.exists,
                      let data = snapshot.data() else {
                    // 이 UID로 휴먼프로필이 없으면 그냥 패스
                    group.leave()
                    return
                }
                
                // 새: HumanProfile/{appUserId}
                let newRef = self.db.collection(FirestoreCollection.humanProfile.rawValue)
                    .document(appUserId)
                
                newRef.setData(data, merge: true) { error in
                    if let error = error {
                        print("❌ [Migration] HumanProfile 복사 실패 (\(legacyUID) → \(appUserId)): \(error)")
                        allSuccess = false
                        group.leave()
                        return
                    }
                    
                    print("✅ [Migration] HumanProfile \(legacyUID) → \(appUserId) 복사 완료")
                    group.leave()
                }
            })
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
}
