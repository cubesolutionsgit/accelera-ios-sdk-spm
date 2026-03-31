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

    /**
     Loads and attaches dynamic content into the given container.
     
     This method:
     - Clears previous views in container
     - Loads data using `loadBanner` from `AcceleraAPI`
     - Parses the DivKit JSON
     - Attaches and renders `DivView` inside the container
     - Optionally adds a close button if `jsonData.closable == true`
     
     - Parameters:
       - container: The `UIView` that will host the banner.
       - data: Optional input JSON to be sent to the backend.
     */
    public func attachContentPlaceholder(
        to container: UIView,
        with data: Data? = nil
    ) {
        container.subviews.forEach { $0.removeFromSuperview() }
        
        guard let hostVC = container.parentViewController else {
            error("No view controller to present from.")
            return
        }
        
        log("Loading conent with params: \(String(data: data ?? Data(), encoding: .utf8) ?? "<invalid>")")
        
        self.api.loadBanner(data: addUserInfo(to: data)) { [weak self, weak container] result, error in
            guard let self = self, let container = container else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error("Failed to load content: \(error)")
                }
                return
            }
            
            guard let jsonData = result else {
                DispatchQueue.main.async {
                    self.error("Empty JSON data from API")
                }
                return
            }
            
            self.log("Content loaded, preparing assets")
            
            Task.detached { [weak self, weak container, weak hostVC] in
                guard let self = self, let container = container, let hostVC = hostVC else { return }
                
                do {
                    try await AcceleraAssetCache.prepare(jsonData) { value in
                        let percent = Int(value * 100)
                        print("Cache progress: \(percent)%")
                    }
                } catch {
                    self.error("Asset prepare failed: \(error). Proceeding without cache warmup")
                }
                
                await MainActor.run { [weak self, weak container] in
                    guard let self = self, let container = container else { return }
                    
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
                        guard let self = self, let divView = divView else { return }
                        
                        await divView.setSource(source)
                        self.logEvent(event: ["event": "view", "meta": jsonData.meta].asData)
                        
                        if jsonData.closable == true {
                            let closeButton = CloseButtonView(target: self, action: #selector(self.handleClose))
                            
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
        }
    }
    
    @objc private func handleClose(_ sender: UIButton) {
        guard let divView = sender.superview else { return }
        divView.removeFromSuperview()
    }
}


#endif
