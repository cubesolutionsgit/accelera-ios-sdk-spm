//
//  Accelera+Notifications.swift
//  Accelera
//
//  Created by Evgeny on 18.08.2025.
//

#if ACCELERA_NOTIFICATIONS_ENABLED

import Foundation
import UIKit

private var tokenKey: UInt8 = 0
private var tokenProviderKey: UInt8 = 0

extension Accelera {
    
    func configureNotificationsModule() {
    }
    
    private var token: String? {
        get {
            objc_getAssociatedObject(self, &tokenKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &tokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            tokenOrUserInfoUpdated()
        }
    }

    private var tokenProvider: String? {
        get {
            objc_getAssociatedObject(self, &tokenProviderKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &tokenProviderKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     Sets a push notification token for Accelera notification tracking.
     The host app owns the concrete push SDK integration and passes the resulting token here.

     - Parameters:
       - token: Push notification token. Pass `nil` or an empty string to clear the current token.
       - provider: Push notification provider.
     */
    public func setPushToken(_ token: String?, provider: String) {
        guard let token, !token.isEmpty else {
            log("Clearing push token")
            tokenProvider = nil
            self.token = nil
            return
        }

        log("Setting push token for provider: \(provider)")
        tokenProvider = provider
        self.token = token
    }

    /**
     Call this method to notify Accelera when a push notification was opened.
     - Parameter userInfo: the payload received from the push notification
     */
    public func handlePushNotificationOpened(userInfo: [AnyHashable: Any]) {
        guard let messageId = userInfo["message_id"] ?? userInfo["gcm.message_id"] ?? userInfo["messageId"] else {
            return
        }

        logPushEvent(event: "clicked", data: ["message_id": messageId])
    }
    
    func tokenOrUserInfoUpdated() {
        log("Update push token or user")
        guard let token else { return }
        
        var payload: [String: Any] = ["token": token]
        if let tokenProvider {
            payload["provider"] = tokenProvider
        }

        if let clientString = config?.userInfo {
            if let clientData = clientString.data(using: .utf8),
               let clientJSON = try? JSONSerialization.jsonObject(with: clientData) {
                payload["client"] = clientJSON
            } else {
                payload["client"] = clientString
            }
        }

        logPushEvent(event: "token", data: payload)
    }

    internal func logPushEvent(event: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "event": event,
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "context": data
        ]
        
        self.log("Log push event \(payload)")
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            self.error("Failed to encode push event")
            return
        }
        
        self.api.logPushEvent(data: body) { [weak self] result, error in
            if let error {
                self?.error("Push event error: \(error.localizedDescription)")
            } else {
                self?.log("Push event sent (\(result?.count ?? 0) bytes)")
            }
        }
    }
}

#endif
