//
//  SDLiteral.swift
//  SherlDog
//
//  Created by JIN LEE on 8/25/25.
//

enum SDLiteral {
    
    enum CollectionName: String, CaseIterable {
        case users = "users"
        case clues = "clues"
        case humanProfile = "HumanProfile"
        case petProfile = "PetProfile"
        case invLog = "InvLog"
        case walkResult = "WalkResult"
        case detectiveMate = "DetectiveMate"
        case invLogBoard = "InvLogBoard"
    }
    
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
        static let dotdotdot: String = "···"
        static let separateDot: String = " · "
    }
    
    enum AddNewContentView {
        static let title: String = "글 작성"
        static let addButtonTitle: String = "등록"
        static let petSelectHeader: String = "어떤 탐정님이 모집하는 건가요?"
        static let selectedPetNames: String = "%@ 탐정"
        static let textViewPlaceholder: String = "내용을 입력하세요.\n(최대 1000자 입력, 사진 최대 10장 업로드)"
        static let pictureCount: String = "%d/5 장"
    }
}
