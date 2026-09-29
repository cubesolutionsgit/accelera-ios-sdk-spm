//
//  AcceleraAPIProtocol.swift
//  Accelera
//
//  Created by Evgeny on 13.10.2025.
//

import Foundation

/// Protocol for all network interactions performed by Accelera.
/// You can override this protocol via `AcceleraDelegate.customAPI`.
public protocol AcceleraAPIProtocol: AnyObject {

    /// Sends user event analytics to backend.
    /// Implement only when a custom API handles user events.
    /// - Parameters:
    ///   - data: JSON data of the event.
    ///   - completion: Completion handler with response data or error.
    func logEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask?

    #if ACCELERA_BANNERS_ENABLED

    /// Loads remote banner configuration or data from backend.
    /// Implement only when a custom API handles banner content.
    /// - Parameters:
    ///   - data: Optional JSON payload to send with the request.
    ///   - completion: Completion handler with response data or error.
    func loadBanner(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask?

    #endif

    #if ACCELERA_NOTIFICATIONS_ENABLED

    /// Logs push notification related events to backend.
    /// Implement only when a custom API handles push events.
    /// - Parameters:
    ///   - data: JSON payload containing push event info.
    ///   - completion: Completion handler with response data or error.
    func logPushEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask?

    #endif
}

public extension AcceleraAPIProtocol {
    @discardableResult
    func logEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        completion(nil, .server(status: 501, message: "User event logging is not implemented"))
        return nil
    }
}

#if ACCELERA_BANNERS_ENABLED

public extension AcceleraAPIProtocol {
    @discardableResult
    func loadBanner(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        completion(nil, .server(status: 501, message: "Banner loading is not implemented"))
        return nil
    }
}

#endif

#if ACCELERA_NOTIFICATIONS_ENABLED

public extension AcceleraAPIProtocol {
    /// Allows custom APIs without push support to omit this method.
    @discardableResult
    func logPushEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask? {
        completion(nil, .server(status: 501, message: "Push event logging is not implemented"))
        return nil
    }
}

#endif
