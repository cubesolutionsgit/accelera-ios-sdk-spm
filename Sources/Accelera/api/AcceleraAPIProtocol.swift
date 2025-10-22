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
    /// - Parameters:
    ///   - data: JSON data of the event.
    ///   - completion: Completion handler with response data or error.
    func logEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask?

    #if ACCELERA_BANNERS_ENABLED

    /// Loads remote banner configuration or data from backend.
    /// Only available if banners modules is installed.
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
    /// Only available if notifications module is installed.
    /// - Parameters:
    ///   - data: JSON payload containing Firebase-related info.
    ///   - completion: Completion handler with response data or error.
    func logFirebaseEvent(
        data: Data?,
        completion: @escaping (Data?, NetworkError?) -> Void
    ) -> URLSessionDataTask?

    #endif
}
