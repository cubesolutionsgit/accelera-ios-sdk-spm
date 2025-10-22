//
//  Utils.swift
//  Accelera
//
//  Created by Evgeny on 16.10.2025.
//

import Foundation

func mergeJSON(old: Any?, new: Any?) -> Any? {
    func toDict(_ input: Any?) -> [String: Any]? {
        if let data = input as? Data,
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return dict
        }
        if let string = input as? String,
           let data = string.data(using: .utf8),
           let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return dict
        }
        return nil
    }

    guard let new else { return nil }

    let oldDict = toDict(old)
    let newDict = toDict(new)

    guard let oldDict, let newDict else {
        return new
    }

    guard var merged = toDict(old),
          let dict = toDict(new) else {
        return new
    }

    for (key, value) in dict {
        if value is NSNull {
            merged.removeValue(forKey: key)
        } else {
            merged[key] = value
        }
    }

    if old is Data || new is Data {
        return try? JSONSerialization.data(withJSONObject: merged)
    } else {
        if let data = try? JSONSerialization.data(withJSONObject: merged),
           let json = String(data: data, encoding: .utf8) {
            return json
        }
    }

    return nil
}
