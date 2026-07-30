#if ACCELERA_BANNERS_ENABLED

import SwiftUI
import UIKit

protocol AcceleraContentSizeInvalidating: AnyObject {
    func acceleraContentSizeDidChange()
}

/// A SwiftUI wrapper for an Accelera UIKit content placeholder whose height
/// follows the content attached to it.
///
/// Use the view passed to `onViewCreated` with
/// `Accelera.attachContentPlaceholder(to:with:)`.
@available(iOS 13.0, *)
public struct AcceleraAutoHeightPlaceholderWrapper: UIViewRepresentable {
    private let onVisibilityChanged: ((Bool) -> Void)?
    private let onViewCreated: (UIView) -> Void

    public init(
        onVisibilityChanged: ((Bool) -> Void)? = nil,
        onViewCreated: @escaping (UIView) -> Void
    ) {
        self.onVisibilityChanged = onVisibilityChanged
        self.onViewCreated = onViewCreated
    }

    public func makeUIView(context: Context) -> UIView {
        let view = SizingView(onVisibilityChanged: onVisibilityChanged)
        DispatchQueue.main.async {
            onViewCreated(view)
        }
        return view
    }

    public func updateUIView(_ uiView: UIView, context: Context) {}

    private final class SizingView: UIView, AcceleraContentSizeInvalidating {
        private let onVisibilityChanged: ((Bool) -> Void)?
        private var height: CGFloat = 0
        private var lastReportedVisibility: Bool?

        init(onVisibilityChanged: ((Bool) -> Void)?) {
            self.onVisibilityChanged = onVisibilityChanged
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override var intrinsicContentSize: CGSize {
            CGSize(width: UIView.noIntrinsicMetric, height: height)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            updateHeight()
        }

        func acceleraContentSizeDidChange() {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.setNeedsLayout()
                self.layoutIfNeeded()
                self.updateHeight()
            }
        }

        private func updateHeight() {
            guard bounds.width > 0 else { return }

            let newHeight = max(0, ceil(subviews.map {
                $0.systemLayoutSizeFitting(
                    CGSize(width: bounds.width, height: UIView.layoutFittingCompressedSize.height),
                    withHorizontalFittingPriority: .required,
                    verticalFittingPriority: .fittingSizeLevel
                ).height
            }.max() ?? 0))

            reportVisibilityIfNeeded(newHeight > 0)

            guard abs(newHeight - height) > 0.5 else { return }
            height = newHeight

            DispatchQueue.main.async { [weak self] in
                self?.invalidateIntrinsicContentSize()
            }
        }

        private func reportVisibilityIfNeeded(_ isVisible: Bool) {
            guard lastReportedVisibility != isVisible else { return }
            lastReportedVisibility = isVisible

            DispatchQueue.main.async { [onVisibilityChanged] in
                onVisibilityChanged?(isVisible)
            }
        }
    }
}

#endif
