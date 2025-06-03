//
//  AcceleraBannerViewController.swift
//  Accelera
//
//  Created by Evgeny Boganov on 16.08.2022.
//

import Foundation
import UIKit

protocol AcceleraViewDelegate: AnyObject {
    func onReady(_ view: UIView, type: AcceleraBannerType)
    func onAdded()
    func onError(_ error: Error)
    func onAction(_ action: String?)
    func onClose()
}

class AcceleraBannerViewController {
    var view: AcceleraBannerView?
    var bannerType: AcceleraBannerType = .center
    
    weak var delegate: AcceleraViewDelegate?
    
    private var parsingParents = [AcceleraAbstractView]()
    private var preparingGroup: DispatchGroup?
    private var topView: AcceleraAbstractView?
    
    deinit {
        clear()
    }
    
    // first we need to parse html to rendering elements
    // must be run in background thread
    func parseHTML(html: String, completion: @escaping () -> Void) {
        HTMLParser().parse(html: html) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.delegate?.onError(error)
                break
            case .success(let document):
                self?.parseElement(document)
                completion()
                break
            }
            
        }
    }
    
    // then we have to create UI views for rendering elements
    // must be run in main thread
    func createViews(completion: @escaping () -> Void) {
        guard let topView = self.topView else {
            self.delegate?.onError("View was not created properly")
            return
        }
        
        self.createView(topView)
        completion()
    }
    
    // we prepare elements here. Mainly for loading images
    // must be run in background thread
    func prepareViews(completion: @escaping () -> Void) {
        guard let topView = self.topView else {
            self.delegate?.onError("View was not prepared properly")
            return
        }
        self.preparingGroup = DispatchGroup()
        self.prepareView(topView)
        self.preparingGroup?.wait()
        
        self.preparingGroup = nil
        
        completion()
    }
    
    // finally we render everything. Adding attributes and constraints
    // must be run in main thread
    func renderViews(type: AcceleraBannerType, completion: @escaping () -> Void) {
        
        defer {
            if let view = self.view {
                self.delegate?.onReady(view, type: bannerType)
            } else {
                self.delegate?.onError("View was not rendered properly")
            }

            completion()
        }
        
        guard let topView = self.topView else {
            return
        }
        
        self.bannerType = type
        let superview = AcceleraBannerView(topView: topView, type: type)
        self.view = superview
        superview.delegate = self
        
        // TODO: think about topView background for non fullscreen types
        topView.descendents.forEach{ child in
            self.renderView(child, parent: topView)
        }
    }
        
    func clear() {
        if let view = self.view {
            view.removeFromSuperview()
        }
        self.view = nil
        self.preparingGroup = nil
        self.topView = nil
        self.bannerType = .center
        self.parsingParents.removeAll()
    }
    
    // private methods for parsing, preparing and rendering
    @discardableResult
    private func parseElement(_ element: AcceleraRenderingElement) -> AcceleraAbstractView? {
                
        let view = self.getViewFromElement(element)
        
        if let view = view {
            if let parent = self.parsingParents.last {
                parent.descendents.append(view)
            }
            self.parsingParents.append(view)
        }
        
        element.descendents.forEach { child in
            self.parseElement(child)
        }
        
        if view != nil {
            // assume that we can only have one top element (re-body)
            if self.parsingParents.count == 1 {
                self.topView = self.parsingParents.first
            }
            self.parsingParents.removeLast()
        }
        
        return view
    }
        
    private func createView(_ view: AcceleraAbstractView) {
        view.create()
        
        view.descendents.forEach{ child in
            self.createView(child)
        }
    }
    
    private func prepareView(_ view: AcceleraAbstractView) {
        self.preparingGroup?.enter()
        view.prepare { [weak self] in
            self?.preparingGroup?.leave()
        }
        view.descendents.forEach{ child in
            self.prepareView(child)
        }
    }
        
    private func renderView(_ view: AcceleraAbstractView, parent: AcceleraAbstractView) {
        parent.view.addSubview(view.view)
        view.render(parent: parent, previousSibling: parent.descendents.before(view), last: parent.descendents.last == view)
        view.descendents.forEach{ child in
            self.renderView(child, parent: view)
        }
    }
    
    private func getViewFromElement(_ element: AcceleraRenderingElement) -> AcceleraAbstractView? {
        
        var view: AcceleraAbstractView?
        
        switch element.name {
        case "re-body":
            view = AcceleraBlock(element: element)
            break
        case "re-main":
            view = AcceleraBlock(element: element)
            break
        case "re-block":
            view = AcceleraBlock(element: element)
            break
        case "re-spacer":
            view = AcceleraSpacer(element: element)
            break
        case "re-heading":
            view = AcceleraLabel(element: element)
            break
        case "re-text":
            view = AcceleraLabel(element: element)
            break
        case "re-image":
            view = AcceleraImageView(element: element)
            break
        case "re-button":
            view = AcceleraButton(element: element, action: { [weak self] action in  self?.delegate?.onAction(action)})
            break
        default:
            break
        }
             
        return view
    }
}

extension AcceleraBannerViewController: AcceleraBannerViewDelegate {
    func onClose() {
        self.delegate?.onClose()
    }
    
    func onAdded() {
        self.delegate?.onAdded()
    }
}
