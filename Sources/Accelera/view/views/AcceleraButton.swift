//
//  AcceleraButton.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation
import UIKit

class AcceleraButton: AcceleraAbstractView {
    
    init(element: AcceleraRenderingElement, action: ((String?) -> Void)?) {
        super.init(element: element, type: UIButton.self)
        self.action = action
    }
    
    private var action: ((String?) -> Void)?
            
    override func prepare(completion: @escaping () -> Void) {
        completion()
    }
        
    override func render(parent: AcceleraAbstractView, previousSibling: AcceleraAbstractView?, last: Bool) {
        
        guard let button = self.view as? UIButton else {
            return
        }
        
        // attributes
        
        button.clipsToBounds = true
        button.setTitle(element.text, for: .normal)
        button.setTitleColor(element.color, for: .normal)
        button.titleLabel?.lineBreakMode = .byWordWrapping
        let padding = element.padding ?? UIEdgeInsets(top: 14, left: 40, bottom: 14, right: 40)
        button.contentEdgeInsets = padding
        let fontSize = element.fontSize ?? 18
        
        let height = button.contentEdgeInsets.top + button.contentEdgeInsets.bottom + fontSize
        
        button.layer.cornerRadius = element.borderRadius ?? (height / 2 > 24 ? 24 : height / 2)
        button.backgroundColor = element.backgroundColor ?? UIColor(hex: "#0091ff")
        if let border = element.border {
            button.layer.borderWidth = border.size
            button.layer.borderColor = border.color.cgColor
        }
        button.titleLabel?.font = button.titleLabel?.font.withSize(fontSize)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        button.startAnimatingPressActions()
        
        // constraints
        
        button.translatesAutoresizingMaskIntoConstraints = false
 
        let parentPadding = parent.element.padding ?? UIEdgeInsets.zero
        let selfMargin = self.element.margin ?? UIEdgeInsets.zero
        
        if let width = element.width {
            button.widthAnchor.constraint(equalToConstant: width).isActive = true
        } else {
            button.widthAnchor.constraint(lessThanOrEqualTo: parent.view.widthAnchor).isActive = true
        }
        
        switch parent.element.align {
        case "center":
            button.centerXAnchor.constraint(equalTo: parent.view.centerXAnchor).isActive = true
            break
        case "right":
            button.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
            break
        default:
            button.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
            break
        }
        
        if let height = element.height {
            button.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        
        if let sibling = previousSibling {
            let siblingMargin = sibling.element.margin ?? UIEdgeInsets.zero
            button.topAnchor.constraint(equalTo: sibling.view.bottomAnchor, constant: siblingMargin.bottom + selfMargin.top).isActive = true
        } else {
            button.topAnchor.constraint(equalTo: parent.view.topAnchor, constant: parentPadding.top + selfMargin.top).isActive = true
        }
        
        if last {
            button.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: -(selfMargin.bottom + parentPadding.bottom)).isActive = true
        }
    }
    
    @objc func buttonAction() {
        if let action = self.action {
            action(element.href)
        }
    }
}
