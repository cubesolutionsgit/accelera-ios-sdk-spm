//
//  WebClient.swift
//
//  Created by Evgeny Boganov on 14.10.2019.
//

import Foundation

typealias JSON = [String: Any]

enum RequestMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

final class WebClient {

    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    private var baseUrl: String
    private var session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
    
    func load(path: String, method: RequestMethod, params: JSON, headers: [String: String] = [:], completion: @escaping (Any?, NetworkError?) -> ()) -> URLSessionDataTask? {
        
        let request = URLRequest(baseUrl: baseUrl, path: path, method: method, params: params, headers: headers)
        
        let task = session.dataTask(with: request) { data, response, error in
            var object: Any? = nil
            if let data = data {
                object = try? JSONSerialization.jsonObject(with: data, options: [])
            }
            
            if let httpResponse = response as? HTTPURLResponse, (200..<300) ~= httpResponse.statusCode {
                completion(object, nil)
            } else {
                let error = (object as? JSON).flatMap(NetworkError.init) ?? NetworkError.other
                completion(nil, error)
            }
        }
        
        task.resume()
        
        return task
    }
}
