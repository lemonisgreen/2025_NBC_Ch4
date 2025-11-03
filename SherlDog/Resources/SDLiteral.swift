//
//  SDLiteral.swift
//  SherlDog
//
//  Created by JIN LEE on 8/25/25.
//

enum SDLiteral {
    
    enum AlertMessage {
        static let confirm = "확인"
        static let cancel = "취소"
        static let album: String = "앨범"
        static let camera: String = "카메라"
        static let permissionDenied: String = "%@ 권한이 필요합니다."
        static let permissionSetting: String = "설정에서 변경해주세요."
        static let moveToSetting: String = "설정으로 이동"
        static let completePost: String = "등록되었습니다."
    }
    
    enum FirestoreFieldName {
        static let userId: String = "userId"
    }
    
    enum LoginView {
        static let helloLabelLarge: String = "반가워요!"
        static let helloLabelSmall: String = "멍탐정과 함께 오늘의 수사를 시작해볼까요?"
        static let loginErrorMessageTitle: String = "로그인 실패"
        static let loginErrorMessage: String = "다시 로그인 해주세요!"
    }
    
    enum CommunityView {
        static let detectiveMateTitle: String = "탐정 메이트"
        static let invLogBoardTitle: String = "수사 게시판"
        static let fix: String = "수정"
        static let delete: String = "삭제"
        static let report: String = "신고"
        static let block: String = "차단"
        static let error: String = "에러"
        static let menuAlertMessage: String = "정말 %@하시겠습니까?"
        static let menuButtonTitle: String = "%@하기"
        static let completeAlert: String = "%@ 완료했습니다."
        static let blockMessageAfterReport: String = "해당 유저를 차단하시겠습니까?"
        static let dotdotdot: String = "···"
        static let separateDot: String = " · "
        static let documentId: String = "documentId"
        static let postDate: String = "postDate"
    }
    
    enum AddNewContentView {
        static let title: String = "글 작성"
        static let titleByEditMode: String = "글 수정"
        static let addButtonTitle: String = "등록"
        static let editButtonTitle: String = "수정"
        static let petSelectHeader: String = "어떤 탐정님이 모집하는 건가요?"
        static let selectedPetNames: String = "%@ 탐정"
        static let textViewPlaceholder: String = "내용을 입력하세요.\n(최대 1000자 입력, 사진 최대 10장 업로드)"
        static let pictureCount: String = "%d/5 장"
    }
    
    enum UserProfileViewController {
        static let navigationTitle: String = "프로필"
        static let navigationBackButtonImage: String  = "chevron.backward"
        static let navigationMoreButtonImage: String = "ellipsis"
        static let assistantNickNameLabel: String = "닉네임"
        static let postCollectionButtonTitle: String = "작성 글 둘러보기"
        static let postCollectionButtonImage: String = "note"
    }
    
    enum InvLogListView {
        static let title: String = "수사일지"
        static let deleteButton: String = "삭제"
        static let deleteComplete: String = "삭제되었습니다."
        static let requestDelete: String = "수사일지를 삭제하시겠습니까?"
        static let requestDeleteWithoutList: String = "선택된 수사일지가 없습니다."
        static let caseNumber: String = "CASE # %@"
        static let infoLabel: String = "%@  ·  %@  ·  %@"
        static let onboardingUserDefaults: String = "needOnboardingInvLogArchive"
    }
    
    enum BlockedUserViewController {
        static let navigationTitle: String = "차단한 사용자 목록"
        static let navigationEditButton: String = "편집"
        static let navigationCancelButton: String = "취소"
        static let navigationUnblockButton: String = "차단 해제"
        static let emptyStateLabel: String = "차단한 사용자가 없습니다."
        static let emptySelectedUnblockUsersAlertText: String = "선택된 차단 유저가 없습니다."
        static let unblcockAlertText: String = "선택한 사용자를\n차단 해제하시겠습니까?"
    }
    
    enum MyPageViewController {
        static let mypageLabel: String = "멍탐정 사무소"
        static let mypageSettingButtonIcon: String = "setting"
        static let assistantButtonTitle: String = "편집"
        static let archiveButtonTitle: String = "수사일지 아카이브"
        static let archiveButtonImage: String = "note"
        static let findMateButtonTitle: String = "탐정메이트 찾기"
        static let findMateButtonImage: String = "search"
    }
    
    enum FindMateViewController {
        static let navigationTitle: String = "내가 쓴 탐정메이트"
    }
}
