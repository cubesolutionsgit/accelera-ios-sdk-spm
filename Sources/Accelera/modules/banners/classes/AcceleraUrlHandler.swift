//
//  AcceleraUrlHandler.swift
//  Accelera
//
//  Created by Evgeny on 20.09.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit
import DivKit

final class AcceleraUrlHandler: DivUrlHandler {
    private weak var hostVC: UIViewController?
    private weak var originContext: AcceleraAttachedContentContext?
    private let jsonData: Data

    init(presentingViewController: UIViewController, jsonData: Data, originContext: AcceleraAttachedContentContext? = nil) {
        self.hostVC = presentingViewController
        self.jsonData = jsonData
        self.originContext = originContext
    }

    func handle(_ url: URL, sender: AnyObject?) {
        handle(url, meta: jsonData.meta ?? [:], sourceCardId: nil)
    }

    func handle(_ url: URL, info: DivActionInfo, sender: AnyObject?) {
        let meta = (hostVC as? AcceleraFullscreenViewController)?.currentMeta() ?? jsonData.meta ?? [:]
        handle(url, meta: meta, sourceCardId: info.cardId)
    }

    private func handle(_ url: URL, meta: Any, sourceCardId: DivCardID?) {
        Accelera.shared.log("Divkit action: \(url.absoluteString)")
        guard url.scheme == "div-action" else { return }

        let actionType = url.host ?? ""
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let actionParams: [String: String] = queryItems
            .reduce(into: [:]) { $0[$1.name] = $1.value }
        
        let payload: [String: Any] = [
            "event": actionType,
            "params": actionParams,
            "meta": meta
        ]
        
        if !queryItems.contains(where: { $0.name == "ignore" }) {
            Accelera.shared.logEvent(event: payload.asData)
        }
        
        switch actionType {
        case "fullscreen":
            guard let id = URLComponents(string: url.absoluteString)?
                .queryItems?
                .first(where: { $0.name == "id" })?.value else { return }
            
            let vc = AcceleraFullscreenViewController(
                jsonData: jsonData,
                entryId: id,
                originContext: originContext,
                sourceCardId: sourceCardId
            )
            vc.modalPresentationStyle = .overFullScreen
            hostVC?.present(vc, animated: true)
            
        case "link":
            if let encodedValue = actionParams["url"] {
                let decoded = encodedValue.removingPercentEncoding ?? encodedValue
                if let finalURL = URL(string: decoded) {
                    Accelera.shared.handle(url: finalURL)
                } else {
                    Accelera.shared.error("Could not construct URL from: \(decoded.debugDescription)")
                }
            } else {
                Accelera.shared.error("No 'url' parameter found in link action")
            }
            
        case "close":
            if let fullscreenVC = hostVC as? AcceleraFullscreenViewController {
                fullscreenVC.closeFullscreen()
            } else {
                originContext?.remove()
            }

        case "refresh":
            originContext?.load()
            
        default:
            break
        }
    }
}

#endif
