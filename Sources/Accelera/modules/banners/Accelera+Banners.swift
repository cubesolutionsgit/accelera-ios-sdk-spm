//
//  Accelera+Banners.swift
//  Accelera
//
//  Created by Evgeny Boganov on 15.08.2025.
//

#if ACCELERA_BANNERS_ENABLED
import UIKit
import DivKit
import DivKitExtensions

extension Accelera {
    
    func configureBannersModule() {
        DivKitLogger.isEnabled = true
        
        DivKitLogger.setLogger { [weak self] level, message in
            guard let self else { return }
            switch level {
            case .error:
                self.error("Divkit Error: " + message)
            case .warning:
                self.log("Dikit warning: " + message)
            }
        }
    }

    /// Loads and attaches banner or stories content into the given container.
    ///
    /// - Parameters:
    ///   - container: The `UIView` that will host the content.
    ///   - data: Optional request parameters to be sent to the backend.
    public func attachContentPlaceholder(
        to container: UIView,
        with data: Data? = nil
    ) {
        container.subviews.forEach { $0.removeFromSuperview() }
        
        guard let hostVC = container.parentViewController else {
            error("No view controller to present from.")
            return
        }
        
        loadPreparedContent(data: data, failureContext: "content") { [weak self, weak container] jsonData in
            guard let self, let container else { return }

            let divView = DivKitSetup.makeView(
                from: jsonData,
                presentingViewController: hostVC
            ).view

            container.addSubview(divView)

            NSLayoutConstraint.activate([
                divView.topAnchor.constraint(equalTo: container.topAnchor),
                divView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                divView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                divView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])

            container.layoutIfNeeded()

            let source = DivViewSource(
                kind: .data(jsonData),
                cardId: DivCardID(rawValue: UUID().uuidString)
            )

            Task { [weak self, weak divView] in
                guard let self, let divView else { return }

                await divView.setSource(source)
                self.logEvent(event: ["event": "view", "meta": jsonData.meta].asData)

                if jsonData.closable == true {
                    let closeButton = CloseButtonView { [weak self, weak divView] in
                        self?.logEvent(event: ["event": "close", "meta": jsonData.meta].asData)
                        divView?.removeFromSuperview()
                    }

                    divView.addSubview(closeButton)
                    divView.bringSubviewToFront(closeButton)

                    NSLayoutConstraint.activate([
                        closeButton.topAnchor.constraint(equalTo: divView.safeAreaLayoutGuide.topAnchor, constant: 8),
                        closeButton.trailingAnchor.constraint(equalTo: divView.trailingAnchor, constant: -8)
                    ])
                }
            }
        }
    }

    /// Loads and presents popup content over the current screen.
    ///
    /// The presenting view controller is resolved automatically from the active window.
    ///
    /// - Parameter data: Optional request parameters to be sent to the backend.
    public func showPopup(data: Data? = nil) {
        showPopup(from: nil, data: data)
    }

    /// Loads and presents popup content from the provided view controller.
    ///
    /// Use this overload when the host application needs explicit control over presentation.
    /// If `presentingViewController` is `nil`, the SDK resolves it automatically from the active window.
    ///
    /// - Parameters:
    ///   - presentingViewController: The view controller that should present the popup.
    ///   - data: Optional request parameters to be sent to the backend.
    public func showPopup(from presentingViewController: UIViewController?, data: Data? = nil) {
        loadPreparedContent(data: data, failureContext: "popup") { [weak self] jsonData in
            guard let self else { return }
            guard let hostVC = presentingViewController ?? UIApplication.shared.acceleraTopMostViewController() else {
                self.error("No view controller to present popup from.")
                return
            }

            let vc = AcceleraFullscreenViewController(jsonData: jsonData)
            vc.modalPresentationStyle = .overFullScreen
            hostVC.present(vc, animated: true)
        }
    }

    private func loadPreparedContent(
        data: Data?,
        failureContext: String,
        onReady: @MainActor @escaping (Data) -> Void
    ) {
        log("Loading \(failureContext) with params: \(String(data: data ?? Data(), encoding: .utf8) ?? "<invalid>")")

        self.api.loadBanner(data: addUserInfo(to: data)) { [weak self] result, error in
            guard let self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.error("Failed to load \(failureContext): \(error)")
                }
                return
            }

            guard let jsonData = result else {
                DispatchQueue.main.async {
                    self.error("Empty \(failureContext) JSON data from API")
                }
                return
            }

            self.log("\(failureContext.capitalized) loaded, preparing assets")

            Task.detached { [weak self] in
                guard let self else { return }

                do {
                    try await AcceleraAssetCache.prepare(jsonData) { value in
                        let percent = Int(value * 100)
                        print("\(failureContext.capitalized) cache progress: \(percent)%")
                    }
                } catch {
                    self.error("\(failureContext.capitalized) asset prepare failed: \(error). Proceeding without cache warmup")
                }

                await onReady(jsonData)
            }
        }
    }
}


#endif
