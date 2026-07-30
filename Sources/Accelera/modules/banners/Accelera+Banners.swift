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
    /// - Returns: A handle that can be used to manage the attached content.
    @discardableResult
    public func attachContentPlaceholder(
        to container: UIView,
        with data: Data? = nil
    ) -> AcceleraContentHandle {
        let context = AcceleraAttachedContentContext(container: container, data: data)
        acceleraContentContexts.setObject(context, forKey: container)
        context.load(isInitialLoad: true)
        return AcceleraContentHandle(context: context)
    }

    /// Reloads content in the given container using the original request parameters.
    ///
    /// Use this method when you do not keep the handle returned by `attachContentPlaceholder(to:with:)`.
    ///
    /// - Parameter container: The container previously passed to `attachContentPlaceholder(to:with:)`.
    public func refreshContentPlaceholder(in container: UIView) {
        guard let context = acceleraContentContexts.object(forKey: container) else { log("No content placeholder found to refresh"); return }
        context.load()
    }

    /// Removes attached content from the given container.
    ///
    /// Use this method when you do not keep the handle returned by `attachContentPlaceholder(to:with:)`.
    ///
    /// - Parameter container: The container previously passed to `attachContentPlaceholder(to:with:)`.
    public func detachContentPlaceholder(from container: UIView) {
        guard let context = acceleraContentContexts.object(forKey: container) else { log("No content placeholder found to detach"); return }
        context.detach()
        acceleraContentContexts.removeObject(forKey: container)
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
        loadPreparedContent(data: data) { [weak self] jsonData in
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

    fileprivate func loadPreparedContent(
        data: Data?,
        onReady: @MainActor @escaping (Data) -> Void,
        onComplete: @MainActor @escaping () -> Void = {}
    ) {
        log("Loading content with params: \(String(data: data ?? Data(), encoding: .utf8) ?? "<invalid>")")

        self.api.loadBanner(data: addUserInfo(to: data)) { [weak self] result, error in
            guard let self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.error("Failed to load content: \(error)")
                    onComplete()
                }
                return
            }

            guard let jsonData = result, !jsonData.isEmpty else {
                DispatchQueue.main.async {
                    self.log("No content data from API")
                    onComplete()
                }
                return
            }

            self.log("Content loaded, preparing assets")

            Task.detached { [weak self] in
                guard let self else { return }

                do {
                    try await AcceleraAssetCache.prepare(jsonData) { value in
                        let percent = Int(value * 100)
                        print("Content cache progress: \(percent)%")
                    }
                } catch {
                    self.error("Content asset prepare failed: \(error). Proceeding without cache warmup")
                }

                await onReady(jsonData)
                await onComplete()
            }
        }
    }
}

public final class AcceleraContentHandle {
    private weak var context: AcceleraAttachedContentContext?

    init(context: AcceleraAttachedContentContext) {
        self.context = context
    }

    /// Reloads content using the original request parameters.
    public func refresh() {
        context?.load()
    }

    /// Removes attached content from its container.
    public func detach() {
        context?.detach()
    }
}

private let acceleraContentContexts = NSMapTable<UIView, AcceleraAttachedContentContext>.weakToStrongObjects()

final class AcceleraAttachedContentContext: NSObject {
    private weak var container: UIView?
    private let data: Data?
    private var divView: DivView?
    private var divKitViewContext: DivKitViewContext?
    private var divKitComponents: DivKitComponents?
    private let variablesStorage = DivVariablesStorage()
    private var cardId: DivCardID?
    private var jsonData: Data?
    private var isRefreshing = false

    init(container: UIView, data: Data?) {
        self.container = container
        self.data = data
    }

    func load(isInitialLoad: Bool = false) {
        guard let container, !isRefreshing else { return }
        isRefreshing = true

        if isInitialLoad {
            container.subviews.forEach { $0.removeFromSuperview() }
        }

        guard let hostVC = container.parentViewController else {
            Accelera.shared.error("No view controller to present from.")
            isRefreshing = false
            return
        }

        var requestData = data
        if !isInitialLoad {
            requestData = mergeJSON(old: data, new: ["refresh": true].asData) as? Data
        }

        Accelera.shared.loadPreparedContent(data: requestData) { [weak self] jsonData in
            guard let self, let container = self.container else { return }
            let oldDivView = self.divView
            let viewContext = DivKitSetup.makeView(from: jsonData, presentingViewController: hostVC, originContext: self, variablesStorage: variablesStorage)
            let divView = viewContext.view
            viewContext.observeSizeChanges { [weak self] in
                (self?.container as? AcceleraContentSizeInvalidating)?
                    .acceleraContentSizeDidChange()
            }
            container.addSubview(divView)
            NSLayoutConstraint.activate([
                divView.topAnchor.constraint(equalTo: container.topAnchor),
                divView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                divView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                divView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
            ])
            container.layoutIfNeeded()

            let cardId = DivCardID(rawValue: UUID().uuidString)
            let source = DivViewSource(kind: .data(jsonData), cardId: cardId)
            Task { [weak self, weak divView] in
                guard let self, let divView else { return }
                await divView.setSource(source)
                oldDivView?.removeFromSuperview()
                self.divView = divView
                self.divKitViewContext = viewContext
                self.divKitComponents = viewContext.components
                self.cardId = cardId
                self.jsonData = jsonData
                Accelera.shared.logEvent(event: ["event": "view", "meta": jsonData.meta].asData)
                if jsonData.closable == true {
                    let closeButton = CloseButtonView { [weak self] in self?.detach() }
                    divView.addSubview(closeButton)
                    divView.bringSubviewToFront(closeButton)
                    NSLayoutConstraint.activate([
                        closeButton.topAnchor.constraint(equalTo: divView.safeAreaLayoutGuide.topAnchor, constant: 8),
                        closeButton.trailingAnchor.constraint(equalTo: divView.trailingAnchor, constant: -8)
                    ])
                }
            }
        } onComplete: { [weak self] in
            self?.isRefreshing = false
        }
    }

    func detach() {
        Accelera.shared.logEvent(event: ["event": "close", "meta": jsonData?.meta].asData)
        remove()
    }

    func remove() {
        divView?.removeFromSuperview()
        divView = nil
        divKitViewContext = nil
        jsonData = nil
        (container as? AcceleraContentSizeInvalidating)?
            .acceleraContentSizeDidChange()
        if let container {
            acceleraContentContexts.removeObject(forKey: container)
        }
        container = nil
    }

    func sharedVariablesStorage() -> DivVariablesStorage {
        variablesStorage
    }
}


#endif
