//
//  TestDataCleaner.swift
//  SherlDog
//
//  Created by JIN LEE on 12/2/25.
//

#if DEBUG
import Foundation
import FirebaseFirestore

final class TestDataCleaner {
    
    static let shared = TestDataCleaner()
    private init() {}
    
    private let db = Firestore.firestore()
    
    /// 특정 kakaoId로 생성된 테스트 데이터들을 싹 정리
    func deleteAllData(forKakaoId kakaoId: Int64, completion: @escaping () -> Void) {
        print("🧹 [Cleaner] Start for kakaoId:", kakaoId)
        
        // 1) users 에서 kakaoId == 값 인 문서들 찾기
        db.collection(FirestoreCollection.users.rawValue)
            .whereField("kakaoId", isEqualTo: kakaoId)
            .getDocuments { [weak self] snapshot, error in
                guard let self else { completion(); return }
                
                if let error = error {
                    print("❌ [Cleaner] users 조회 실패:", error)
                    completion()
                    return
                }
                
                guard let docs = snapshot?.documents, !docs.isEmpty else {
                    print("ℹ️ [Cleaner] 해당 kakaoId의 users 문서 없음")
                    completion()
                    return
                }
                
                // 이 kakaoId로 생긴 Firebase UID / appUserId 모으기
                let firebaseUIDs = docs.map { $0.documentID }
                let appUserIds = docs.compactMap { $0.data()["userId"] as? String }
                
                print("🧹 [Cleaner] 대상 UID들:", firebaseUIDs)
                print("🧹 [Cleaner] 대상 AppUserID들:", appUserIds)
                
                // users 문서들 삭제
                self.deleteUsersDocuments(docs: docs) {
                    // 나머지 컬렉션들 삭제
                    self.cleanOtherCollections(
                        firebaseUIDs: firebaseUIDs,
                        appUserIds: appUserIds,
                        completion: completion
                    )
                }
            }
    }
    
    // MARK: - users 삭제
    
    private func deleteUsersDocuments(docs: [QueryDocumentSnapshot],
                                      completion: @escaping () -> Void) {
        let batch = db.batch()
        docs.forEach { batch.deleteDocument($0.reference) }
        
        batch.commit { error in
            if let error = error {
                print("❌ [Cleaner] users 삭제 실패:", error)
            } else {
                print("✅ [Cleaner] users 문서 삭제 완료 (\(docs.count)개)")
            }
            completion()
        }
    }
    
    // MARK: - 다른 컬렉션들 삭제
    
    private func cleanOtherCollections(firebaseUIDs: [String],
                                       appUserIds: [String],
                                       completion: @escaping () -> Void) {
        
        let group = DispatchGroup()
        let allIds = firebaseUIDs + appUserIds
        
        // PetProfile / HumanProfile : userId 필드
        group.enter()
        deleteByUserIdField(
            collection: .petProfile,
            fieldName: "userId",
            userIds: allIds
        ) { group.leave() }
        
        group.enter()
        deleteByUserIdField(
            collection: .humanProfile,
            fieldName: "userId",
            userIds: allIds
        ) { group.leave() }
        
        // WalkResult / clues : userID (대문자 D) 필드
        group.enter()
        deleteByUserIdField(
            collection: .walkResult,
            fieldName: "userID",
            userIds: allIds
        ) { group.leave() }
        
        group.enter()
        deleteByUserIdField(
            collection: .clues,
            fieldName: "userID",
            userIds: allIds
        ) { group.leave() }
        
        // ReportLog : reporterId / targetUserId
        group.enter()
        deleteByUserIdField(
            collection: .reportLog,
            fieldName: "reporterId",
            userIds: allIds
        ) { group.leave() }
        
        group.enter()
        deleteByUserIdField(
            collection: .reportLog,
            fieldName: "targetUserId",
            userIds: allIds
        ) { group.leave() }
        
        // BlockLog 도 필요하면 여기 추가 (필드명에 맞게 수정)
        // group.enter()
        // deleteByUserIdField(
        //     collection: .blockLog,
        //     fieldName: "blockerId",   // TODO: 실제 필드명으로 변경
        //     userIds: allIds
        // ) { group.leave() }
        
        group.notify(queue: .main) {
            print("✅ [Cleaner] 모든 컬렉션 정리 완료")
            completion()
        }
    }
    
    // userId / userID / reporterId / targetUserId 공통 삭제 함수
    private func deleteByUserIdField(collection: FirestoreCollection,
                                     fieldName: String,
                                     userIds: [String],
                                     completion: @escaping () -> Void) {
        
        guard !userIds.isEmpty else {
            completion()
            return
        }
        
        let group = DispatchGroup()
        
        userIds.forEach { id in
            group.enter()
            db.collection(collection.rawValue)
                .whereField(fieldName, isEqualTo: id)
                .getDocuments { snapshot, error in
                    if let error = error {
                        print("❌ [Cleaner] \(collection.rawValue) (\(fieldName) == \(id)) 조회 실패:", error)
                        group.leave()
                        return
                    }
                    
                    guard let docs = snapshot?.documents, !docs.isEmpty else {
                        group.leave()
                        return
                    }
                    
                    let batch = self.db.batch()
                    docs.forEach { batch.deleteDocument($0.reference) }
                    
                    batch.commit { error in
                        if let error = error {
                            print("❌ [Cleaner] \(collection.rawValue) (\(fieldName)) 삭제 실패:", error)
                        } else {
                            print("✅ [Cleaner] \(collection.rawValue) (\(fieldName) == \(id)) \(docs.count)개 삭제")
                        }
                        group.leave()
                    }
                }
        }
        
        group.notify(queue: .main) {
            completion()
        }
    }
}
#endif
