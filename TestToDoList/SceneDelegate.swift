//
//  SceneDelegate.swift
//  TestToDoList
//
//  Created by user on 26.05.2025.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    private let toDoListRouter = ToDoListRouter()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if self.window == nil {
            guard let windowScene = scene as? UIWindowScene else { return }
            
            let window = UIWindow(windowScene: windowScene)
            window.overrideUserInterfaceStyle = .dark
            let loadingModule = self.toDoListRouter.createLoadingModule()
            window.rootViewController = loadingModule
            self.window = window
            window.makeKeyAndVisible()
            
            self.toDoListRouter.createToDoListModule(comletion: { toDoListModule in
                window.rootViewController = toDoListModule
            })
        }
    }
}
