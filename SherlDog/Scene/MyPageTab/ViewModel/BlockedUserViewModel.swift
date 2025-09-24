//
//  BlockedUserViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 9/17/25.
//

import Foundation
import RxSwift
import RxCocoa

final class BlockedUserViewModel {
    let blockedUserIds = BehaviorRelay<[String]>(value: [])
    let blockedProfiles = BehaviorRelay<[HumanProfileModel]>(value: [])
    let selectedIndexes = BehaviorRelay<Set<Int>>(value: [])
    let isEditingMode = BehaviorRelay<Bool>(value: false)
    let errorMessage = PublishSubject<String>()
    
    private let disposeBag = DisposeBag()
    
    init() {
        fetchBlockedUsers()
    }
    
    func fetchBlockedUsers() {
        BlockManager.shared.fetchBlockedUserIds()
            .subscribe(onSuccess: { [weak self] ids in
                self?.blockedUserIds.accept(ids)
                self?.fetchBlockedProfiles(ids: ids)
            }, onFailure: { [weak self] error in
                self?.errorMessage.onNext("차단 사용자 불러오기 실패: \(error.localizedDescription)")
                self?.blockedUserIds.accept([])
                self?.blockedProfiles.accept([])
            })
            .disposed(by: disposeBag)
    }
    
    func fetchBlockedProfiles(ids: [String]) {
        guard !ids.isEmpty else {
            blockedProfiles.accept([])
            return
        }
        
        let profileObservables = ids.map { id in
            BlockManager.shared.fetchUserProfile(userId: id)
                .asObservable()
                .catchAndReturn(HumanProfileModel(nickname: "Unknown", image: "", introduce: ""))
        }
        
        Observable.zip(profileObservables)
            .subscribe(onNext: { [weak self] profiles in
                self?.blockedProfiles.accept(profiles)
            })
            .disposed(by: disposeBag)
    }
    
    func toggleSelection(row: Int) {
        var selected = selectedIndexes.value
        if selected.contains(row) {
            selected.remove(row)
        } else {
            selected.insert(row)
        }
        selectedIndexes.accept(selected)
    }
    
    func unblockSelectedUsers() {
        let indexes = selectedIndexes.value.sorted()
        let idsToUnblock = indexes.compactMap { blockedUserIds.value[$0] }
        
        Observable.from(idsToUnblock)
            .flatMap { id in BlockManager.shared.unblockUser(id).asObservable() }
            .ignoreElements()
            .subscribe(onCompleted: { [weak self] in
                self?.fetchBlockedUsers()
                self?.selectedIndexes.accept([])
            })
            .disposed(by: disposeBag)
    }
    
    func setEditing(_ isEditing: Bool) {
        isEditingMode.accept(isEditing)
        if !isEditing {
            selectedIndexes.accept([])
        }
    }
}

