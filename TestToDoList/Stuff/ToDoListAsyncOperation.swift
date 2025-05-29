//
//  ToDoListAsyncOperation.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//

import Foundation

enum ToDoListOperationResult<ResultType> {
    case success(ResultType)
    case await
    case cancel
}

/// Асинхронная операция. Завершать методом finish(with:).
final class ToDoListAsyncOperation<T, ErrorType: Error>: Operation, @unchecked Sendable {
    enum State: Int {
        case ready
        case executing
        case finished
        case cancelled
    }
    private let lock = ToDoListUnfairLock()
    private var state = State.ready
    private var result: Result<T, ErrorType>?
    private let block: (ToDoListAsyncOperation) throws(ErrorType) -> ToDoListOperationResult<T>
    
    init(block: @escaping (ToDoListAsyncOperation) throws(ErrorType) -> ToDoListOperationResult<T>,
         completion: @escaping @Sendable (Result<T, ErrorType>?) -> Void) {
        self.block = block
        super.init()
        self.completionBlock = { [unowned self] in
            self.lock.lock()
            let result = self.result
            self.lock.unlock()
            
            completion(result)
        }
    }
    override var isAsynchronous: Bool {
        return true
    }
    
    override var isCancelled: Bool {
        self.lock.lock()
        let isCancelled = self.state == .cancelled
        self.lock.unlock()
        
        return isCancelled
    }
    override func cancel() {
        self.lock.lock()
        let state = self.state
        self.lock.unlock()
        
        if state == .executing || state == .ready {
            self.willChangeValue(for: \.isReady)
            self.willChangeValue(for: \.isCancelled)
            self.willChangeValue(for: \.isExecuting)
            self.willChangeValue(for: \.isFinished)
            
            self.lock.lock()
            self.result = nil
            self.state = .cancelled
            self.lock.unlock()
            
            self.didChangeValue(for: \.isReady)
            self.didChangeValue(for: \.isCancelled)
            self.didChangeValue(for: \.isExecuting)
            self.didChangeValue(for: \.isFinished)
        }
    }
    override var isExecuting: Bool {
        self.lock.lock()
        let isExecuting = self.state == .executing
        self.lock.unlock()
        
        return isExecuting
    }
    override var isFinished: Bool {
        self.lock.lock()
        let state = self.state
        let isFinished = state == .finished || state == .cancelled
        self.lock.unlock()
        
        return isFinished
    }
    override var isReady: Bool {
        self.lock.lock()
        let isReady = self.state == .ready
        self.lock.unlock()
        
        return isReady
    }
    
    override func start() {
        self.lock.lock()
        let state = self.state
        self.lock.unlock()
        
        if state == .ready {
            self.willChangeValue(for: \.isReady)
            self.willChangeValue(for: \.isExecuting)
            
            self.lock.lock()
            self.state = .executing
            self.lock.unlock()
            
            self.didChangeValue(for: \.isReady)
            self.didChangeValue(for: \.isExecuting)
            
            self.main()
        }
    }
    
    override func main() {
        do {
            let operationResult = try self.block(self)
            switch operationResult {
            case .success(let result):
                self.finish(with: .success(result))
            case .await:
                break
            case .cancel:
                self.cancel()
            }
        } catch {
            self.finish(with: .failure(error))
        }
    }
    
    func finish(with result: Result<T, ErrorType>) {
        self.lock.lock()
        let state = self.state
        self.lock.unlock()
        
        if state == .executing || state == .ready {
            self.willChangeValue(for: \.isReady)
            self.willChangeValue(for: \.isExecuting)
            self.willChangeValue(for: \.isFinished)
            
            self.lock.lock()
            self.result = result
            self.state = .finished
            self.lock.unlock()
            
            self.didChangeValue(for: \.isReady)
            self.didChangeValue(for: \.isExecuting)
            self.didChangeValue(for: \.isFinished)
        }
    }
}
final class ToDoListUnfairLock: @unchecked Sendable {
    private let unfairLock: os_unfair_lock_t
    
    init() {
        self.unfairLock = .allocate(capacity: 1)
        self.unfairLock.initialize(to: os_unfair_lock())
    }
    deinit {
        self.unfairLock.deinitialize(count: 1)
        self.unfairLock.deallocate()
    }
    
    func lock() {
        os_unfair_lock_lock(self.unfairLock)
    }
    func unlock() {
        os_unfair_lock_unlock(self.unfairLock)
    }
}
extension OperationQueue {
    convenience init(name: String) {
        self.init()
        self.name = "com.todolist." + name
        self.qualityOfService = .background
        self.maxConcurrentOperationCount = 1
    }
    
    func addAsyncOperation(_ operation: Operation) {
        operation.name = self.name
        self.addOperation(operation)
    }
}
