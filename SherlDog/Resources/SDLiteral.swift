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
    }
    
    enum LoginView {
        static let helloLabelLarge: String = "반가워요!"
        static let helloLabelSmall: String = "멍탐정과 함께 오늘의 수사를 시작해볼까요?"
        static let loginErrorMessageTitle: String = "로그인 실패"
        static let loginErrorMessage: String = "다시 로그인 해주세요!"
    }
    
    enum UserProfileViewController {
        static let navigationTitle: String = "프로필"
        static let navigationBackButtonImage: String  = "chevron.backward"
        static let navigationMoreButtonImage: String = "ellipsis"
        static let assistantNickNameLabel: String = "닉네임"
        static let postCollectionButtonTitle: String = "작성 글 둘러보기"
        static let postCollectionButtonImage: String = "note"
    }
}
