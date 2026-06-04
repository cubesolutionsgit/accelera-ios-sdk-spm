//
//  UIApplication+.swift
//  Accelera
//
//  Created by OpenAI on 01.06.2026.
//

import UIKit

extension UIApplication {
    func acceleraTopMostViewController() -> UIViewController? {
        let allScenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = allScenes
            .filter { $0.activationState == .foregroundActive }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
            ?? allScenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        var top = keyWindow?.rootViewController

        while true {
            if let presented = top?.presentedViewController {
                top = presented
            } else if let navigation = top as? UINavigationController {
                top = navigation.visibleViewController
            } else if let tabBar = top as? UITabBarController {
                top = tabBar.selectedViewController
            } else {
                return top
            }
        }
    }
}
