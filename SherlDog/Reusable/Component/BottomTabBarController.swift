//
//  BottomTabBarController.swift
//  SherlDog
//
//  Created by JIN LEE on 6/5/25.
//

import UIKit

class BottomTabBarController: UITabBarController {
    
    let mainVC = UINavigationController(rootViewController: MainViewController())
    // let communityVC = UINavigationController(rootViewController: CommunityViewController())
    let myPageVC = UINavigationController(rootViewController: MyPageViewController())

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controllers = [mainVC,/*communityVC,*/ myPageVC]
        self.viewControllers = controllers
        
        self.navigationItem.hidesBackButton = true
        
        setupTabBar()
        configureTabBar()
    }
    
    private func setupTabBar() {
        
        mainVC.tabBarItem = UITabBarItem(title: "홈",
                                      image: UIImage(named: "home")?.resized(to: CGSize(width: 32, height: 32)),tag: 0)
        mainVC.tabBarItem.selectedImage = UIImage(named: "homeGreen")?.resized(to: CGSize(width: 32, height: 32)).withRenderingMode(.alwaysOriginal)
        
//        communityVC.tabBarItem = UITabBarItem(title: "수사일지",
//                                      image: UIImage(named: "community")?.resized(to: CGSize(width: 32, height: 32)),tag: 1)
//        communityVC.tabBarItem.selectedImage = UIImage(named: "communityGreen")?.resized(to: CGSize(width: 32, height: 32)).withRenderingMode(.alwaysOriginal)
        
        myPageVC.tabBarItem = UITabBarItem(title: "마이",
                                      image: UIImage(named: "myPage")?.resized(to: CGSize(width: 32, height: 32)),tag: 2)
        myPageVC.tabBarItem.selectedImage = UIImage(named: "myPageGreen")?.resized(to: CGSize(width: 32, height: 32)).withRenderingMode(.alwaysOriginal)
    }
    
    private func configureTabBar() {
        
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.body5,
            .foregroundColor: UIColor.textPrimary
        ]

        let unselectedAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.body5,
            .foregroundColor: UIColor.gray300
        ]
        
        let appearance = UITabBarAppearance()
        
        appearance.backgroundColor = .keycolorInverse
        //standardAppearance랑 scrollEdgeAppearance 둘 다 지정해줘야 UITabBarAppearance()에 지정한 스타일이 먹음.
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = unselectedAttributes
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = .keycolorInverse
        UITabBar.appearance().tintColor = .keycolorInverse
    }
}
