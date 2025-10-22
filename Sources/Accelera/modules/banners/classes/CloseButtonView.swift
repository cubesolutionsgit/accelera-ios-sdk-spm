//
//  CloseButtonView.swift
//  Accelera
//
//  Created by Evgeny on 20.09.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit

final class CloseButtonView: UIButton {

    init(target: Any?, action: Selector) {
        super.init(frame: .zero)
        configure()
        addTarget(target, action: action, for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    private func configure() {
        setTitle("✕", for: .normal)
        tintColor = .white
        titleLabel?.font = .boldSystemFont(ofSize: 12)
        backgroundColor = UIColor.black.withAlphaComponent(0.2)
        layer.cornerRadius = 12
        translatesAutoresizingMaskIntoConstraints = false
        layer.zPosition = 999
        NSLayoutConstraint.activate([
            self.widthAnchor.constraint(equalToConstant: 24),
            self.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

#endif
