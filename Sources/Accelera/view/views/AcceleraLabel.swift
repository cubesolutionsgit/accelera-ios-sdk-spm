//
//  AcceleraLabel.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation
import UIKit

class AcceleraLabel: AcceleraAbstractView {
    init(element: AcceleraRenderingElement) {
        super.init(element: element, type: UILabel.self)
    }
        
    override func prepare(completion: @escaping () -> Void) {
        completion()
    }
    
    override func render(parent: AcceleraAbstractView, previousSibling: AcceleraAbstractView?, last: Bool) {
        
        // attributes
        
        guard let label = self.view as? UILabel,
        var text = element.text else {
            return
        }
        
        label.backgroundColor = element.backgroundColor ?? .clear
        label.numberOfLines = 0
        label.textColor = element.color
        label.lineBreakMode = .byWordWrapping
        
        var fontSize: CGFloat = 16
        
        if let level = element.level {
            switch level {
            case 1:
                fontSize = 32
                break
            case 2:
                fontSize = 28
                break
            case 3:
                fontSize = 20
                break
            default:
                fontSize = 16
                break
            }
            text = "<b>\(text)</b>"
            
            label.font = label.font.withSize(element.fontSize ?? fontSize).bold()
        } else {
            label.font = label.font.withSize(element.fontSize ?? fontSize)
        }
                
        text = "<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: \(element.fontSize ?? fontSize); color: \((element.color ?? .black).toHexString()); line-height: 1.5 \">\(text)</span>"
           
        // TODO: html doesn't work good with memory
        //label.attributedText = NSMutableAttributedString(html: text)

        label.text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        label.setLineSpacing(lineHeightMultiple: 1.5)
        
        if let align = element.align ?? parent.element.align {
            switch align {
            case "left":
                label.textAlignment = .left
                break
            case "center":
                label.textAlignment = .center
                break
            case "right":
                label.textAlignment = .right
            default:
                break
            }
        }
        
        // constraints
        
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let parentPadding = parent.element.padding ?? UIEdgeInsets.zero
        let selfMargin = self.element.margin ?? UIEdgeInsets.zero
        
        if let width = element.width {
            label.widthAnchor.constraint(equalToConstant: width).isActive = true
            
            switch parent.element.align {
            case "center":
                label.centerXAnchor.constraint(equalTo: parent.view.centerXAnchor).isActive = true
                break
            case "right":
                label.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
                break
            default:
                label.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
                break
            }
        } else {
            label.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
            label.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
        }
        
        if let height = element.height {
            label.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        
        if let sibling = previousSibling {
            let siblingMargin = sibling.element.margin ?? UIEdgeInsets.zero
            
            label.topAnchor.constraint(equalTo: sibling.view.bottomAnchor, constant: siblingMargin.bottom + selfMargin.top).isActive = true
        } else {
            label.topAnchor.constraint(equalTo: parent.view.topAnchor, constant: parentPadding.top + selfMargin.top).isActive = true
        }
        
        if last {
            label.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: -(selfMargin.bottom + parentPadding.bottom)).isActive = true
        }
    }
}
