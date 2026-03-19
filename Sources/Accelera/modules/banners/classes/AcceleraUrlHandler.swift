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
    private let jsonData: Data

    init(presentingViewController: UIViewController, jsonData: Data) {
        self.hostVC = presentingViewController
        self.jsonData = jsonData
    }

    func handle(_ url: URL, sender: AnyObject?) {
        Accelera.shared.log("Divkit action: \(url.absoluteString)")
        guard url.scheme == "div-action" else { return }

        let actionType = url.host ?? ""
        let actionParams: [String: String] = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .reduce(into: [:]) { $0[$1.name] = $1.value } ?? [:]
        
        let payload: [String: Any] = [
            "event": actionType,
            "params": actionParams,
            "meta": jsonData.meta ?? [:]
        ]
        
        Accelera.shared.logEvent(event: payload.asData)
        
        switch actionType {
        case "fullscreen":
            guard let id = URLComponents(string: url.absoluteString)?
                .queryItems?
                .first(where: { $0.name == "id" })?.value else { return }
            
            let vc = AcceleraFullscreenViewController(
                jsonData: jsonData,
                entryId: id,
            )
            vc.modalPresentationStyle = .fullScreen
            hostVC?.present(vc, animated: true)
            
        case "link":
            if let range = url.absoluteString.range(of: "url=") {
                let encodedValue = String(url.absoluteString[range.upperBound...])
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
            hostVC?.dismiss(animated: true)
            
        default:
            break
        }
    }
}

#endif
