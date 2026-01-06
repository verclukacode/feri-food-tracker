//
//  ViewController.swift
//  FeriFoodTracker
//
//  Created by Luka Verč on 6. 1. 26.
//

import UIKit

class ViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let homePage = HomeViewController()
        homePage.tabBarItem = UITabBarItem(title: "Diary", image: UIImage(systemName: "book.closed"), selectedImage: UIImage(systemName: "book.closed.fill"))
        
        let nutritionPage = NutritionListViewController(date: .now)
        nutritionPage.tabBarItem = UITabBarItem(title: "Nutrition", image: UIImage(systemName: "checklist.unchecked"), selectedImage: UIImage(systemName: "checklist.checked"))
        
        let suggestionsPage = SuggestionsViewController()
        suggestionsPage.tabBarItem = UITabBarItem(title: "Insights", image: UIImage(systemName: "heart.text.square"), selectedImage: UIImage(systemName: "heart.text.square.fill"))
        
        self.viewControllers = [
            homePage,
            UINavigationController(rootViewController: nutritionPage),
            suggestionsPage
        ]
        
        self.tabBar.tintColor = .label
        self.tabBar.unselectedItemTintColor = .secondaryLabel
        
    }
    
}
