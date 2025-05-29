//
//  UIColor+Extensions.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//

import UIKit

extension UIColor {
    static let toDoGray = UIColor.toDoWhite.withAlphaComponent(0.5)
    
    static let toDoWhite = UIColor(red: UInt8(244).percent,
                                   green: UInt8(244).percent,
                                   blue: UInt8(244).percent,
                                   alpha: 1) // #F4F4F4
    
    static let toDoDarkStroke = UIColor(red: UInt8(77).percent,
                                        green: UInt8(85).percent,
                                        blue: UInt8(94).percent,
                                        alpha: 1) // #4D555E
    
    static let toDoYellow = UIColor(red: UInt8(254).percent,
                                    green: UInt8(215).percent,
                                    blue: UInt8(2).percent,
                                    alpha: 1) // #FED702
    
    static let toDoDarkBackground = UIColor(red: UInt8(4).percent,
                                            green: UInt8(4).percent,
                                            blue: UInt8(5).percent,
                                            alpha: 1) // #040404
}
extension UInt8 {
    /// Величина числа в дроби от максимального.
    var percent: CGFloat {
        return CGFloat(self) / CGFloat(Self.max)
    }
}
