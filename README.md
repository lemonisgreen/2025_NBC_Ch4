<div align="center">
  <h1>🐾 멍탐정 산책일지</h1>
</div>

![시안 4](https://github.com/user-attachments/assets/e2770dd2-6e2f-402d-a8fb-82c96796d1ec)




> 반려견과 함께하는 특별한 산책 경험을 **탐정 놀이**로 기록하는 산책일지 앱

---

## 📱 프로젝트 소개

**멍탐정 산책일지**는 단순한 산책 기록을 넘어 반려견과의 추억을 특별하게 만드는 앱입니다.  
일상적인 산책을 **탐정 수사**라는 재미있는 컨셉으로 재해석하여,  
반려견을 '멍탐정'으로, 산책로를 '수사 현장'으로,  
특별한 순간들을 '단서'로 기록할 수 있어요.

실시간 GPS 추적과 사진 및 메모 기능을 통해 나만의 산책 스토리를 만들고, 반려견과의 하루를 **작은 모험**으로 만들어보세요.
---

## 🚀 주요 기능

### 🕵️‍♂️ 멍탐정 및 조수 프로필 등록
- 반려견 3마리까지 등록 가능
- 강아지는 '탐정', 사람은 '조수'로 등록
- 다양한 조수 캐릭터 제공
  
  <img src="https://github.com/user-attachments/assets/24c3879b-6dff-4d2f-9ba0-41908ea87013" width="300" />
  <img src="https://github.com/user-attachments/assets/15b77cf0-7728-478f-a6cc-ed7a4e78a13d" width="300" />
  
---

### 🗺 산책 기록 (수사일지)
- 걸음 수, 거리, 시간, GPS 경로 자동 기록
- 지난 산책 기록을 아카이브에서 관리

 <img src="https://github.com/user-attachments/assets/a4cdff5b-69dd-46a9-8f79-b8446a9da2a4" width="300" />
 <img src="https://github.com/user-attachments/assets/c91c2e01-42c9-4633-a408-0403573e6dcc" width="300" />
 
---

### 🔍 단서 남기기
- 산책 중 장소나 순간을 사진·메모로 기록
- 지도에서 다른 유저의 단서도 확인 가능

  <img src="https://github.com/user-attachments/assets/47472df2-f03e-447d-97ca-c844372deffe" width="300" />
 
---

## 🛠 기술 스택

| 범위            | 사용 기술 |
|-----------------|-----------|
| 의존성 관리     | `Swift Package Manager` |
| 형상 관리       | `Git`, `GitHub` |
| 아키텍처        | `MVVM` |
| 디자인 패턴     | `Delegate`, `RxSwift`, `RxDataSources` |
| UI 프레임워크   | `UIKit` |
| 비동기 처리     | `RxSwift`, `RxCocoa`, `RxCoreLocation` |
| 레이아웃        | `SnapKit`, `IQKeyboardManagerSwift` |
| 로컬 저장소     | `UserDefaults` |
| 외부 저장소     | `Firebase Firestore`, `Firebase Storage` |
| 동작 감지       | `CoreMotion` |
| 외부 인증       | `Firebase Auth`, `GoogleSignIn`, `Sign in with Apple`, `KakaoOpenSDK` |
| 지도 서비스     | `NMapsMap`, `NMapsGeometry`, `CoreLocation` |
| 이미지 처리     | `URLSession` |
| 네트워킹        | `URLSession` |
| 커밋 컨벤션     | `Conventional Commits` |

---

## ⚙️ 기술적 의사결정

- **MVVM**: UI와 비즈니스 로직 분리, 테스트 및 유지보수 용이
- **RxSwift**: 비동기 흐름을 효율적으로 처리하며 MVVM과 궁합이 좋음
- **NaverMap**: 국내 사용자에 친숙하며, 실시간 경로 추적 최적화
- **Firebase**: 인증, 데이터 동기화, 실시간 커뮤니티 기능 구현
- **CoreMotion**: 걸음 수, 활동 정보 수집을 위한 센서 API
- **IQKeyboardManager**: 키보드에 의한 UI 가림 자동 처리

---

## 📅 개발 로드맵

### 1차
- 버그 수정 및 UI 개선

### 2차
- 수사일지 정렬 문제 개선
- 단서 데이터 연결 구조 개선

### 3차
- 커뮤니티 기능 추가  
  (글/댓글 작성, 수정, 삭제, 신고, 차단 등)

---

## 👥 팀 소개

| 이름 | 역할 | 담당 |
|------|------|------|
| **이정진** | 리더 | Firestore, 마이페이지, 앱 배포, 프로젝트 기획 |
| **최규현** | 부리더 | 카메라, 커뮤니티 기능 |
| **김재우** | 팀원 | 메인 탭, UI/UX 개선 |
| **전원식** | 팀원 | 마이페이지, API 연동 |
| **최영락** | 팀원 | 로그인/회원가입, Firebase Auth, Storage, 견종 검색 |
| **신혜진** | 팀원 | 디자인, 로고/아이콘 제작 |

---
