//
//  AvatarModel.swift
//  SherlDog
//
//  Created by 최규현 on 6/12/25.
//

import UIKit

struct AvatarModel {
    let avatar: String
    let icon: String
    let title: String
    let content: String
}

extension AvatarModel {
    static let avatarData: [AvatarModel] = [
        AvatarModel(avatar: "thief",
                    icon: "thiefFace",
                    title: "(전직) 도둑  <산책 루트 설계 조수>",
                    content: """
                        매일 새로운 산책 코스를 짜서 멍탐정에게 오늘의 ‘비밀 루트’를 소개 해준다. 겉모습은 다소 거칠어 보이지만, 사실은 순박한 성격이다. 한 특별한 사건을 계기로 멍탐정과 함께하게 되었고, 지금은 가장 믿을 만한 동반자가 되었다.
                        """),
        AvatarModel(avatar: "actor",
                    icon: "actorFace",
                    title: "극단배우  <사진 찍어주기 조수>",
                    content: """
                        무대에서 다양한 인물을 연기하던 극단 배우였다. 그러나 우연히 만난 멍탐정의 생생한 표정에 매료되어 전속 사진작가가 되었다. 사건 현장에선 중요한 순간을 가끔 놓치기도 하지만, 둘만의 소중한 추억만큼은 절대 빠뜨리지 않고 꼼꼼히 간직한다. 덕분에 멍탐정의 앨범에는 언제나 특별한 순간들이 한가득이다.
                        """),
        AvatarModel(avatar: "scientist",
                    icon: "scientistFace",
                    title: "과학자  <사료 영양 조수>",
                    content: """
                        멍탐정이 배고플 때마다 영양 만점 사료를 준비해준다. 가끔 새로운 레시피에 도전하지만, 멍탐정의 반응은... 글쎄다. 원래 개의 후각 능력을 연구하던 학자였는데, 멍탐정의 추리 능력에 매료되어 버렸다. 함께하는 시간이 늘어나면서, 냉철한 과학자에서 따뜻한 파트너로 변해갔다.
                        """),
        AvatarModel(avatar: "magician",
                    icon: "magicianFace",
                    title: "마법사 수련생 <목욕 준비 조수>",
                    content: """
                        산책 후 목욕 준비를 척척 해내는 마법사 수련생이다. 가끔은 새로운 마법을 시도하다가 비누거품 색이 엉뚱하게 변하기도 한다. 멍탐정이 산책 후 발 닦기를 거부하면 둘 사이에 작은 소동이 벌어지지만, 결국은 티격태격하면서도 떨어질 수 없는 콤비다. 
                        (사실 소동의 원인은 조수인 경우가 더 많지만!)
                        """),
        AvatarModel(avatar: "assistant",
                    icon: "assistantFace",
                    title: "그냥 평범한 조수 - 봉투 챙기기 조수",
                    content: """
                        멍탐정이 산책 중 볼일을 보면 어디서든 재빠르게 똥봉투를 꺼내는 뒷정리 전문가다. 처음엔 평범한 산책을 기대했는데, 어느새 멍탐정의 하루에 자연스레 스며들었다. 길에서 이상한 물건 먹으려 하면 슬쩍 막아주고, 예상치 못한 순간 단서를 툭 건네기도 한다. 종일 함께 걷다 보니, 둘 사이엔 말하지 않아도 통하는 무언가가 생겼다.
                        """),
        AvatarModel(avatar: "sherlock",
                    icon: "sherlockFace",
                    title: "셜록을 감명 깊게 본 사람  <산책 기록 조수>",
                    content: """
                        드라마 ‘셜록’에 감명받아 탐정 옷을 입고 다니는 산책 기록가다. 산책길에서 멍탐정이 어디로 가는지, 어떤 냄새를 맡는지, 누구를 만나는지 꼼꼼히 메모한다. 때로는 “여기서 꼬리를 세 번 흔들었어요!” 같은 디테일도 놓치지 않는다. 대단한 추리를 꿈꾸지만, 사실은 멍탐정의 평범한 일상과 소소한 순간을 남기는 데 더 진심이다.
                        """)
    ]
}
