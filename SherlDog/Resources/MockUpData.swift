//
//  MockUpData.swift
//  SherlDog
//
//  Created by 최규현 on 7/16/25.
//

import UIKit
import FirebaseFirestore

struct MockUpData {
    static let communitySample: [CommunityModel] = [
        CommunityModel(profileImage: "https://m.health.chosun.com/site/data/img_dir/2025/04/08/2025040803041_0.jpg",
                       name: "강아지명",
                       info: "1세 남아 / 포메라니안",
                       postDate: Timestamp(date: Date()),
                       contentImage: "https://m.health.chosun.com/site/data/img_dir/2023/01/10/2023011001501_0.jpg",
                       content: "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest"),
        CommunityModel(profileImage: "https://img.khan.co.kr/news/r/700xX/2024/03/23/news-p.v1.20240323.c159a4cab6f64473adf462d873e01e43_P1.webp",
                       name: "강아지명",
                       info: "3세 여아 / 포메라니안",
                       postDate: Timestamp(date: Date()),
                       contentImage: "https://cdn.travie.com/news/photo/first/201710/img_19975_1.jpg",
                       content: "testtesttesttestteststtesttesttest"),
        CommunityModel(profileImage: "https://godomall.speedycdn.net/a821c735e2b8cdac3e23257ac7455ca6/goods/1000005275/image/detail/1000005275_detail_074.jpg",
                       name: "강아지명",
                       info: "1세 여아 / 비숑프리제",
                       postDate: Timestamp(date: Date()),
                       contentImage: "https://cdn.travie.com/news/photo/first/201710/img_19975_2.jpg",
                       content: "testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest")
    ]
}
