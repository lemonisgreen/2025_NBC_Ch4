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
    
    /// 카카오 로그인 직후 호출해서,
    /// 해당 kakaoId 로 과거에 생성된 모든 UID 기반 데이터들을
    /// appUserId 기준으로 업데이트한다.
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
            completion(true) // 이상한 값이면 그냥 할 게 없음
            return
        }
        
        print("🔁 [Migration] 시작 - kakaoId: \(kakaoId), appUserId: \(appUserId)")
        
        // 1) users 컬렉션에서 kakaoId == 현재 kakaoId 인 문서들 조회
        db.collection(FirestoreCollection.users.rawValue)
            .whereField("kakaoId", isEqualTo: kakaoId)
            .getDocuments { [weak self] snapshot, error in
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
                
                // 과거에 이 카카오 계정으로 로그인하면서 생성된 모든 Firebase UID 들
                let legacyUIDs = docs.map { $0.documentID }
                print("🧩 [Migration] legacyUIDs: \(legacyUIDs)")
                
                // 2) users 컬렉션 자체 필드도 appUserId 기준으로 정리
                self.migrateUsersCollection(
                    docs: docs,
                    appUserId: appUserId
                ) { usersSuccess in
                    // 3) 나머지 컬렉션 마이그레이션
                    self.migrateOtherCollections(
                        legacyUIDs: legacyUIDs,
                        appUserId: appUserId
                    ) { othersSuccess in
                        let allSuccess = usersSuccess && othersSuccess
                        print(allSuccess
                              ? "✅ [Migration] 전체 마이그레이션 완료"
                              : "⚠️ [Migration] 일부 마이그레이션 실패")
                        completion(allSuccess)
                    }
                }
            }
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
            // 필요하면 다른 필드도 통일해줄 수 있음
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
        
        /// ✅ 여기서 마이그레이션할 컬렉션 + 필드 이름을 정의
        /// 실제 Firestore 모델에 맞게 필드명을 확인해서 필요하면 수정해줘야 함!
        let config: [(FirestoreCollection, [String])] = [
            (.petProfile, ["userId"]),
            (.walkResult, ["userID", "userId"]),
            (.clues, ["userID", "userId"]),
            (.reportLog, ["reporterId", "targetUserId"]),
            (.blockLog, ["blockerId", "blockedId"]),
            // 필요하다면 아래처럼 DetectiveMate / InvLogBoard 도 추가 가능
            // (.detectiveMate, ["ownerId", "participantId"]),
            // (.invLogBoard, ["writerId"])
        ]
        
        for (collection, fields) in config {
            for field in fields {
                for legacyUID in legacyUIDs {
                    group.enter()
                    
                    db.collection(collection.rawValue)
                        .whereField(field, isEqualTo: legacyUID)
                        .getDocuments { snapshot, error in
                            
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
                        }
                }
            }
        }
        
        group.notify(queue: .main) {
            completion(allSuccess)
        }
    }
}
