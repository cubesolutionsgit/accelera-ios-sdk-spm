//
//  NetworkError.swift
//
//  Created by Evgeny Boganov on 14.10.2019.
//

import Foundation

enum NetworkError: Error {
    case noInternetConnection
    case custom(String)
    case other
}

extension NetworkError {
    init(json: JSON) {
        if let message =  json["message"] as? String {
            self = .custom(message)
        } else {
            self = .other
        }
    }
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No Internet connection"
        case .other:
            return "Something went wrong"
        case .custom(let message):
            return message
        }
    }
}


