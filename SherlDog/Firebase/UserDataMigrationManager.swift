//
//  UserDataMigrationManager.swift
//  SherlDog
//
//  Created by JIN LEE on 11/28/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class UserDataMigrationManager {
    
    static let shared = UserDataMigrationManager()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// 기존 Firebase UID 기반 userId를 AppUserID 기반으로 한 번만 옮겨주는 마이그레이션
    func migrateIfNeeded(firebaseUID: String, completion: @escaping () -> Void) {
        let userDocRef = db.collection(FirestoreCollection.users.rawValue)
            .document(firebaseUID)
        
        userDocRef.getDocument { [weak self] snapshot, error in
            guard let self else { completion(); return }
            
            if let error = error {
                print("🔴 [Migration] users 문서 조회 실패:", error)
                completion()
                return
            }
            
            guard let snapshot = snapshot, var data = snapshot.data() else {
                print("ℹ️ [Migration] users 문서 없음 -> 마이그레이션 스킵")
                completion()
                return
            }
            
            // 이미 마이그레이션 한 유저라면 종료
            if let migrated = data["isUserIdMigrated"] as? Bool, migrated == true {
                print("✅ [Migration] 이미 마이그레이션 완료된 유저")
                completion()
                return
            }
            
            // provider 확인 (카카오 유저만 처리)
            guard let provider = data["provider"] as? String, provider == "kakao" else {
                print("ℹ️ [Migration] 카카오 유저가 아님 -> 스킵")
                completion()
                return
            }
            
            // kakaoId 가져오기 (Int / Int64 / String 등 형 변환 방어)
            let kakaoIdValue = data["kakaoId"]
            let kakaoIdString: String?
            
            if let id = kakaoIdValue as? Int64 {
                kakaoIdString = String(id)
            } else if let id = kakaoIdValue as? Int {
                kakaoIdString = String(id)
            } else if let id = kakaoIdValue as? String {
                kakaoIdString = id
            } else {
                kakaoIdString = nil
            }
            
            guard let kakaoIdString else {
                print("🔴 [Migration] kakaoId 없음 -> 마이그레이션 불가")
                completion()
                return
            }
            
            // 🔑 여기서 AppUserID 생성 (프로젝트에 이미 있는 헬퍼 사용)
            let appUserId: String
            if let kakaoInt64 = Int64(kakaoIdString) {
                appUserId = AppUserID.fromKakaoID(kakaoInt64)
            } else {
                // 문자열이지만 Int64로 변환 불가한 경우에도 안전하게 fallback
                appUserId = "kakao:" + kakaoIdString
            }
            
            // users 문서에 appUserId 및 마이그레이션 플래그 저장
            var newFields: [String: Any] = [
                "appUserId": appUserId,
                "isUserIdMigrated": true
            ]
            
            // 혹시 나중을 위해 "legacyUID" 같은 것도 남겨두고 싶으면:
            if data["legacyFirebaseUID"] == nil {
                newFields["legacyFirebaseUID"] = firebaseUID
            }
            
            userDocRef.setData(newFields, merge: true)
            
            // 🔐 세션에도 AppUserID 반영
            AuthSession.setAppUserId(appUserId)
            
            // 실제 컬렉션들 마이그레이션
            self.migrateCollections(firebaseUID: firebaseUID, appUserId: appUserId) {
                print("✅ [Migration] 모든 컬렉션 마이그레이션 완료")
                completion()
            }
        }
    }
    
    /// userId == firebaseUID 로 저장돼 있던 문서들을 userId == appUserId 로 업데이트
    private func migrateCollections(firebaseUID: String,
                                    appUserId: String,
                                    completion: @escaping () -> Void) {
        
        let group = DispatchGroup()
        
        // 멍탐정 프로필
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.petProfile.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        // 조수 프로필
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.humanProfile.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        // 남긴 단서
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.clues.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        // 커뮤니티 - 탐정 메이트
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.detectiveMate.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        // 커뮤티니 - 수사일지
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.invLogBoard.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        // 신고 기록
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.reportLog.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        // 전체 수사일지
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.walkResult.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        group.enter()
        migrateUserId(
            collection: FirestoreCollection.users.rawValue,
            from: firebaseUID,
            to: appUserId
        ) {
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
    
    /// 특정 컬렉션에서 userId == from 인 문서들을 userId == to 로 업데이트
    private func migrateUserId(collection: String,
                               from oldUserId: String,
                               to newUserId: String,
                               completion: @escaping () -> Void) {
        
        let query = db.collection(collection)
            .whereField("userId", isEqualTo: oldUserId)
        
        query.getDocuments { snapshot, error in
            if let error = error {
                print("🔴 [Migration] \(collection) 조회 실패:", error)
                completion()
                return
            }
            
            guard let documents = snapshot?.documents, !documents.isEmpty else {
                print("ℹ️ [Migration] \(collection) 에서 옮길 문서 없음")
                completion()
                return
            }
            
            let batch = self.db.batch()
            documents.forEach { doc in
                batch.updateData(["userId": newUserId], forDocument: doc.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    print("🔴 [Migration] \(collection) 마이그레이션 실패:", error)
                } else {
                    print("✅ [Migration] \(collection) \(documents.count)개 문서 userId -> \(newUserId)")
                }
                completion()
            }
        }
    }
}
