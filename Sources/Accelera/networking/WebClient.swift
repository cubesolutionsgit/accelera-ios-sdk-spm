//
//  WebClient.swift
//  Accelera
//
//  Created by Evgeny Boganov on 14.10.2019.
//

import Foundation

/// Supported HTTP methods for network requests.
public enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// A simple HTTP client for sending JSON-based API requests.
public final class WebClient {
    private let baseUrl: String
    private let session: URLSession

    /// Initializes the client with a base URL.
    /// - Parameter baseUrl: The root URL for all requests (e.g. `https://api.domain.com`)
    public init(baseUrl: String) {
        self.baseUrl = baseUrl
        let config = URLSessionConfiguration.default
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }

    /**
     Sends a request to the given API path using the specified HTTP method.

     - Parameters:
       - path: Relative path to append to the base URL (e.g. `/users/login`)
       - method: HTTP method (`GET`, `POST`, etc.)
       - body: Optional JSON data to include in the request body
       - headers: Optional additional headers
       - completion: Completion block with either response `Data` or `NetworkError`

     - Returns: The created `URLSessionDataTask` if the request was started
     */
    @discardableResult
    public func load(
        path: String,
        method: RequestMethod,
        body: Data? = nil,
        headers: [String: String] = [:],
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        var request = URLRequest(baseUrl: baseUrl, path: path, method: method, body: body, headers: headers)

        let task = session.dataTask(with: request) { data, response, error in
            let networkError = NetworkError.fromResponse(data: data, response: response, error: error)

            if case .server = networkError,
               let httpResponse = response as? HTTPURLResponse,
               (200..<300).contains(httpResponse.statusCode) {
                completion(data, nil)
            } else if error == nil,
                      let httpResponse = response as? HTTPURLResponse,
                      (200..<300).contains(httpResponse.statusCode) {
                completion(data, nil)
            } else {
                completion(nil, networkError)
            }
        }

        task.resume()
        return task
    }
}
