//
//  PostMenuManager.swift
//  SherlDog
//
//  Created by 최규현 on 5/30/26.
//

import UIKit
import RxSwift
import RxCocoa

// 셀 메뉴 버튼 타입
enum PostMenuEvent {
    case fix
    case delete(String)
    case report(String)
    case block(String)
    case error
}

final class PostMenuViewModel {

    func handleMenuEvent(
        _ input: Observable<PostMenuEvent>,
        category: Observable<CommunitySectionType>
    ) -> Signal<PostMenuEvent> {
        handleMenuEvent(input, collection: category.map { $0.toFirestoreCollection })
    }

    func handleMenuEvent(
        _ input: Observable<PostMenuEvent>,
        collection: Observable<FirestoreCollection>
    ) -> Signal<PostMenuEvent> {
        input
            .withLatestFrom(collection) { ($0, $1) }
            .flatMap { menu, collection -> Observable<PostMenuEvent> in

                switch menu {
                case .fix:
                    return .just(.fix)

                case .delete(let documentId):
                    return FirestoreManager.shared.deleteDocument(
                        collection: collection,
                        documentId: documentId
                    )
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    .andThen(.just(.delete(documentId)))
                    .catchAndReturn(.error)

                case .report(let documentId):
                    let reportData = BlockModel(
                        collection: collection.rawValue,
                        documentId: documentId
                    )

                    return FirestoreManager.shared.createDocument(
                        collection: .blockLog,
                        data: reportData,
                        documentId: documentId
                    )
                    .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                    .andThen(.just(.report(documentId)))
                    .catchAndReturn(.error)

                case .block(let postUserId):
                    return BlockManager.shared.blockUser(postUserId)
                        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
                        .andThen(.just(.block(postUserId)))
                        .catchAndReturn(.error)

                case .error:
                    return .just(.error)
                }
            }
            .asSignal(onErrorJustReturn: .error)
    }
}

final class PostMenuManager {
    static let shared = PostMenuManager()

    private init() {}

    func isWriter(_ postUserId: String) -> Bool {
        guard let currentUserId = AuthSession.currentAppUserId else { return false }
        return postUserId == currentUserId
    }

    func makeMenu(
        post: CommunityModel,
        category: CommunitySectionType,
        viewController: UIViewController,
        onEvent: @escaping (PostMenuEvent) -> Void
    ) -> UIMenu {
        if isWriter(post.userId) {
            return myPostMenu(
                post: post,
                category: category,
                viewController: viewController,
                onEvent: onEvent
            )
        } else {
            return otherPostMenu(
                post: post,
                category: category,
                viewController: viewController,
                onEvent: onEvent
            )
        }
    }

    func makeMenu(
        clue: ClueModel,
        viewController: UIViewController,
        onEdit: @escaping () -> Void,
        onEvent: @escaping (PostMenuEvent) -> Void
    ) -> UIMenu {
        guard let id = clue.documentId, !id.isEmpty else { return UIMenu(children: []) }
        let fixTitle = String(
            format: SDLiteral.CommunityView.menuButtonTitle,
            SDLiteral.CommunityView.fix
        )
        let deleteTitle = String(
            format: SDLiteral.CommunityView.menuButtonTitle,
            SDLiteral.CommunityView.delete
        )
        let blockTitle = String(
            format: SDLiteral.CommunityView.menuButtonTitle,
            SDLiteral.CommunityView.block
        )
        let reportTitle = String(
            format: SDLiteral.CommunityView.menuButtonTitle,
            SDLiteral.CommunityView.report
        )
        
        
        
        if isWriter(clue.userID) {
            return UIMenu(
                children: [
                    UIAction(title: fixTitle) { _ in onEdit() },
                    UIAction(title: deleteTitle,
                             attributes: .destructive) { [weak viewController] _ in
                    self.showMenuAlert(type: .delete(id), viewController: viewController, onEvent: onEvent)
                }
            ])
        }
        return UIMenu(children: [
            UIAction(title: blockTitle) { [weak viewController] _ in
                self.showMenuAlert(type: .block(clue.userID), viewController: viewController, onEvent: onEvent)
            },
            UIAction(title: reportTitle) { [weak viewController] _ in
                let reportVC = ReportViewController(target: .post(
                    collection: .clues, documentId: id, postUserId: clue.userID
                ))
                reportVC.onReportCompleted = { [weak viewController] in
                    onEvent(.report(id))
                    self.blockMessageAfterReport(userId: clue.userID, viewController: viewController, onEvent: onEvent)
                }
                reportVC.modalPresentationStyle = .pageSheet
                reportVC.isModalInPresentation = true
                reportVC.sheetPresentationController?.detents = [.large()]
                viewController?.present(reportVC, animated: true)
            }
        ])
    }

