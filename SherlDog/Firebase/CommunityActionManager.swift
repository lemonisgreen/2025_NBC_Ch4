//
//  CommunityActionManager.swift
//  SherlDog
//
//  Created by 최규현 on 9/15/25.
//

import FirebaseAuth
import FirebaseFirestore
import RxSwift

final class CommunityActionManager {
    static let shared = CommunityActionManager()
    
    enum CommunityAction: String {
        case like = "like"
        case comment = "comment"
    }
    
    private let db = Firestore.firestore()
    private let myUserId = Auth.auth().currentUser?.uid ?? ""
    
    private init() {}
}

// MARK: - Method
extension CommunityActionManager {
    
    // Like 추가, 제거
    func toggleLikeWithCount(collection: FirestoreCollection, postCode: String) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            
            let postRef = self.db
                .collection(collection.rawValue)
                .document(postCode)
            
            let likeRef = postRef
                .collection(CommunityAction.like.rawValue)
                .document(self.myUserId)
            
            self.db.runTransaction({ transaction, _ -> Any? in
                let likeSnap = try? transaction.getDocument(likeRef)

                if likeSnap?.exists == true {
                    transaction.deleteDocument(likeRef)
                    transaction.updateData(["likeCount": FieldValue.increment(Int64(-1))], forDocument: postRef)
                } else {
                    transaction.setData([:], forDocument: likeRef)
                    transaction.updateData(["likeCount": FieldValue.increment(Int64(1))], forDocument: postRef)
                }
                return nil
            }) { _, error in
                if let error {
                    completable(.error(error))
                } else {
                    completable(.completed)
                }
            }
            return Disposables.create()
        }
    }
    
    // Like state observer
    func observeIsLiked(collection: FirestoreCollection, postCode: String, userId: String) -> Observable<Bool> {
        let doc = self.db
            .collection(collection.rawValue)
            .document(postCode)
            .collection(CommunityActionManager.CommunityAction.like.rawValue)
            .document(userId)

        return Observable.create { observable in
            let listener = doc.addSnapshotListener { snapshot, _ in
                if let snapshot {
                    observable.onNext(snapshot.exists)
                } else {
                    observable.onError(FirestoreError.unknown)
                }
            }
            
            return Disposables.create { listener.remove() }
        }
    }
    
    // Like count observer
    func observeLikeCount(
        collection: FirestoreCollection,
        postCode: String
    ) -> Observable<Int> {
        let doc = self.db
            .collection(collection.rawValue)
            .document(postCode)

        return Observable.create { observable in
            let listener = doc.addSnapshotListener { snapshot, _ in
                let count = (snapshot?.data()?["likeCount"] as? Int) ?? 0
                observable.onNext(count)
            }
            return Disposables.create { listener.remove() }
        }
    }
    
    // Create Comment
    func createComment<T: Codable>(
        collection: FirestoreCollection,
        postCode: String,
        data: T
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            
            do {
                try self.db.collection(collection.rawValue)
                    .document(postCode)
                    .collection(CommunityAction.comment.rawValue)
                    .document()
                    .setData(from: data) { error in
                        if let error {
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
    
    // Delete Comment
    func deleteComment(
        collection: FirestoreCollection,
        postCode: String,
        commentDocumentId: String
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db.collection(collection.rawValue)
                .document(postCode)
                .collection(CommunityAction.comment.rawValue)
                .document(commentDocumentId)
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
    
    // Like list 불러오기
    func fetchLikersList(
        collection: FirestoreCollection,
        postCode: String
    ) -> Single<[String]> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db
                .collection(collection.rawValue)
                .document(postCode)
                .collection(CommunityAction.like.rawValue)
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

    // 코멘트 리스트 불러오기
    func fetchCommentsList<T: Codable>(
        collection: FirestoreCollection,
        postCode: String
    ) -> Single<[T]> {
        return Single.create { [weak self] single in
            guard let self else {
                single(.failure(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db
                .collection(collection.rawValue)
                .document(postCode)
                .collection(CommunityAction.comment.rawValue)
                .getDocuments() { snapshot, error in
                    if let snapshot {
                        single(.success(snapshot.documents.compactMap { try? $0.data(as: T.self) }))
                    } else if let error {
                        single(.failure(error))
                    } else {
                        single(.failure(FirestoreError.noData))
                    }
                }
            
            return Disposables.create()
        }
    }
    
    // comment 수정
    func updateComment(
        collection: FirestoreCollection,
        postCode: String,
        commentDocumentId: String,
        text: String
    ) -> Completable {
        return Completable.create { [weak self] completable in
            guard let self else {
                completable(.error(FirestoreError.unknown))
                return Disposables.create()
            }
            
            self.db.collection(collection.rawValue)
                .document(postCode)
                .collection(CommunityAction.comment.rawValue)
                .document(commentDocumentId)
                .updateData(["text": text]) { error in // FIXME: "text"를 commentModel의 내용을 담은 프로퍼티 이름으로 변경
                    if let error {
                        completable(.error(error))
                    } else {
                        completable(.completed)
                    }
                }
            
            
            return Disposables.create()
        }
    }
    
}
