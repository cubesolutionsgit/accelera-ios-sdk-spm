//
//  AcceleraAPI.swift
//  Accelera
//
//  Created by Evgeny Boganov on 15.08.2022.
//

import Foundation

final class AcceleraAPI {
    
    init(config: AcceleraConfig) {
        self.config = config
        self.client = WebClient(baseUrl: config.url)
    }
    
    var client: WebClient
    var config: AcceleraConfig
        
    @discardableResult
    func logFirebaseEvent(data: JSON, completion: @escaping (JSON?, NetworkError?) -> ()) -> URLSessionDataTask? {
        
        return client.load(path: "/firebase/webhooks", method: .post, params: data, headers: ["Authorization": config.systemToken]) { result, error in
            completion(result as? JSON, error)
        }
    }
    
    @discardableResult
    func logEvent(data: [String: Any], completion: @escaping (JSON?, NetworkError?) -> ()) -> URLSessionDataTask? {
        
        var params = JSON()
        params["data"] = data
        
        return client.load(path: "/events/event", method: .post, params: params, headers: ["Authorization": config.systemToken]) { result, error in
            completion(result as? JSON, error)
        }
    }
    
    @discardableResult
    func loadBanner(completion: @escaping (JSON?, NetworkError?) -> ()) -> URLSessionDataTask? {
        
        let params = JSON()
        
        return client.load(path: "/banner/template", method: .get, params: params, headers: ["Authorization": config.systemToken]) { result, error in
            completion(result as? JSON, error)
        }
    }
}
