//
//  NSError+Extensions.swift
//  TestToDoList
//
//  Created by user on 21.05.2025.
//

import Foundation

extension NSError {
    /// Ошибка `Отмена`.
    var isCancelled: Bool {
        return self.code == NSURLErrorCancelled
    }
    /// Создание ошибки типа `Отмена`.
    static func cancelledError(reason: String) -> NSError {
        return NSError(code: NSURLErrorCancelled, reason: reason)
    }
    /// Конструктор для создания ошибки. Передаётся код при причина.
    convenience init(code: Int, reason: String) {
        self.init(domain: "ToDoListErrorDomain", code: code, userInfo: [NSLocalizedDescriptionKey: reason])
    }
}
