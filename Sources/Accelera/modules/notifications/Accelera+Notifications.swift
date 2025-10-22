//
//  Accelera+Notifications.swift
//  Accelera
//
//  Created by Evgeny on 18.08.2025.
//

#if ACCELERA_NOTIFICATIONS_ENABLED

import Foundation
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

private var tokenKey: UInt8 = 0

extension Accelera {
    
    func configureNotificationsModule() {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
    
    private var token: String? {
        get {
            objc_getAssociatedObject(self, &tokenKey) as? String
        }
        set {
            log("Setting token: \(newValue ?? "")")
            objc_setAssociatedObject(self, &tokenKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            tokenOrUserInfoUpdated()
        }
    }
    
    /**
     Call this method to notify Accelera when a push notification was opened.
     - Parameter userInfo: the payload received from the push notification
     */
    public func handlePushNotificationOpened(userInfo: [AnyHashable: Any]) {
        guard let messageId = userInfo["message_id"] else { return }
        logFirebaseEvent(event: "clicked", data: ["message_id": messageId])
    }
    
    func tokenOrUserInfoUpdated() {
        log("Update token or user")
        guard let token = token else { return }
        
        var payload: [String: Any] = ["token": token]

        if let clientString = config?.userInfo {
            if let clientData = clientString.data(using: .utf8),
               let clientJSON = try? JSONSerialization.jsonObject(with: clientData) {
                payload["client"] = clientJSON
            } else {
                payload["client"] = clientString
            }
        }

        logFirebaseEvent(event: "token", data: payload)
    }

    internal func logFirebaseEvent(event: String, data: [String: Any]) {
        let payload: [String: Any] = [
            "event": event,
            "deviceId": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "context": data
        ]
        
        self.log("Log firebase event \(payload)")
        
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            self.error("Failed to encode firebase event")
            return
        }
        
        self.api.logFirebaseEvent(data: body) { [weak self] result, error in
            if let error {
                self?.error("Firebase event error: \(error.localizedDescription)")
            } else {
                self?.log("Firebase event sent (\(result?.count ?? 0) bytes)")
            }
        }
    }
}

extension Accelera: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.token = fcmToken
    }
}

#endif