    private func myPostMenu(
        post: CommunityModel,
        category: CommunitySectionType,
        viewController: UIViewController,
        onEvent: @escaping (PostMenuEvent) -> Void
    ) -> UIMenu {
        let fixAction = UIAction(
            title: String(
                format: SDLiteral.CommunityView.menuButtonTitle,
                SDLiteral.CommunityView.fix
            )
        ) { [weak viewController] _ in
            let editView = AddNewContentViewController(category: category, post: post)
            editView.hidesBottomBarWhenPushed = true
            viewController?.navigationController?.pushViewController(editView, animated: true)
        }

        let deleteAction = UIAction(
            title: String(
                format: SDLiteral.CommunityView.menuButtonTitle,
                SDLiteral.CommunityView.delete
            )
        ) { [weak viewController] _ in
            self.showMenuAlert(
                type: .delete(post.documentId),
                viewController: viewController,
                onEvent: onEvent
            )
        }

        return UIMenu(children: [fixAction, deleteAction])
    }

    private func otherPostMenu(
        post: CommunityModel,
        category: CommunitySectionType,
        viewController: UIViewController,
        onEvent: @escaping (PostMenuEvent) -> Void
    ) -> UIMenu {
        let blockAction = UIAction(
            title: String(
                format: SDLiteral.CommunityView.menuButtonTitle,
                SDLiteral.CommunityView.block
            )
        ) { [weak viewController] _ in
            self.showMenuAlert(
                type: .block(post.userId),
                viewController: viewController,
                onEvent: onEvent
            )
        }

        let reportAction = UIAction(
            title: String(
                format: SDLiteral.CommunityView.menuButtonTitle,
                SDLiteral.CommunityView.report
            )
        ) { [weak viewController] _ in
            self.showMenuAlert(
                type: .report(post.documentId),
                viewController: viewController,
                onEvent: onEvent
            ) { [weak viewController] in
                self.presentReportForPost(
                    post,
                    category: category,
                    viewController: viewController,
                    onEvent: onEvent
                )
            }
        }

        return UIMenu(children: [blockAction, reportAction])
    }
}

extension PostMenuManager {

    private func presentReportForPost(
        _ post: CommunityModel,
        category: CommunitySectionType,
        viewController: UIViewController?,
        onEvent: @escaping (PostMenuEvent) -> Void
    ) {
        let reportVC = ReportViewController(
            target: .post(
                collection: category.toFirestoreCollection,
                documentId: post.documentId,
                postUserId: post.userId
            )
        )

        reportVC.onReportCompleted = { [weak viewController] in
            self.blockMessageAfterReport(
                userId: post.userId,
                viewController: viewController,
                onEvent: onEvent
            )
        }

        reportVC.modalPresentationStyle = .pageSheet
        reportVC.isModalInPresentation = true

        if let sheet = reportVC.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = false
            sheet.preferredCornerRadius = 20
        }

        viewController?.present(reportVC, animated: true)
    }

    private func showMenuAlert(
        type: PostMenuEvent,
        viewController: UIViewController?,
        onEvent: @escaping (PostMenuEvent) -> Void,
        completion: (() -> Void)? = nil
    ) {
        switch type {
        case .fix, .error:
            return
        default:
            break
        }

        let title: String = {
            switch type {
            case .fix:
                return SDLiteral.CommunityView.fix
            case .delete:
                return SDLiteral.CommunityView.delete
            case .report:
                return SDLiteral.CommunityView.report
            case .block:
                return SDLiteral.CommunityView.block
            case .error:
                return SDLiteral.CommunityView.error
            }
        }()

        let alert = CustomAlertViewController(
            message: String(format: SDLiteral.CommunityView.menuAlertMessage, title),
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.AlertMessage.cancel,
                    action: nil
                ),
                CustomAlertViewController.AlertButton(
                    title: title,
                    action: {
                        onEvent(type)
                        completion?()
                    }
                )
            ]
        )

        viewController?.present(alert, animated: true)
    }

    private func blockMessageAfterReport(
        userId: String,
        viewController: UIViewController?,
        onEvent: @escaping (PostMenuEvent) -> Void
    ) {
        let alert = CustomAlertViewController(
            message: String(
                format: SDLiteral.CommunityView.completeAlert,
                SDLiteral.CommunityView.report
            ),
            subMessage: SDLiteral.CommunityView.blockMessageAfterReport,
            buttons: [
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.AlertMessage.cancel,
                    action: nil
                ),
                CustomAlertViewController.AlertButton(
                    title: SDLiteral.CommunityView.block,
                    action: {
                        onEvent(.block(userId))
                    }
                )
            ]
        )

        viewController?.present(alert, animated: true)
    }
}
