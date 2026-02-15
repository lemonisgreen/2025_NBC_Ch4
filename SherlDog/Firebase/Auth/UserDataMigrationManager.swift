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
    
    private let kakaoIndexCollection = "kakaoUsers"
    private let targetMigrationVersion = 1
    
    /// kakaoUsers/{kakaoId} upsert + legacyUIDs 누적 + (legacyUIDs, migrationVersion) 반환
    private func upsertKakaoIndexAndFetchState(
        kakaoId: Int64,
        appUserId: String,
        currentFirebaseUID: String?,
        completion: @escaping (_ legacyUIDs: [String], _ migrationVersion: Int, _ error: Error?) -> Void
    ) {
        let ref = db.collection(kakaoIndexCollection).document(String(kakaoId))
        
        db.runTransaction({ txn, errPtr -> Any? in
            let snap: DocumentSnapshot
            do {
                snap = try txn.getDocument(ref)
            } catch {
                errPtr?.pointee = error as NSError
                return nil
            }
            
            var legacyUIDs = (snap.data()?["legacyFirebaseUIDs"] as? [String]) ?? []
            if let uid = currentFirebaseUID, !uid.isEmpty, !legacyUIDs.contains(uid) {
                legacyUIDs.append(uid)
            }
            
            let currentVersion = (snap.data()?["migrationVersion"] as? Int) ?? 0
            
            if snap.exists {
                txn.setData([
                    "appUserId": appUserId,
                    "legacyFirebaseUIDs": legacyUIDs,
                    "lastLoginAt": FieldValue.serverTimestamp()
                ], forDocument: ref, merge: true)
            } else {
                txn.setData([
                    "appUserId": appUserId,
                    "legacyFirebaseUIDs": legacyUIDs,
                    "migrationVersion": 0,
                    "createdAt": FieldValue.serverTimestamp(),
                    "lastLoginAt": FieldValue.serverTimestamp()
                ], forDocument: ref, merge: false)
            }
            
            return [
                "legacyUIDs": legacyUIDs,
                "migrationVersion": currentVersion
            ]
        }) { result, error in
            if let error = error {
                completion([], 0, error)
                return
            }
            let dict = result as? [String: Any]
            let legacy = dict?["legacyUIDs"] as? [String] ?? []
            let version = dict?["migrationVersion"] as? Int ?? 0
            completion(legacy, version, nil)
        }
    }
    
    private func setMigrationDone(kakaoId: Int64) {
        let ref = db.collection(kakaoIndexCollection).document(String(kakaoId))
        ref.setData([
            "migrationVersion": targetMigrationVersion,
            "migratedAt": FieldValue.serverTimestamp()
        ], merge: true)
    }
    
    /// 카카오 로그인 직후 호출 -> 해당 kakaoId 로 과거에 생성된 모든 UID 기반 데이터들을 appUserId 기준으로 업데이트
    ///
    /// - Parameters:
    ///   - kakaoId: Kakao SDK 에서 받은 카카오 유저 ID (예: 4303230810)
    ///   - appUserId: "kakao:\(kakaoId)" 형태의 앱 기준 사용자 ID
    ///   - completion: 전체 마이그레이션 성공 여부
    
    func migrateAfterKakaoLogin(
        kakaoId: Int64,
        appUserId: String,
        currentFirebaseUID: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        guard kakaoId != 0, !appUserId.isEmpty else {
            completion(true)
            return
        }
        
        print("[Migration] 시작 - kakaoId: \(kakaoId), appUserId: \(appUserId)")
        
        // kakaoUsers 인덱스 upsert + 상태 확인
        upsertKakaoIndexAndFetchState(
            kakaoId: kakaoId,
            appUserId: appUserId,
            currentFirebaseUID: currentFirebaseUID
        ) { [weak self] indexLegacyUIDs, migrationVersion, error in
            guard let self else { completion(false); return }
            
            if let error = error {
                print("[Migration] kakaoUsers upsert 실패: \(error)")
                completion(false)
                return
            }
            
            // 이미 한 번 완료된 유저면 스킵
            if migrationVersion >= self.targetMigrationVersion {
                print("[Migration] 이미 완료된 유저 (version: \(migrationVersion)) - 스킵")
                completion(true)
                return
            }
            
            // 1) 기존 방식 유지: users 컬렉션에서 kakaoId로 legacyUIDs 찾기 (업뎃 직후 최초 1회용)
            self.db.collection(FirestoreCollection.users.rawValue)
                .whereField("kakaoId", isEqualTo: kakaoId)
                .getDocuments { [weak self] snapshot, error in
                    guard let self else { completion(false); return }
                    
                    if let error = error {
                        print("[Migration] users 조회 실패: \(error)")
                        completion(false)
                        return
                    }
                    
                    let docs = snapshot?.documents ?? []
                    let legacyFromUsers = docs.map { $0.documentID }
                    
                    // legacyUIDs = (인덱스에 모아둔 것 + users에서 찾은 것) 합집합
                    var legacyUIDs = Array(Set(indexLegacyUIDs + legacyFromUsers))
                    
                    // legacy가 아예 없으면 마이그레이션 할 게 없으니 완료 처리 + 버전 올려서 재실행 방지
                    guard !legacyUIDs.isEmpty else {
                        print("[Migration] legacyUIDs 없음 - 마이그레이션 스킵 & 완료 마킹")
                        self.setMigrationDone(kakaoId: kakaoId)
                        completion(true)
                        return
                    }
                    
                    print("[Migration] legacyUIDs: \(legacyUIDs)")
                    
                    // 1-1) legacyUIDs를 kakaoUsers에 다시 저장(누락 보완)
                    self.db.collection(self.kakaoIndexCollection)
                        .document(String(kakaoId))
                        .setData([
                            "legacyFirebaseUIDs": legacyUIDs,
                            "updatedAt": FieldValue.serverTimestamp()
                        ], merge: true)
                    
                    // 2) 마이그레이션 실행(기존 함수 재사용)
                    self.migrateUsersCollection(docs: docs, appUserId: appUserId) { usersSuccess in
                        self.migrateOtherCollections(legacyUIDs: legacyUIDs, appUserId: appUserId) { othersSuccess in
                            self.migrateHumanProfileDocuments(legacyUIDs: legacyUIDs, appUserId: appUserId) { humanSuccess in
                                
                                let allSuccess = usersSuccess && othersSuccess && humanSuccess
                                print(allSuccess
                                      ? "[Migration] 전체 마이그레이션 완료"
                                      : "[Migration] 일부 마이그레이션 실패")
                                
                                // 성공했을 때만 version 올려서 “최초 1회” 보장
                                if allSuccess {
                                    self.setMigrationDone(kakaoId: kakaoId)
                                }
                                completion(allSuccess)
                            }
                        }
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
            batch.updateData(data, forDocument: doc.reference)
        }
        
        batch.commit { error in
            if let error = error {
                print("[Migration] users 컬렉션 업데이트 실패: \(error)")
                completion(false)
            } else {
                print("[Migration] users 컬렉션 userId 업데이트 완료")
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
            (.blockLog, ["documentId"]),
            (.detectiveMate, ["userId"]),
            (.invLogBoard, ["userId"])
        ]
        
        for (collection, fields) in config {
            for field in fields {
                for legacyUID in legacyUIDs {
                    group.enter()
                    
                    db.collection(collection.rawValue)
                        .whereField(field, isEqualTo: legacyUID)
                        .getDocuments(completion: { snapshot, error in
                            
                            if let error = error {
                                print("[Migration] \(collection.rawValue) 조회 실패 (\(field) == \(legacyUID)): \(error)")
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
                                    print("[Migration] \(collection.rawValue) 업데이트 실패 (\(field) == \(legacyUID)): \(error)")
                                    allSuccess = false
                                } else {
                                    print("[Migration] \(collection.rawValue).\(field) \(legacyUID) → \(appUserId), \(docs.count)개 문서 업데이트")
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
        
        let newRef = db.collection(FirestoreCollection.humanProfile.rawValue).document(appUserId)
        
            newRef.getDocument { [weak self] newSnap, error in
            guard let self else { completion(false); return }
            
            let existing = newSnap?.data() ?? [:]
            
            func hasNonEmptyString(_ key: String) -> Bool {
                guard let s = existing[key] as? String else { return false }
                return !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            
            let protectKeys: Set<String> = [
                // 유저가 수정 가능한 값 및 생성시각 보호
                "nickname", "image", "introduce", "createdAt"
            ]
            
            let shouldProtectNickname = hasNonEmptyString("nickname")
            let shouldProtectImage = hasNonEmptyString("image")
            let shouldProtectIntroduce = hasNonEmptyString("introduce")
            let shouldProtectCreatedAt = (existing["createdAt"] != nil)
            
            for legacyUID in legacyUIDs {
                group.enter()
                
                let oldRef = self.db.collection(FirestoreCollection.humanProfile.rawValue).document(legacyUID)
                oldRef.getDocument { snapshot, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("[Migration] HumanProfile 조회 실패 (\(legacyUID)): \(error)")
                        allSuccess = false
                        return
                    }
                    
                    guard let snapshot = snapshot, snapshot.exists, var data = snapshot.data() else {
                        return
                    }
                    
                    if protectKeys.contains("nickname"), shouldProtectNickname { data.removeValue(forKey: "nickname") }
                    if protectKeys.contains("image"), shouldProtectImage { data.removeValue(forKey: "image") }
                    if protectKeys.contains("introduce"), shouldProtectIntroduce { data.removeValue(forKey: "introduce") }
                    
                    // createdAt 보호(있으면 덮지 않음)
                    if protectKeys.contains("createdAt"), shouldProtectCreatedAt { data.removeValue(forKey: "createdAt") }
                    
                    // 아무 것도 남지 않으면 setData 호출할 필요 없음
                    if data.isEmpty { return }
                    
                    // 3) merge로 비어있는 값만 채움
                    newRef.setData(data, merge: true) { error in
                        if let error = error {
                            print("[Migration] HumanProfile 복사 실패 (\(legacyUID) → \(appUserId)): \(error)")
                            allSuccess = false
                        } else {
                            print("[Migration] HumanProfile \(legacyUID) → \(appUserId) merge 완료")
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                completion(allSuccess)
            }
        }
    }
}
