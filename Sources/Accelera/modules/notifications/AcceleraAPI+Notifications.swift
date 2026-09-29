//
//  AcceleraAPI.swift
//  Accelera
//
//  Created by Evgeny Boganov on 18.08.2022.
//

#if ACCELERA_NOTIFICATIONS_ENABLED

import Foundation

extension AcceleraAPI {
    /**
     Sends push notification event to the backend (e.g. delivery tracking).

     - Parameters:
       - data: JSON payload with push event data.
       - completion: Callback with response data or `NetworkError`.
     - Returns: Created `URLSessionDataTask` if the request was started.
     */
    @discardableResult
    public func logPushEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        client.load(
            path: "/firebase/webhooks",
            method: .post,
            body: data,
            headers: ["Authorization": config.systemToken!],
            completion: completion
        )
    }
}

extension AcceleraAPIStub {
    @discardableResult
    func logPushEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        completion(nil, .server(status: 501, message: "logPushEvent is not implemented in stub"))
        return nil
    }
}

#endif
