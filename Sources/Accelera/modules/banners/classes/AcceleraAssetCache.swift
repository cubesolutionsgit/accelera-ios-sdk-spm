//
//  AcceleraAssetCache.swift
//  Accelera
//
//  Created by Evgeny on 24.11.2025.
//

import Foundation
import CryptoKit

enum AcceleraAssetCache {
    private static let queue = DispatchQueue(label: "accelera.assetCache", attributes: .concurrent)

    private static var directoryURL: URL = {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let url = base.appendingPathComponent("AcceleraAssets", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    private enum AssetKind {
        case image
    }

    static func prepare(
        _ data: Data,
        progress: ((Double) -> Void)? = nil
    ) async throws -> Data {
        let json = try JSONSerialization.jsonObject(with: data, options: [])

        var blocking: [String: AssetKind] = [:]
        var lazy: [String: AssetKind] = [:]
        collectAssets(node: json, inLazyZone: false, blocking: &blocking, lazy: &lazy)

        if !blocking.isEmpty {
            let total = blocking.count
            var completed = 0

            for (remote, _) in blocking {
                try await ensureCached(remote: remote)

                completed += 1

                if let progress = progress {
                    let value = Double(completed) / Double(total)
                    await MainActor.run {
                        progress(value)
                    }
                }
            }
        }

        for (remote, _) in lazy {
            scheduleDownload(remote: remote)
        }

        return data
    }

    static func clean() {
        let url = directoryURL
        try? FileManager.default.removeItem(at: url)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    static func existingFileURL(forRemote remote: String) -> URL? {
        let hash = filenameFor(remote)
        let fileURL = directoryURL.appendingPathComponent(hash)
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return fileURL
        }
        return nil
    }

    static func scheduleDownload(remote: String) {
        let hash = filenameFor(remote)
        let fileURL = directoryURL.appendingPathComponent(hash)

        if FileManager.default.fileExists(atPath: fileURL.path) {
            return
        }

        Task.detached {
            do {
                try await ensureCached(remote: remote, hash: hash, fileURL: fileURL)
            } catch {
            }
        }
    }

    private static func collectAssets(
        node: Any,
        inLazyZone: Bool,
        blocking: inout [String: AssetKind],
        lazy: inout [String: AssetKind]
    ) {
        if let dict = node as? [String: Any] {
            for (key, value) in dict {
                let nextLazy = inLazyZone || key == "fullscreens"

                if let string = value as? String,
                   let kind = assetKind(key: key, value: string, parent: dict) {
                    if nextLazy {
                        lazy[string] = kind
                    } else {
                        blocking[string] = kind
                    }
                }

                collectAssets(node: value, inLazyZone: nextLazy, blocking: &blocking, lazy: &lazy)
            }
        } else if let array = node as? [Any] {
            for item in array {
                collectAssets(node: item, inLazyZone: inLazyZone, blocking: &blocking, lazy: &lazy)
            }
        }
    }

    private static func assetKind(key: String, value: String, parent: [String: Any]) -> AssetKind? {
        let lower = value.lowercased()
        guard lower.hasPrefix("http://") || lower.hasPrefix("https://") else {
            return nil
        }

        if key == "image_url" {
            return .image
        }

        return nil
    }

    private static func ensureCached(remote: String) async throws {
        let hash = filenameFor(remote)
        let fileURL = directoryURL.appendingPathComponent(hash)
        try await ensureCached(remote: remote, hash: hash, fileURL: fileURL)
    }

    private static func ensureCached(remote: String, hash: String, fileURL: URL) async throws {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            return
        }

        guard let url = URL(string: remote) else {
            throw NSError(
                domain: "AcceleraAssetCache",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL \(remote)"]
            )
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        try data.write(to: fileURL, options: .atomic)
    }

    private static func filenameFor(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
