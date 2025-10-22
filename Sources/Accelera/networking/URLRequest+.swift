//
//  URLRequest+.swift
//
//  Created by Evgeny Boganov on 14.10.2019.
//

import Foundation

extension URLRequest {
    init(
        baseUrl: String,
        path: String,
        method: RequestMethod,
        body: Data? = nil,
        headers: [String: String] = [:]
    ) {
        let fullUrlString = baseUrl + (path.hasPrefix("/") ? path : "/" + path)
        guard let url = URL(string: fullUrlString) else {
            fatalError("Invalid URL: \(fullUrlString)")
        }
        self.init(url: url)
        httpMethod = method.rawValue
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue("application/json", forHTTPHeaderField: "Content-Type")

        headers.forEach { key, value in
            setValue(value, forHTTPHeaderField: key)
        }

        if let body {
            httpBody = body
        }
    }
}
