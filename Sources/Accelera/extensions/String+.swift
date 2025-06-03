//
//  String+.swift
//  Accelera
//
//  Created by Evgeny Boganov on 14.08.2022.
//

import Foundation

extension String {
    var digits: String {
        return components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
    }
    
    func removeExtraSpaces() -> String {
        return self.replacingOccurrences(of: "[\\s\n]+", with: " ", options: .regularExpression, range: nil)
    }
}

extension String: Error {
    
}
