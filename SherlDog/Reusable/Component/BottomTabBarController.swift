//
//  BottomTabBarController.swift
//  SherlDog
//
//  Created by JIN LEE on 6/5/25.
//

import UIKit

class BottomTabBarController: UITabBarController {
    
    let VC1 = WalkMainViewController()
    let VC2 = WalkMainViewController()
    let VC3 = WalkMainViewController()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let controllers = [VC1, VC2, VC3]
        self.viewControllers = controllers
        
        setupTabBar()
        configureTabBar()
    }
    
    private func setupTabBar() {
        
        VC1.tabBarItem = UITabBarItem(title: "홈", image: UIImage(named: "home")?.resized(to: CGSize(width: 32, height: 32)),tag: 1)
        VC1.tabBarItem.selectedImage = UIImage(named: "homeGreen")?.resized(to: CGSize(width: 32, height: 32)).withRenderingMode(.alwaysOriginal)
        
        VC2.tabBarItem = UITabBarItem(title: "커뮤니티", image: UIImage(named: "community")?.resized(to: CGSize(width: 32, height: 32)),tag: 0)
        VC2.tabBarItem.selectedImage = UIImage(named: "communityGreen")?.resized(to: CGSize(width: 32, height: 32)).withRenderingMode(.alwaysOriginal)
        
        VC3.tabBarItem = UITabBarItem(title: "마이", image: UIImage(named: "myPage")?.resized(to: CGSize(width: 32, height: 32)),tag: 2)
        VC3.tabBarItem.selectedImage = UIImage(named: "myPageGreen")?.resized(to: CGSize(width: 32, height: 32)).withRenderingMode(.alwaysOriginal)
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
        
        appearance.backgroundEffect = UIBlurEffect(style: .light)
        //standardAppearance랑 scrollEdgeAppearance 둘 다 지정해줘야 UITabBarAppearance()에 지정한 스타일이 먹음.
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = unselectedAttributes
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().unselectedItemTintColor = .white
        UITabBar.appearance().tintColor = .white
    }
    
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
