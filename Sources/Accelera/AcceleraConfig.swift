//
//  AcceleraConfig.swift
//  Accelera
//
//  Created by Evgeny Boganov on 15.08.2022.
//

import Foundation

/// Banner type
public enum AcceleraBannerType: String {
    /// Small banner that will be added on top of the screen
    case notification
    /// Middle size banner that will be displayed on top of the screen
    case top
    /// Middle size banner that will be centered
    case center
    /// Full screen banner
    case fullscreen
}

/// Library configuration
public struct AcceleraConfig {
    /**
     Initializes configuration
     
     - Parameters:
         - systemToken: application token provided by Accelera.
         - url: system url provided by Accelera.
         - userInfo: string or valid JSON string of the user information that you want to share with Accelera.
     */
    public init(systemToken: String, url: String, userInfo: String? = nil) {
        self.systemToken = systemToken
        self.url = url
        self.userInfo = userInfo
    }
    
    let systemToken: String
    let url: String
    var userInfo: String?
}
