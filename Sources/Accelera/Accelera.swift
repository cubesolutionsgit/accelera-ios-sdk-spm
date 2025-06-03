//
//  Accelera.swift
//  Accelera
//
//  Created by Evgeny Boganov on 11.08.2022.
//

import Foundation
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications


/// Delegate that informs about banner events
public protocol AcceleraDelegate: AnyObject {
    /**
     When view is ready delegate calls this method
     - Parameters:
         - view: UIView that was prepared by the library
         - type: Type of the banner. See ``AcceleraBannerType``
     */
    func bannerViewReady(view: UIView, type: AcceleraBannerType)
    
    /**
     If banner doesn't exist then library will call this delegate method
     */
    func noBannerView()
    
    /**
     Called when close button was pressed
     - Returns: Optional boolean. If true library will remove banner from its superview automatically
     */
    @discardableResult func bannerViewClosed() -> Bool?
    
    /**
     Called when any action button was pressed
     - Parameters:
          - action: optional string set as button action
     - Returns: Optional boolean. If true library will remove banner from its superview automatically
     */
    @discardableResult func bannerViewAction(action: String?) -> Bool?
    
    /**
     Called when library adds messages to log. Useful for debugging.
     - Parameters:
            - message: log message
     */
    func log(_ message: String)
}

public extension AcceleraDelegate {
    func bannerViewReady(view: UIView, type: AcceleraBannerType) {
        
    }
    
    func noBannerView() {
        
    }
    
    @discardableResult func bannerViewClosed() -> Bool? {
        return true
    }
    
    @discardableResult func bannerViewAction(action: String?) -> Bool? {
        return true
    }
    
    func log(_ message: String) {
        print(message)
    }
}

/// Main library class
public final class Accelera: NSObject {
        
    /**
     Singleton to communicate with library. You will need to call 
     ``configure(config:)`` before actively using it.
     */
    public static let shared = Accelera();
    
    override init() {
        super.init()
        self.viewController.delegate = self
    }
    
    private var config: AcceleraConfig?
    
    private var _log = [String]()
    
    private var _token: String?
    private var token: String? {
        get {
            return _token
        }
        set {
            log("Setting token: \(newValue ?? "")")
            _token = newValue
            tokenOrUserInfoUpdated()
        }
    }
    
    private var _api: AcceleraAPI?
    private var api: AcceleraAPI {
        get {
            if let api = self._api {
                return api
            }
            let api = AcceleraAPI(config: self.config!)
            self._api = api
            return api
        }
    }
    
    private let queue = DispatchQueue(label: "ai.accelera.ios", qos: .background)

    private var _viewController: AcceleraBannerViewController?
    private var viewController: AcceleraBannerViewController {
        get {
            if let vc = self._viewController {
                return vc
            }
            let vc = AcceleraBannerViewController()
            vc.delegate = self
            self._viewController = vc
            return vc
        }
    }
    
    private var configured: Bool {
        get {
            return config != nil
        }
    }
    
    /**
     Call this method to set up the library. See ``AcceleraConfig`` for parameters
     */
    public func configure(config: AcceleraConfig) {
        self.config = config
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        log("Accelera configured")
    }
    
    /**
     Set user info
     - Parameters:
            - userInfo: string or valid JSON string of the user information that you want to share with Accelera.
     */
    public func setUserInfo(_ userInfo: String) {
        if configured {
            log("Setting user info: \(userInfo)")
            self.config!.userInfo = userInfo
            tokenOrUserInfoUpdated()
        } else {
            log("Can't set userInfo when Accelera is not configured!")
        }
    }
    
    func log(_ message: Any) {
        _log.append("\(message)")
        DispatchQueue.main.async {
            self.delegate?.log("\(message)")
        }
    }
    
    weak public var _delegate: AcceleraDelegate?
    /**
     Sets delegate for library events. See ``AcceleraDelegate``
     */
    weak public var delegate: AcceleraDelegate? {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
            // send logs if delegate was set after we have some
            for msg in _log {
                _delegate?.log("\(msg)")
            }
        }
    }
}

extension Accelera: AcceleraViewDelegate {
    func onError(_ error: Error) {
        self.delegate?.noBannerView()
    }
    
    func onReady(_ view: UIView, type: AcceleraBannerType) {
        DispatchQueue.main.async {
            self.delegate?.bannerViewReady(view: view, type: type)
        }
    }
    
