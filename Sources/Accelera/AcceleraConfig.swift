//
//  AcceleraConfig.swift
//  Accelera
//
//  Created by Evgeny Boganov on 15.08.2022.
//

import Foundation

/// Library configuration
public struct AcceleraConfig: Codable {
    
    /// System URL provided by Accelera.
    public let url: String?
    
    /// Application token provided by Accelera
    public let systemToken: String?

    /// Optional user info (string or JSON).
    public internal(set) var userInfo: String?

    /**
     Initializes configuration.

     You can skip all parameters if you want to handle networking manually.

     - Parameters:
        - url: system URL provided by Accelera
        - systemToken: optional application token provided by Accelera.
        - userInfo: optional user info (used by SDK only).
     */
    public init(url: String? = nil, systemToken: String? = nil, userInfo: String? = nil) {
        self.systemToken = systemToken
        self.url = url
        self.userInfo = userInfo
    }
}
