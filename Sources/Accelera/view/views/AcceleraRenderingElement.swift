//
//  AcceleraRenderingElement.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation
import UIKit

protocol AcceleraRenderingElement {
    var name: String { get }
    var attributes: [String: String] { get set }
    var descendents: [AcceleraRenderingElement] { get }
    var text: String? { get }
}

extension AcceleraRenderingElement {
        
    func getAttribute(_ name: String) -> String? {
        return attributes[name]
    }
    
    mutating func setAttribute(_ name: String, value: String) {
        attributes[name] = value
    }
    
    var width: CGFloat? {
        guard let str = self.getAttribute("width")?.digits,
              !str.isEmpty,
              let w = NumberFormatter().number(from: str) else {
            return nil
        }
        return CGFloat(truncating: w)
    }

    var height: CGFloat? {
        guard let str = self.getAttribute("height")?.digits,
              !str.isEmpty,
              let h = NumberFormatter().number(from: str) else {
            return nil
        }
        return CGFloat(truncating: h)
    }
    
    var align: String? {
        guard let a = self.getAttribute("align"), !a.isEmpty else {
           return nil
        }
        return a
    }
    
    var href: String? {
        guard let h = self.getAttribute("href"), !h.isEmpty else {
           return nil
        }
        return h
    }
    
    var margin: UIEdgeInsets? {
        guard let m = self.getAttribute("margin") else {
            return nil
        }
        
        if m.isEmpty {
            return UIEdgeInsets.zero
        }

        let values = m.components(separatedBy: " ").map{Int($0.digits) ?? 0}

        let top = values[safe: 0] ?? 0
        let right = values[safe: 1] ?? top
        let bottom = values[safe: 2] ?? top
        let left = values[safe: 3] ?? right

        return UIEdgeInsets(top: CGFloat(top), left: CGFloat(left), bottom: CGFloat(bottom), right: CGFloat(right))

    }

    var padding: UIEdgeInsets? {
        guard let p = self.getAttribute("padding") else {
            return nil
        }
        
        if p.isEmpty {
            return UIEdgeInsets.zero
        }

        let values = p.components(separatedBy: " ").map{Int($0.digits) ?? 0}

        let top = values[safe: 0] ?? 0
        let right = values[safe: 1] ?? top
        let bottom = values[safe: 2] ?? top
        let left = values[safe: 3] ?? right

        return UIEdgeInsets(top: CGFloat(top), left: CGFloat(left), bottom: CGFloat(bottom), right: CGFloat(right))

    }
    
    var color: UIColor? {
        guard let c = self.getAttribute("color"), !c.isEmpty else {
            return nil

        }
        return UIColor(hex: c)
    }

    var backgroundColor: UIColor? {
        guard let bc = self.getAttribute("background-color"), !bc.isEmpty else {
            return nil

        }
        return UIColor(hex: bc)
    }

    var level: Int? {
        guard let l = self.getAttribute("level")?.digits, !l.isEmpty else {
            return nil

        }
        return Int(l)
    }

    var fontSize: CGFloat? {
        guard let str = self.getAttribute("font-size")?.digits,
              !str.isEmpty,
              let fs = NumberFormatter().number(from: str) else {
            return nil
        }
        return CGFloat(truncating: fs)
    }
    
    var borderRadius: CGFloat? {
        guard let str = self.getAttribute("border-radius")?.digits,
              !str.isEmpty,
              let br = NumberFormatter().number(from: str) else {
            return nil
        }
        return CGFloat(truncating: br)
    }
    
    var border: (size: CGFloat, type: String, color: UIColor)? {
        guard let b = self.getAttribute("border"), !b.isEmpty else {
            return nil
        }
        
        let borderParams = b.split(separator: " ")
        guard borderParams.count == 3 else {
            return nil
        }
        let size = CGFloat(Int(String(borderParams[0]).digits) ?? 0)
        let type = String(borderParams[1])
        let color = UIColor(hex: String(borderParams[2]))
        
        return (size, type, color)
    }
}

// if we change parsing impelemtation then extend new Element to implement AcceleraRenderingElement
extension Element: AcceleraRenderingElement {    
    var descendents: [AcceleraRenderingElement] {
        return self.children
    }
}
