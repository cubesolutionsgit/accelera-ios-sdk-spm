//
//  AcceleraBannerView.swift
//  Accelera
//
//  Created by Evgeny Boganov on 22.08.2022.
//

import Foundation
import UIKit

protocol AcceleraBannerViewDelegate: AnyObject {
    func onClose()
    func onAdded()
}

class AcceleraBannerView: UIView {
    
    init(topView: AcceleraAbstractView, type: AcceleraBannerType) {
        self.topView = topView
        self.type = type
        
        super.init(frame: CGRect())
        
        if self.type == .fullscreen {
            self.backgroundColor = self.getBackgroundColor()
        }
        self.addSubview(topView.view)
        self.createCloseButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    let type: AcceleraBannerType
    let topView: AcceleraAbstractView
    weak var delegate: AcceleraBannerViewDelegate?
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if superview == nil && newSuperview != nil {
            self.delegate?.onAdded()
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        if let superview = superview {
            self.translatesAutoresizingMaskIntoConstraints = false
            
            let guide = self.safeAreaLayoutGuide

            switch type {
            case .fullscreen:
                self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
                self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
                self.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
                break
            case .top:
                self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
                self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
                self.bottomAnchor.constraint(equalTo: topView.view.bottomAnchor).isActive = true
                break
            case .center:
                self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
                self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
                self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
                self.bottomAnchor.constraint(equalTo: topView.view.bottomAnchor).isActive = true
                break
            case .notification:
                self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
                self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
                self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
                self.bottomAnchor.constraint(equalTo: topView.view.bottomAnchor).isActive = true
                break
            }
            
            topView.view.translatesAutoresizingMaskIntoConstraints = false
            topView.view.topAnchor.constraint(equalTo: guide.topAnchor).isActive = true
            topView.view.leadingAnchor.constraint(equalTo: guide.leadingAnchor).isActive = true
            topView.view.trailingAnchor.constraint(equalTo: guide.trailingAnchor).isActive = true
            
        }
    }
    

    private func getBackgroundColor() -> UIColor? {
        var bgColor: UIColor?
        var view: AcceleraAbstractView? = topView
        while view?.element != nil {
            if view?.element.backgroundColor != nil {
                bgColor = view?.element.backgroundColor
                view = nil
            } else {
                view = view?.descendents.first
            }
        }
        return bgColor
    }
    
    private func createCloseButton() {
        let closeButton = UIButton()
        self.addSubview(closeButton)
        
        let closeButtonColor: UIColor = self.getBackgroundColor()?.isLight() == false ? .white : .black
                
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(closeButtonColor, for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonPress), for: .touchUpInside)
        closeButton.startAnimatingPressActions()
        
        let guide = self.safeAreaLayoutGuide
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 24).isActive = true
        closeButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10 + (topView.element.padding?.top ?? 0)).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -10 - (topView.element.padding?.right ?? 0)).isActive = true
        
    }
    
    @objc
    private func closeButtonPress() {
        self.delegate?.onClose()
    }
}
