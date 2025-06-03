//
//  URLRequest+.swift
//
//  Created by Evgeny Boganov on 14.10.2019.
//

import Foundation

extension URLRequest {
    init(baseUrl: String, path: String, method: RequestMethod, params: JSON, headers: [String: String] = [:]) {
        let url = URL(baseUrl: baseUrl, path: path, params: params, method: method)
        self.init(url: url)
        httpMethod = method.rawValue
        setValue("application/json", forHTTPHeaderField: "Accept")
        setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        headers.forEach{ header in
            setValue(header.value, forHTTPHeaderField: header.key)
        }
        
        switch method {
        case .post, .put:
            httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        default:
            break
        }
    }
}
