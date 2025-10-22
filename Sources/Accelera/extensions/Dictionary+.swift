//
//  Dictionary+.swift
//  Accelera
//
//  Created by Evgeny on 13.10.2025.
//

import Foundation

extension Dictionary where Key == String, Value == Any {
    /// Converts the dictionary to `Data` using JSON serialization.
    ///
    /// If serialization fails, returns empty `Data()`.
    public var asData: Data {
        (try? JSONSerialization.data(withJSONObject: self)) ?? Data()
    }
}
