//
//  Int+Extensions.swift
//  TestToDoList
//
//  Created by user on 28.05.2025.
//

import Foundation

/// Падежи существительных.
enum NumberCases: Int {
    case nominative, genitive, plural
}
extension SignedInteger {
    /// Падежи существительных в зависимости от числа.
    func cases(locale: String) -> NumberCases {
        let abs = abs(self)
        
        if locale == "ru" || locale == "uk" {
            if abs > 10 && abs < 20 {
                return .plural
            } else {
                switch abs % 10 {
                case 1:
                    return .nominative
                case 2, 3, 4:
                    return .genitive
                default:
                    return .plural
                }
            }
        } else {
            if abs == 1 {
                return .nominative
            } else {
                return .plural
            }
        }
    }
}
