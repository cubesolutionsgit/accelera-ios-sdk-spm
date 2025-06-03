//
//  Element.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation

class Element {
    init (name: String, attributes: [String: String] = [:]) {
        self.name = name
        self.attributes = attributes
    }
        
    var name: String
    var children = [Element]()
    var attributes: [String: String]
    var text: String?
}

extension Element: CustomStringConvertible {
    var description: String {
        var string = "\(name)"
        if let text = text {
            string += ", text: \(text)"
        }
        if !attributes.isEmpty {
            string += ", attributes: \(attributes.description)"
        }
        string += "\n"
        children.forEach{ child in
            string += child.description
        }
        
        return string
    }
}
