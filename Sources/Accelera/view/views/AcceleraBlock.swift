//
//  AcceleraBlock.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation
import UIKit

class AcceleraBlock: AcceleraAbstractView {
    
    init(element: AcceleraRenderingElement) {
        super.init(element: element, type: UIView.self)
    }
        
    override func prepare(completion: @escaping () -> Void) {
        completion()
    }
    
    override func render(parent: AcceleraAbstractView, previousSibling: AcceleraAbstractView?, last: Bool) {
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let parentPadding = parent.element.padding ?? UIEdgeInsets.zero
        let selfMargin = self.element.margin ?? UIEdgeInsets.zero
        
        if let bg = element.backgroundColor {
            self.view.backgroundColor = bg
        }
        self.view.layer.cornerRadius = element.borderRadius ?? 0
        
        if let border = element.border {
            self.view.layer.borderWidth = border.size
            self.view.layer.borderColor = border.color.cgColor
        }
        
        if let width = element.width {
            view.widthAnchor.constraint(equalToConstant: width).isActive = true
            
            switch parent.element.align {
            case "center":
                view.centerXAnchor.constraint(equalTo: parent.view.centerXAnchor).isActive = true
                break
            case "right":
                view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
                break
            default:
                view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
                break
            }
        } else {
            view.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
            view.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
        }
        
        if let height = element.height {
            view.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        
        if let sibling = previousSibling {
            let siblingMargin = sibling.element.margin ?? UIEdgeInsets.zero
            view.topAnchor.constraint(equalTo: sibling.view.bottomAnchor, constant: siblingMargin.bottom + selfMargin.top).isActive = true
        } else {
            view.topAnchor.constraint(equalTo: parent.view.topAnchor, constant: parentPadding.top + selfMargin.top).isActive = true
        }
        
        if last {
            view.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: -(selfMargin.bottom + parentPadding.bottom)).isActive = true
        }
    }
}