    func onAction(_ action: String?) {
        let closeAutomatically = self.delegate?.bannerViewAction(action: action)
        if closeAutomatically == true {
            viewController.view?.removeFromSuperview()
            viewController.clear()
        }
    }
    
    func onAdded() {
        self.logEvent(string: "{\"event\": \"shown\"}")
    }
    
    func onClose() {
        self.logEvent(string: "{\"event\": \"closed\"}")
        let closeAutomatically = self.delegate?.bannerViewClosed()
        if closeAutomatically == true {
            viewController.view?.removeFromSuperview()
            viewController.clear()
        }
    }
}

// BASE METHODS

extension Accelera {
    /**
     Logs event for user activity
     - Parameters:
         - data: Valid JSON string that describes the event
     */
    public func logEvent(string: String) {
        log("log event: \(string)")
        self.queue.async {
            // TODO: cache if network is not available
            if let data = string.data(using: .utf8),
               let object = try? JSONSerialization.jsonObject(with: data, options: []),
               let json = object as? JSON {
                self.api.logEvent(data: json) { [weak self] json, error in
                    self?.queue.async {
                        if let error = error {
                            self?.log(error.localizedDescription)
                        } else if let json = json {
                            self?.log(json)
                        }
                    }
                }
            } else {
                self.log("bad json sent to log event")
            }
        }
    }
}

// BANNERS

extension Accelera {
    /**
     Asks if any type of banner for current user exists
     will call on of the delegate methods in any case. See ``AcceleraDelegate``
     */
    public func loadBanner() {
        self.queue.async {
            self.api.loadBanner() { [weak self] json, error in
                self?.queue.async {
                    guard let json = json, let status = json["status"] as? Int, status == 1, let html = json["template"] as? String else {
                        self?.delegate?.noBannerView()
                        return
                    }
                    
                    var bannerType: AcceleraBannerType = .top
                    
                    if let data = json["data"] as? [String: Any],
                       let type = data["type"] as? String,
                       let bt = AcceleraBannerType(rawValue: type) {
                        bannerType = bt
                    }
                    
                    // some crazy code for switching between threads
                    self?.queue.async {
                        self?.viewController.parseHTML(html: html) {
                            DispatchQueue.main.async {
                                self?.viewController.createViews {
                                    self?.queue.async {
                                        self?.viewController.prepareViews {
                                            DispatchQueue.main.async {
                                                self?.viewController.renderViews(type: bannerType) {
                                                    
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /**
     Will return banner view if it was loaded previously.
     - Returns: Tuple with **view** as banner view and **type** as its type.
     This is just a convenience method. Need to call ``loadBanner()`` first
     */
    public func getBannerView() -> (view: UIView, type: AcceleraBannerType)? {
        guard let view = viewController.view else {
            return nil
        }
        
        return (view: view, type: viewController.bannerType)
    }
}

// PUSH NOTIFICATIONS

extension Accelera: MessagingDelegate {
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.token = fcmToken
    }
}

extension Accelera {
    
    private func tokenOrUserInfoUpdated() {
        log("Update token or user")
        if let token = token {
            var data = JSON()
            data["token"] = token
            data["client"] = self.config?.userInfo
                        
            if let client = self.config?.userInfo,
               let clientObject = client.data(using: .utf8) {
                do {
                    data["client"] = try JSONSerialization.jsonObject(with: clientObject, options: [])
                } catch {
                    data["client"] = self.config?.userInfo
                }
            }
            
            logFirebaseEvent(event: "token", data: data)
        }
    }
    
    private func logFirebaseEvent(event: String, data: JSON) {
        self.queue.async {
            var json = JSON()
            json["event"] = event
            json["deviceId"] = UIDevice.current.identifierForVendor?.uuidString
            json["context"] = data
            self.log("Log firebase event \(json)")
            self.api.logFirebaseEvent(data: json) { [weak self] json, error in
                self?.queue.async {
                    if let error = error {
                        self?.log(error.localizedDescription)
                    } else if let json = json {
                        self?.log("Result: \(json)")
                    }
                }
            }
        }
    }
    
    /**
     Call this method to notify Accelera when push notifications was opened
     */
    public func handlePushNotificationOpened(userInfo: [AnyHashable: Any]) {
        if let messageId = userInfo["message_id"] {
            var data = JSON()
            data["message_id"] = messageId
            logFirebaseEvent(event: "clicked", data: data)
        }
    }
}
