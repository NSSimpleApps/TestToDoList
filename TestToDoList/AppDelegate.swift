//
//  AppDelegate.swift
//  TestToDoList
//
//  Created by user on 26.05.2025.
//

import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let navigationBarAppearance = UINavigationBarAppearance()
        //navigationBarAppearance.configureWithDefaultBackground()
        navigationBarAppearance.titleTextAttributes[.foregroundColor] = UIColor.toDoWhite
        navigationBarAppearance.largeTitleTextAttributes[.foregroundColor] = UIColor.toDoWhite
        
        let appearance = UINavigationBar.appearance()
        appearance.scrollEdgeAppearance = navigationBarAppearance
        appearance.compactAppearance = navigationBarAppearance
        appearance.standardAppearance = navigationBarAppearance
        appearance.compactScrollEdgeAppearance = navigationBarAppearance
        
        let barButtonAppearance = UIBarButtonItem.appearance()
        barButtonAppearance.tintColor = UIColor.toDoYellow
        
        return true
    }
}
