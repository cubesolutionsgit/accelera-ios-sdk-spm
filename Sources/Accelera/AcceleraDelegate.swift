//
//  AcceleraDelegate.swift
//  Accelera
//
//  Created by Evgeny Boganov on 11.08.2022.
//

import UIKit

/// Delegate protocol for handling events, actions, logging, and custom API override from Accelera.
public protocol AcceleraDelegate: AnyObject {
    
    /// Called when the library wants to log a message.
    /// - Parameter message: The log string.
    func log(_ message: String)

    /// Called when the library wants to report an error.
    /// - Parameter error: The error string.
    func error(_ error: String)

    /// Optional custom API implementation override.
    /// Return your own conforming instance if you want to bypass the default `AcceleraAPI`.
    var customAPI: AcceleraAPIProtocol? { get }

    /// Handles incoming deep links or internal URLs.
    /// - Parameter url: The URL to handle.
    func handle(url: URL)

    /// Handles custom action strings triggered by banners or other modules.
    /// - Parameter action: Action identifier string.
    func action(action: String)

    /// Handles custom action strings with parsed payload from the event body.
    /// - Parameters:
    ///   - action: Action identifier string.
    ///   - params: Query parameters extracted from the action URL.
    ///   - meta: Optional metadata attached to the rendered content.
    func action(action actionName: String, params: [String: String], meta: Any?)
}

public extension AcceleraDelegate {

    /// Default log implementation — prints to console.
    func log(_ message: String) {
        print(message)
    }

    /// Default error implementation — prints to console.
    func error(_ error: String) {
        print(error)
    }

    /// Default custom API — none.
    var customAPI: AcceleraAPIProtocol? { nil }

    /// Default URL handler — opens external links via `UIApplication.shared`.
    func handle(url: URL) {
        if url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url)
        } else if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            error("Can't open url: \(url)")
        }
    }

    /// Default action handler — logs the action name.
    func action(action: String) {
        log("Banner action: \(action)")
    }

    /// Backward-compatible action handler that falls back to the legacy API.
    func action(action actionName: String, params: [String: String], meta: Any?) {
        self.action(action: actionName)
    }
}
