//
//  Collection+.swift
//  Testing
//
//  Created by Evgeny Boganov on 09.08.2022.
//

import Foundation

extension Collection {

    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
    
    var elementBeforeLast: Element? {
        return dropLast().last
    }
}
