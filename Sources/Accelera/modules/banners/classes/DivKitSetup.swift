//
//  DivKitSetup.swift
//  Accelera
//
//  Created by Evgeny on 20.09.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit
import DivKit
import DivKitExtensions
import Lottie
import LayoutKit
import VGSL

final class DivKitSetup {

    // MARK: - Public API

    static func makeView(
        from jsonData: Data,
        presentingViewController: UIViewController,
    ) -> DivView {
        let components = makeComponents(
            presentingViewController: presentingViewController,
            jsonData: jsonData
        )

        let divView = DivView(divKitComponents: components)
        divView.translatesAutoresizingMaskIntoConstraints = false
        return divView
    }

    // MARK: - Private

    private static func makeComponents(
        presentingViewController: UIViewController,
        jsonData: Data
    ) -> DivKitComponents {
        let requestPerformer = URLRequestPerformer(urlTransform: nil)
        let requester = NetworkURLResourceRequester(performer: requestPerformer)
        let lottieHandler = LottieExtensionHandler(
            factory: LottieAnimationFactory(),
            requester: requester
        )

        let urlHandler = AcceleraUrlHandler(
            presentingViewController: presentingViewController,
            jsonData: jsonData
        )

        return DivKitComponents(
            extensionHandlers: [lottieHandler],
            fontProvider: CustomFontProvider(),
            urlHandler: urlHandler
        )
    }

    // MARK: - FontProvider

    private final class CustomFontProvider: DivFontProvider {
        func font(family: String, weight: DivFontWeight, size: CGFloat) -> UIFont {
            UIFont(name: family, size: size) ?? .systemFont(ofSize: size)
        }
    }

    // MARK: - Lottie

    private final class LottieAnimationFactory: AsyncSourceAnimatableViewFactory {
        func createAsyncSourceAnimatableView(
            withMode mode: AnimationRepeatMode,
            repeatCount count: Float
        ) -> AsyncSourceAnimatableView {
            let animationView = LottieAnimationView()
            switch mode {
            case .restart:
                animationView.loopMode = count == -1 ? .loop : .repeat(count)
            case .reverse:
                animationView.loopMode = count == -1 ? .autoReverse : .repeatBackwards(count / 2)
            }
            return animationView
        }
    }
}

// MARK: - Lottie Extension Protocol Conformance

extension LottieAnimationView: DivKitExtensions.AsyncSourceAnimatableView {
    public func play() {
        self.play(completion: nil)
        self.forceDisplayUpdate()
    }

    public func setSourceAsync(_ source: AnimationSourceType) async {
        guard let source = source as? LottieAnimationSourceType else { return }

        animation = await Task.detached(priority: .userInitiated) {
            switch source {
            case let .data(data):
                try? JSONDecoder().decode(LottieAnimation.self, from: data)
            case let .json(json):
                try? LottieAnimation(dictionary: json)
            }
        }.value
    }
}

#endif
