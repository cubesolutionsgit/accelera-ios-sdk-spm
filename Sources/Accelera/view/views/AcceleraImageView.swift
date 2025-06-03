//
//  AcceleraImageView.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation
import UIKit

class AcceleraImageView: AcceleraAbstractView {
    
    init(element: AcceleraRenderingElement) {
        super.init(element: element, type: UIImageView.self)
    }
        
    override func prepare(completion: @escaping () -> Void) {
        
        defer {
            completion()
        }
        
        guard let imageView = self.view as? UIImageView else {
            return
        }
        
        if let source = element.getAttribute("src"),
           !source.isEmpty,
           let url = URL(string: source) {
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.contentMode = .scaleAspectFill
                        imageView.image = image
                    }
                }
            }
        }
    }
    
    override func render(parent: AcceleraAbstractView, previousSibling: AcceleraAbstractView?, last: Bool) {
             
        
        // attributes
        
        guard let imageView = self.view as? UIImageView,
        let image = imageView.image else {
            return
        }
        
        imageView.layer.cornerRadius = element.borderRadius ?? 0
        
        if let border = element.border {
            imageView.layer.borderWidth = border.size
            imageView.layer.borderColor = border.color.cgColor
        }
        
        // constraints
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let imageRatio = image.size.width / image.size.height
        
        let width = element.width
        let height = element.height
        
        if let w = width, height == nil {
            imageView.heightAnchor.constraint(equalToConstant: w / imageRatio).isActive = true
        }
        
        if let h = height, width == nil {
            imageView.widthAnchor.constraint(equalToConstant: h * imageRatio).isActive = true
        }
        
        let parentPadding = parent.element.padding ?? UIEdgeInsets.zero
        let selfMargin = self.element.margin ?? UIEdgeInsets.zero
        
        if let width = element.width {
            imageView.widthAnchor.constraint(equalToConstant: width).isActive = true
            switch parent.element.align {
            case "center":
                imageView.centerXAnchor.constraint(equalTo: parent.view.centerXAnchor).isActive = true
                break
            case "right":
                imageView.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
                break
            default:
                imageView.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
                break
            }
        } else {
            imageView.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor, constant: parentPadding.left + selfMargin.left).isActive = true
            imageView.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor, constant: -(parentPadding.right + selfMargin.right)).isActive = true
        }
        
        if let height = element.height {
            imageView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
        
        
        if let sibling = previousSibling {
            let siblingMargin = sibling.element.margin ?? UIEdgeInsets.zero
            imageView.topAnchor.constraint(equalTo: sibling.view.bottomAnchor, constant: siblingMargin.bottom + selfMargin.top).isActive = true
        } else {
            imageView.topAnchor.constraint(equalTo: parent.view.topAnchor, constant: parentPadding.top + selfMargin.top).isActive = true
        }
        
        if last {
            imageView.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor, constant: -(selfMargin.bottom + parentPadding.bottom)).isActive = true
        }
    }
}
