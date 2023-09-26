//
//  TabBarController.swift
//  Tracker
//
//  Created by Victoria Isaeva on 26.09.2023.
//

import UIKit

final class TabBarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let trackerViewController = UINavigationController(rootViewController: TrackerViewController())
        let statisticViewController = UINavigationController(rootViewController: StatisticViewController())
        
        trackerViewController.tabBarItem = UITabBarItem(title: "Трекеры", image: UIImage(named: "allTrackers"), selectedImage: nil)
        statisticViewController.tabBarItem = UITabBarItem(title: "Статистика", image: UIImage(named: "rabbitImage"), selectedImage: nil)
        
        let viewControllers = [trackerViewController, statisticViewController]
        
        self.viewControllers = viewControllers
        
        for viewController in viewControllers {
            let leftImage = UIImage(named: "allTrackers")
            let rightImage = UIImage(named: "rabbitImage")
            
            let leftBarButtonItem = UIBarButtonItem(image: leftImage, style: .plain, target: self, action: #selector(leftBarButtonTapped))
            let rightBarButtonItem = UIBarButtonItem(image: rightImage, style: .plain, target: self, action: #selector(rightBarButtonTapped))
            
            viewController.navigationItem.leftBarButtonItem = leftBarButtonItem
            viewController.navigationItem.rightBarButtonItem = rightBarButtonItem
        }
        
        if #available(iOS 13.0, *) {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.configureWithDefaultBackground()
            tabBarAppearance.backgroundColor = UIColor.white
            tabBarAppearance.shadowColor = UIColor.black
            
            tabBar.standardAppearance = tabBarAppearance
            
            if #available(iOS 15.0, *) {
                tabBar.scrollEdgeAppearance = tabBarAppearance
            }
        }
    }
    
    @objc func leftBarButtonTapped() {
    }
    
    @objc func rightBarButtonTapped() {
    }
}
