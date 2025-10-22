//
//  AcceleraAPI.swift
//  Accelera
//
//  Created by Evgeny Boganov on 15.08.2022.
//

import Foundation

final class AcceleraAPI: AcceleraAPIProtocol {
    init(config: AcceleraConfig) {
        self.config = config
        self.client = WebClient(baseUrl: config.url!)
    }

    let client: WebClient
    let config: AcceleraConfig
    
    @discardableResult
    public func logEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        client.load(
            path: "/api/v1/events",
            method: .post,
            body: data,
            headers: ["Authorization": config.systemToken!],
            completion: completion
        )
    }
}

final class AcceleraAPIStub: AcceleraAPIProtocol {
    @discardableResult
    public func logEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        completion(nil, .server(status: 501, message: "logEvent is not implemented in stub"))
        return nil
    }
}
