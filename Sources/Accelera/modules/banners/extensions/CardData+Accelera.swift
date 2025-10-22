//
//  CardData+Accelera.swift
//  Accelera
//
//  Created by Evgeny on 20.10.2025.
//

#if ACCELERA_BANNERS_ENABLED

import UIKit

extension Data {
    var closable: Bool? {
        extractValue(forKey: "closable")
    }

    var duration: Int? {
        extractValue(forKey: "duration")
    }

    var meta: Any? {
        extractValue(forKey: "meta")
    }

    private func extractValue<T>(forKey key: String) -> T? {
        guard
            let jsonObject = try? JSONSerialization.jsonObject(with: self, options: []),
            let root = jsonObject as? [String: Any],
            let card = root["card"] as? [String: Any],
            let value = card[key] as? T
        else {
            return nil
        }
        return value
    }
}

#endif
