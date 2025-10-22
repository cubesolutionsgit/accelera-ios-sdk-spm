//
//  PassthroughZoneView.swift
//  Accelera
//
//  Created by Evgeny on 20.09.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit

final class PassthroughZoneView: UIView {
    weak var divView: UIView?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let divView else {
            return super.hitTest(point, with: event)
        }

        let pointInDiv = convert(point, to: divView)
        if let hit = divView.hitTest(pointInDiv, with: event) {
            let className = String(describing: type(of: hit)).lowercased()

            if hit is UIControl ||
               hit is UIButton ||
               hit !== divView && (hit.gestureRecognizers?.isEmpty == false ||
               className.contains("button") ||
               className.contains("touchable")) {
                return nil
            }
        }

        return super.hitTest(point, with: event)
    }
}

#endif
