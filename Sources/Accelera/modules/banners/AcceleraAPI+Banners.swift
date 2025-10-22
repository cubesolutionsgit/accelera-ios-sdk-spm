//
//  AcceleraAPI.swift
//  Accelera
//
//  Created by Evgeny Boganov on 15.08.2025.
//
#if ACCELERA_BANNERS_ENABLED

import Foundation


extension AcceleraAPI {
    
    /**
     Loads banner content from the backend.

     - Parameters:
       - data: Optional payload to send in the request body (e.g. user info, params).
       - completion: Completion handler with response data or network error.
     - Returns: The created `URLSessionDataTask`, if any.
     */
    @discardableResult
    public func loadBanner(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        
        return client.load(
            path: "/api/v1/content",
            method: .post,
            body: data,
            headers: ["Authorization": config.systemToken!],
            completion: completion
        )
    }
}

extension AcceleraAPIStub {
    @discardableResult
    func loadBanner(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        completion(nil, .server(status: 501, message: "logBanner is not implemented in stub"))
        return nil
    }
}

#endif
