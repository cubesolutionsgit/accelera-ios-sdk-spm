//
//  NetworkError.swift
//  Accelera
//
//  Created by Evgeny Boganov on 14.10.2019.
//

import Foundation

/// Represents networking-related errors that may occur during a request.
public enum NetworkError: Error {
    
    /// No internet connection available.
    case noConnection

    /// The request timed out.
    case timeout

    /// The request was cancelled before completion.
    case cancelled

    /// The response could not be decoded.
    case decoding

    /// A response was received, but it was not a valid HTTPURLResponse.
    case badResponse

    /// Server responded with an error HTTP status code (4xx or 5xx).
    /// - Parameters:
    ///   - status: HTTP status code returned by the server.
    ///   - message: Optional message from the server response body.
    case server(status: Int, message: String?)

    /// A low-level networking error occurred.
    /// - Parameter error: The underlying system error.
    case internalError(Error)
}

extension NetworkError {

    /**
     Creates a `NetworkError` from a URLSession response, optional data, and error.
     
     - Parameters:
       - data: Optional response body from the server.
       - response: URL response from the server (expected to be `HTTPURLResponse`).
       - error: Optional system error from `URLSession`.
     */
    public static func fromResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> NetworkError {
        // Network-level URLSession error
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return .noConnection
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            default:
                return .internalError(urlError)
            }
        }

        // Invalid or missing HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            return .badResponse
        }

        // Server responded with error (non-2xx)
        if (400..<600).contains(httpResponse.statusCode) {
            return NetworkError(data: data, statusCode: httpResponse.statusCode)
        }

        // Fallback: unknown internal error
        if let error {
            return .internalError(error)
        }

        return .internalError(NSError(domain: "Unknown", code: 0))
    }

    /**
     Creates a `.server` error from raw response data and status code.

     Attempts to parse JSON for common error message fields like `"message"`, `"error"`, or `"detail"`.
     
     - Parameters:
       - data: Optional response body.
       - statusCode: HTTP status code returned by the server.
     */
    public init(data: Data?, statusCode: Int) {
        var message: String?

        if let data,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            message = json["message"] as? String
                ?? json["error"] as? String
                ?? json["detail"] as? String
        }

        self = .server(status: statusCode, message: message)
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .cancelled:
            return "Request was cancelled"
        case .decoding:
            return "Failed to decode response"
        case .badResponse:
            return "Invalid or missing HTTP response"
        case .server(let status, let message):
            return message ?? "Server error (code \(status))"
        case .internalError(let error):
            return error.localizedDescription
        }
    }
}
