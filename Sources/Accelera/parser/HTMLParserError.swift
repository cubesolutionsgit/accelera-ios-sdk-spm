//
//  HTMLParserError.swift
//  Accelera
//
//  Created by Evgeny Boganov on 19.08.2022.
//

import Foundation


enum HTMLParserError: Error {
    case nonValidHTML
    case emptyHTML
    case other
}

extension HTMLParserError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .nonValidHTML:
            return "Provided html is not valid"
        case .emptyHTML:
            return "Provided html is empty"
        case .other:
            return "Something went wrong"
        }
    }
}
