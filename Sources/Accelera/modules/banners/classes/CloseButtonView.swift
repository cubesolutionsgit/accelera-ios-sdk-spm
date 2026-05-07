//
//  CloseButtonView.swift
//  Accelera
//
//  Created by Evgeny on 20.09.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit

final class CloseButtonView: UIButton {

    private var onTap: (() -> Void)?

    init(target: Any?, action: Selector) {
        super.init(frame: .zero)
        configure()
        addTarget(target, action: action, for: .touchUpInside)
    }

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: .zero)
        configure()
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configure()
    }

    @objc private func handleTap() {
        onTap?()
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
