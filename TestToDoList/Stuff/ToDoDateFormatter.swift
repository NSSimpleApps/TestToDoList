//
//  ToDoDateFormatter.swift
//  TestToDoList
//
//  Created by user on 21.05.2025.
//

import Foundation

/// Форматирование даты в строку.
final class ToDoDateFormatter: Sendable {
    /// Поддерживаемые строки даты.
    enum DateFormat {
        /// Строковый разделитель.
        case delim(String)
        /// Минуты.
        case mm
        
        /// Час без нуля.
        case H
        /// Час с нулём.
        case HH
        
        /// Дни без нуля.
        case d
        /// Дни с нулём.
        case dd
        
        /// Месяцы в числовом формате 01...12.
        case MM
        /// Месяцы в кратком буквенном формате.
        case _MMM(shortMonthSymbols: [String])
        /// Месяцы в полном буквенном формате.
        case _MMMM(monthSymbols: [String])
        
        /// Крайние 2 цифры года.
        case yy
        /// Полный год.
        case yyyy
        
        /// Точка.
        static var dot: Self { return .delim(".") }
        /// Двоеточие.
        static var colon: Self { return .delim(":") }
        /// Пробел.
        static var space: Self { return .delim(" ") }
        
        /// Месяцы в кратком буквенном формате.
        static func MMM(_ locale: String) -> Self {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: locale)
            let shortMonthSymbols = dateFormatter.shortMonthSymbols
            
            return ._MMM(shortMonthSymbols: shortMonthSymbols!)
        }
        
        /// Месяцы в полном буквенном формате.
        static func MMMM(_ locale: String) -> Self {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: locale)
            let monthSymbols = dateFormatter.monthSymbols
            
            return ._MMMM(monthSymbols: monthSymbols!)
        }
    }
    let dateFormats: [DateFormat]
    let calendar: Calendar
    
    init(calendar: Calendar?, dateFormats: [DateFormat]) {
        self.dateFormats = dateFormats
        self.calendar = calendar ?? Calendar(identifier: .gregorian)
    }
    
    func string(from date: Date) -> String {
        if self.dateFormats.isEmpty {
            return date.description
        } else {
            return self.dateFormats.reduce(into: "") { (partial, dateFormat) in
                switch dateFormat {
                case .delim(let delim):
                    partial.append(delim)
                case .mm:
                    let minute = self.calendar.component(.minute, from: date)
                    partial.append(String(format: "%02d", minute))
                case .H:
                    let hour = self.hour(from: date)
                    partial.append(String(hour))
                case .HH:
                    let hour = self.hour(from: date)
                    partial.append(String(format: "%02d", hour))
                case .d:
                    let day = self.day(from: date)
                    partial.append(String(day))
                case .dd:
                    let day = self.day(from: date)
                    partial.append(String(format: "%02d", day))
                case .MM:
                    let month = self.month(from: date)
                    partial.append(String(format: "%02d", month))
                case ._MMM(shortMonthSymbols: let shortMonthSymbols):
                    let month = self.month(from: date)
                    partial.append(shortMonthSymbols[month - 1])
                case ._MMMM(monthSymbols: let monthSymbols):
                    let month = self.month(from: date)
                    partial.append(monthSymbols[month - 1])
                case .yy:
                    let year = self.year(from: date)
                    partial.append(contentsOf: String(format: "%04d", year).suffix(2))
                case .yyyy:
                    let year = self.year(from: date)
                    partial.append(String(format: "%04d", year))
                }
            }
        }
    }
    private func hour(from date: Date) -> Int {
        return self.calendar.component(.hour, from: date)
    }
    private func day(from date: Date) -> Int {
        return self.calendar.component(.day, from: date)
    }
    private func month(from date: Date) -> Int {
        return self.calendar.component(.month, from: date)
    }
    private func year(from date: Date) -> Int {
        return self.calendar.component(.year, from: date)
    }
}
