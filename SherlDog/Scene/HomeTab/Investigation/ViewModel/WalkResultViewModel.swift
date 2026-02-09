//
//  WalkResultViewModel.swift
//  SherlDog
//
//  Created by JIN LEE on 2/6/26.
//

import UIKit
import RxSwift
import RxCocoa
import FirebaseFirestore
import FirebaseAuth

final class WalkResultViewModel {
    private let disposeBag = DisposeBag()

    let saveResult = PublishSubject<Result<Void, Error>>()

    func uploadWalkingPathImageAndSaveResult(
        image: UIImage,
        session: WalkSession.State,
        selectedProfiles: [PetProfile]
    ) {
        FirebaseImageManager.shared.uploadImage(image, type: .walkResult) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let urlString):
                self.saveWalkResult(
                    session: session,
                    selectedProfiles: selectedProfiles,
                    walkingPathImageURL: urlString
                )
            case .failure(let error):
                self.saveResult.onNext(.failure(error))
            }
        }
    }

    func saveWalkResult(
        session: WalkSession.State,
        selectedProfiles: [PetProfile],
        walkingPathImageURL: String
    ) {
        let userId = Auth.auth().currentUser?.uid ?? "anonymous"
        let profileIds = selectedProfiles.map { $0.petProfileId }

        let endDate = session.endDate ?? Date()
        let dateString = DateFormatter.yyyyMMdd.string(from: endDate)

        let newWalkResult = WalkResult(
            userId: userId,
            petProfileId: profileIds,
            date: dateString,
            distance: session.distanceMeters,
            duration: formatDuration(seconds: session.elapsedSeconds),
            steps: session.steps,
            walkingPathImage: walkingPathImageURL,
            createdAt: Timestamp(date: Date())
        )

        FirestoreManager.shared.createDocument(collection: .walkResult, data: newWalkResult)
            .subscribe(
                onCompleted: { [weak self] in self?.saveResult.onNext(.success(())) },
                onError: { [weak self] error in self?.saveResult.onNext(.failure(error)) }
            )
            .disposed(by: disposeBag)
    }

    private func formatDuration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
