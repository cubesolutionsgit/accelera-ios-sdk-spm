//
//  Accelera.swift
//  Accelera
//
//  Created by Evgeny Boganov on 11.08.2022.
//

import Foundation
import UIKit

/// Main library class
public final class Accelera: NSObject {

    /// Singleton to communicate with the library.
    public static let shared = Accelera()

    private override init() {
        super.init()
    }

    var config: AcceleraConfig?
    
    private static let maxBufferedLogCount = 200
    private var _log = [String]()

    /// Sets delegate for library events. See ``AcceleraDelegate``
    weak public var delegate: AcceleraDelegate? {
        didSet {
            runOnMain { [weak self, weak delegate] in
                guard let self, let delegate else { return }
                _log.forEach { delegate.log($0) }
                _log.removeAll(keepingCapacity: true)
            }
        }
    }

    /**
     Call this method to set up the library. See ``AcceleraConfig`` for parameters. Can be empty when api delegate is set. See ``AcceleraDelegate``
     */
    public func configure(config: AcceleraConfig) {
        self.config = config
        if let data = try? JSONEncoder().encode(config),
           let json = String(data: data, encoding: .utf8) {
            log("Accelera configured with config:\n\(json)")
        } else {
            error("Accelera configured (failed to encode config to JSON)")
        }
        
        #if ACCELERA_BANNERS_ENABLED
        configureBannersModule()
        #endif
        
        #if ACCELERA_NOTIFICATIONS_ENABLED
        configureNotificationsModule()
        #endif
    }

    /**
     Set user info.
     - Parameter userInfo: string or valid JSON string of the user information that you want to share with Accelera.
     */
    public func setUserInfo(_ userInfo: String?) {
        guard var config else {
            error("Can't set userInfo — Accelera is not configured!")
            return
        }

        config.userInfo = (mergeJSON(old: config.userInfo, new: userInfo) as? String) ?? userInfo
        self.config = config

        log("User info set to: \(config.userInfo ?? "nil")")

        #if ACCELERA_NOTIFICATIONS_ENABLED
        tokenOrUserInfoUpdated()
        #endif
    }

    /**
     Logs event for user activity.
     - Parameter event: event in json data
     */
    public func logEvent(event data: Data) {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let eventName = json["event"] as? String {
            let params = json["params"] as? [String: String] ?? [:]
            let meta = json["meta"]
            runOnMain { [weak self] in
                self?.delegate?.action(action: eventName, params: params, meta: meta)
            }
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            log("Logging event: \(jsonString)")
        } else {
            log("Logging event: <invalid UTF-8 data>")
        }

        self.api.logEvent(data: addUserInfo(to: data)) { [weak self] result, error in
            if let error {
                self?.error("Event error \(error.localizedDescription)")
            } else {
                self?.log("Event sent successfully")
            }
        }
    }
    
    func log(_ message: Any) {
        emit("[Accelera] \(message)", isError: false)
    }
    
    func error(_ error: Any) {
        emit("[Accelera] Error: \(error)", isError: true)
    }
    
    func handle(url: URL) {
        log("Handling URL: \(url)")
        runOnMain { [weak self] in self?.delegate?.handle(url: url) }
    }

    private func emit(_ message: String, isError: Bool) {
        runOnMain { [weak self] in
            guard let self else { return }
            if let delegate {
                isError ? delegate.error(message) : delegate.log(message)
                return
            }
            if _log.count >= Self.maxBufferedLogCount {
                _log.removeFirst()
            }
            _log.append(message)
        }
    }

    private func runOnMain(_ action: @escaping () -> Void) {
        Thread.isMainThread ? action() : DispatchQueue.main.async(execute: action)
    }

    var api: AcceleraAPIProtocol {
        if let existing = _api { return existing }
        
        if let customAPI = delegate?.customAPI {
            _api = customAPI
            return customAPI
        }
        
        if let config = self.config, config.url != nil {
            let api = AcceleraAPI(config: config)
            _api = api
            return api
        }
        
        error(
            """
            API initialization failed.
            Missing configuration and no custom API provided by delegate.
            Set AcceleraConfig via configure(...) or implement AcceleraDelegate.customAPI.
            """
        )
        
        let stub = AcceleraAPIStub()
        _api = stub
        return stub
    }
    
    private var configured: Bool {
        return config != nil
    }
    
    func addUserInfo(to data: Data?) -> Data? {
        var payload: [String: Any] = [:]

        if let data,
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            payload = dict
        }

        if let userInfo = config?.userInfo,
           let infoData = userInfo.data(using: .utf8),
           let infoDict = try? JSONSerialization.jsonObject(with: infoData) {
            payload["userInfo"] = infoDict
        }
        
        return try? JSONSerialization.data(withJSONObject: payload)
    }

    private var _api: AcceleraAPIProtocol?
}
