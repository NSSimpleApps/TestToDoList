//
//  UIView+Extensions.swift
//  TestToDoList
//
//  Created by user on 12.05.2025.
//


import UIKit


extension UIView {
    /// Равенство верхней границе.
    func topEquals(to superview: UIView, inset: CGFloat = 0) {
        self.topEqualsToBorder(of: superview.topAnchor, space: inset)
    }
    /// Равенство верхней границе.
    /// space - отступ вниз.
    func topEqualsToBorder(of border: NSLayoutAnchor<NSLayoutYAxisAnchor>, space: CGFloat = 0) {
        self.topAnchor.constraint(equalTo: border, constant: space).isActive = true
    }
    
    /// Равенство нижней границе.
    func bottomEquals(to superview: UIView, inset: CGFloat = 0) {
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor, constant: -inset).isActive = true
    }
    /// Равенство нижней и верхней границы.
    func topBottomEquals(to superview: UIView, inset: CGFloat = 0) {
        self.topEquals(to: superview, inset: inset)
        self.bottomEquals(to: superview, inset: inset)
    }
    
    /// Равенство левого края.
    func leftEquals(to superview: UIView, inset: CGFloat = 0) {
        self.leftAnchor.constraint(equalTo: superview.leftAnchor, constant: inset).isActive = true
    }
    /// Равенство левому отступу.
    func leftEqualsToLayoutMargin(of superview: UIView, inset: CGFloat = 0) {
        self.leftAnchor.constraint(equalTo: superview.layoutMarginsGuide.leftAnchor, constant: inset).isActive = true
    }
    /// Равенство левой читаемой границе.
    func leftEqualsToReadableMargin(of superview: UIView, inset: CGFloat = 0) {
        self.leftAnchor.constraint(equalTo: superview.readableContentGuide.leftAnchor, constant: inset).isActive = true
    }
    /// Левая граница равна указанной границе.
    /// space - отступ вправо.
    func leftEqualsToBorder(of border: NSLayoutAnchor<NSLayoutXAxisAnchor>, space: CGFloat = 0) {
        self.leftAnchor.constraint(equalTo: border, constant: space).isActive = true
    }
    
    /// Равенство правому краю.
    func rightEquals(to superview: UIView, inset: CGFloat = 0) {
        self.rightAnchor.constraint(equalTo: superview.rightAnchor, constant: -inset).isActive = true
    }
    /// Равенство правому отступу.
    func rightEqualsToLayoutMargin(of superview: UIView, inset: CGFloat = 0) {
        self.rightAnchor.constraint(equalTo: superview.layoutMarginsGuide.rightAnchor, constant: -inset).isActive = true
    }
    /// Равенство правой читаемой границе.
    func rightEqualsToReadableMargin(of superview: UIView, inset: CGFloat = 0) {
        self.rightAnchor.constraint(equalTo: superview.readableContentGuide.rightAnchor, constant: -inset).isActive = true
    }
    /// Правая граница равна указанной границе.
    /// space - отступ влево.
    func rightEqualsToBorder(of border: NSLayoutAnchor<NSLayoutXAxisAnchor>, space: CGFloat = 0) {
        self.rightAnchor.constraint(equalTo: border, constant: -space).isActive = true
    }
    
    /// Левый и правый край равны указанной вьюшке.
    func leftRightEquals(to superview: UIView, inset: CGFloat = 0) {
        self.leftEquals(to: superview, inset: inset)
        self.rightEquals(to: superview, inset: inset)
    }
    /// Левый и правый край равны отступу.
    func leftRightEqualsToLayoutMargin(of superview: UIView, inset: CGFloat = 0) {
        self.leftEqualsToLayoutMargin(of: superview, inset: inset)
        self.rightEqualsToLayoutMargin(of: superview, inset: inset)
    }
    /// Левый и правый край равны читаемой границе.
    func leftRightEqualsToReadableMargin(of superview: UIView, inset: CGFloat = 0) {
        self.leftEqualsToReadableMargin(of: superview, inset: inset)
        self.rightEqualsToReadableMargin(of: superview, inset: inset)
    }
    
    /// Центр по горизонтали равен указанному.
    /// topShift - смещение вверх.
    func centerYEquals(to superview: UIView) {
        self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }
    /// Центр по вертикали равен указанному.
    func centerXEquals(to superview: UIView) {
        self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
    }
    /// Центр равен указанному.
    func centerEquals(to superview: UIView) {
        self.centerYEquals(to: superview)
        self.centerXEquals(to: superview)
    }
    
    /// Высота равна указанному значению.
    func heightEqualsTo(_ height: CGFloat) {
        self.heightAnchor.constraint(equalToConstant: height).isActive = true
    }
    /// Ширина равна указанному значению.
    func widthEqualsTo(_ width: CGFloat) {
        self.widthAnchor.constraint(equalToConstant: width).isActive = true
    }
    /// Высота и ширина равны указанному значению.
    func sizeEqualsTo(square: CGFloat) {
        self.heightEqualsTo(square)
        self.widthEqualsTo(square)
    }
    
    /// Добавление на родительскую вьюшку с автолайаутом.
    func autoLayoutSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(subview)
    }
    /// Высота вьюшки с использованием авто-лейаута.
    func autoLayoutHeight(parentSize: CGSize) -> CGFloat {
        return self.systemLayoutSizeFitting(parentSize, withHorizontalFittingPriority: .required,
                                            verticalFittingPriority: .fittingSizeLevel).height
    }
    
    /// Родительский контроллер.
    func parentViewController<ViewController: UIViewController>(ofType type: ViewController.Type) -> ViewController? {
        switch self.next {
        case (let viewController as UIViewController):
            if let result = viewController as? ViewController {
                return result
            } else if let navigationController = viewController as? UINavigationController {
                if let result = navigationController.visibleViewController as? ViewController {
                    return result
                } else {
                    return navigationController.parentViewController(ofType: type)
                }
            } else {
                return viewController.parentViewController(ofType: type)
            }
        case (let view as UIView):
            return view.parentViewController(ofType: type)
        default:
            return nil
        }
    }
}

extension UITableView {
    /// Регистрация ячейки с заданным типом.
    func register<T: UITableViewCell>(cellClass: T.Type) {
        self.register(cellClass, forCellReuseIdentifier: String(describing: cellClass))
    }
    /// Получение ячейки с заданным типом.
    func dequeueReusableCell<T: UITableViewCell>(withCellClass cellClass: T.Type, for indexPath: IndexPath) -> T {
        return self.dequeueReusableCell(withIdentifier: String(describing: cellClass), for: indexPath) as! T
    }
}


extension UIViewController {
    /// Родительский экран указанного типа.
    func parentViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        if let parent = self.parent {
            if let result = parent as? T {
                return result
            } else {
                return parent.parentViewController(ofType: type)
            }
        } else {
            return nil
        }
    }
}
extension UIRefreshControl {
    func fixedEndRefreshing() {
        if self.isRefreshing {
            self.perform(#selector(self.endRefreshing), with: nil, afterDelay: 0.5)
        }
    }
}

extension UIBarButtonItem {
    /// Родительский экран указанного типа.
    func parentViewController<T: UIViewController>(ofType type: T.Type) -> T? {
        guard let view = self.value(forKey: "view") as? UIView else { return nil }
        guard let navigationController = view.parentViewController(ofType: UINavigationController.self) else { return nil }
        
        return navigationController.visibleViewController as? T
    }
}
    
