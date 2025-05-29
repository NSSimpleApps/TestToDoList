//
//  ToDoListNetworkProvider.swift
//  TestToDoList
//
//  Created by user on 27.05.2025.
//

import Foundation
import Alamofire

/// Отправляет сетевые запросы.
/// Возвращает бинарные данные для дальнейшего парсинга.
final class ToDoListNetworkProvider {
    private let session: Session
    private let urlRequest: URLRequest
    init() {
        self.session = Session(startRequestsImmediately: false)
        self.urlRequest = URLRequest(url: URL(string: "https://dummyjson.com/todos")!,
                                     cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 60)
    }
    
    func loadToDoList(completion: @escaping @Sendable (Result<Data, NSError>) -> Void) {
        self.session.request(self.urlRequest).responseData(completionHandler: { response in
            let result: Result<Data, NSError>
            if let afError = response.error {
                let nsError = NSError.initFrom(afError: afError)
                result = .failure(nsError)
            } else if let httpResponse = response.response {
                let statusCode = httpResponse.statusCode
                if statusCode >= 200 && statusCode < 300 {
                    if let data = response.data {
                        result = .success(data)
                    } else {
                        let nsError = NSError(code: statusCode, reason: "Empty response.")
                        result = .failure(nsError)
                    }
                } else {
                    let nsError = NSError(code: statusCode, reason: "Invalid status code.")
                    result = .failure(nsError)
                }
            } else {
                let nsError = NSError(code: -1, reason: "There is not appropriate info.")
                result = .failure(nsError)
            }
            completion(result)
        }).resume()
    }
}


extension NSError {
    /// Создание ошибки из ошибки Alamofire.
    static func initFrom(afError: AFError) -> NSError {
        let nsError: NSError
        switch afError {
        case .responseValidationFailed(reason: let reason):
            switch reason {
            case .unacceptableStatusCode(code: let code):
                nsError = NSError(code: code, reason: "Unacceptable status code.")
            case .customValidationFailed(error: let error):
                nsError = error as NSError
            default:
                nsError = afError as NSError
            }
        case .sessionInvalidated(error: let error):
            if let error {
                nsError = error as NSError
            } else {
                nsError = NSError(code: -1, reason: "Session invalidated.")
            }
        case .sessionTaskFailed(error: let error):
            nsError = error as NSError
        case .serverTrustEvaluationFailed(reason: let serverTrustFailureReason):
            switch serverTrustFailureReason {
            case .customEvaluationFailed(error: let error):
                nsError = error as NSError
            default:
                nsError = NSError(code: -4, reason: "Server trust evaluation failed.")
            }
        case .responseSerializationFailed(reason: let responseSerializationFailureReason):
            switch responseSerializationFailureReason {
            case .jsonSerializationFailed(error: let error):
                nsError = error as NSError
            case .decodingFailed(error: let error):
                nsError = error as NSError
            case .customSerializationFailed(error: let error):
                nsError = error as NSError
            default:
                nsError = afError as NSError
            }
        case .explicitlyCancelled:
            nsError = NSError.cancelledError(reason: "Request explicitly cancelled.")
        case .requestRetryFailed(retryError: let retryError, originalError: let originalError):
            if let afError = retryError as? AFError {
                return self.initFrom(afError: afError)
            } else {
                nsError = originalError as NSError
            }
        default:
            nsError = afError as NSError
        }
        return nsError
    }
}
