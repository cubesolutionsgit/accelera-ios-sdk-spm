//
//  StoryProgressBar.swift
//  Accelera
//
//  Created by Evgeny on 20.09.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit

final class StoryProgressBar: UIView {
    private let bgLayer = CALayer()
    private let fillLayer = CALayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        bgLayer.backgroundColor = UIColor.white.withAlphaComponent(0.3).cgColor
        fillLayer.backgroundColor = UIColor.white.cgColor
        layer.addSublayer(bgLayer)
        layer.addSublayer(fillLayer)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        bgLayer.frame = bounds
    }

    func setProgress(_ progress: CGFloat) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillLayer.frame = CGRect(
            x: 0, y: 0,
            width: bounds.width * progress,
            height: bounds.height
        )
        CATransaction.commit()
    }

    func reset() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillLayer.frame = .zero
        CATransaction.commit()
    }
}

#endif
