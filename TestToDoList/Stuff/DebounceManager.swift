//
//  DebounceManager.swift
//  TestToDoList
//
//  Created by user on 29.05.2025.
//


import Foundation

/// Выполняет задачу через timeInterval,
/// если она не была отменена.
final class DebounceManager: Sendable {
    private let operationQueue = OperationQueue(name: "DebounceManager")
    
    func schedule(timeInterval: TimeInterval, completion: @escaping @MainActor () -> Void) {
        self.cancelAllOperations()
        
        let asyncOperation =
        ToDoListAsyncOperation(block: { asyncOperation throws(NSError) in
            DispatchQueue.global().asyncAfter(deadline: .now() + timeInterval, execute: {
                asyncOperation.finish(with: .success(()))
            })
            return .await
        },
                               completion: { (result: Result<Void, NSError>?) in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    completion()
                }
            case .failure:
                break
            default:
                break
            }
        })
        self.operationQueue.addAsyncOperation(asyncOperation)
    }
    
    func cancelAllOperations() {
        self.operationQueue.cancelAllOperations()
    }
    deinit {
        self.cancelAllOperations()
    }
}
