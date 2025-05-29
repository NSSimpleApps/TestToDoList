//
//  ToDoLoadingViewController.swift
//  TestToDoList
//
//  Created by user on 28.05.2025.
//


import UIKit

/// Экран-заглушка на время создания корневого экрана.
final class ToDoLoadingViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.toDoDarkBackground
        
        let activityIndicatorView = UIActivityIndicatorView(style: .medium)
        activityIndicatorView.color = UIColor.toDoWhite
        activityIndicatorView.startAnimating()
        self.view.autoLayoutSubview(activityIndicatorView)
        activityIndicatorView.centerEquals(to: self.view)
    }
}
