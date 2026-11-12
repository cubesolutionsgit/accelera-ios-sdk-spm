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
        case video
    }

    static func prepare(
        _ data: Data,
        progress: ((Double) -> Void)? = nil
    ) async throws -> Data {
        let json = try JSONSerialization.jsonObject(with: data, options: [])

        var blocking: [String: AssetKind] = [:]
        var lazy: [String: AssetKind] = [:]
        collectAssets(node: json, inFullscreen: false, blocking: &blocking, lazy: &lazy)

        try? queue.sync(flags: .barrier) {
            let now = Date()
            for remote in Array(blocking.keys) + Array(lazy.keys) { try? FileManager.default.setAttributes([.modificationDate: now], ofItemAtPath: directoryURL.appendingPathComponent(filenameFor(remote)).path) }
            let cutoff = now.addingTimeInterval(-7 * 24 * 60 * 60)
            let files = try FileManager.default.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.contentModificationDateKey])
            for file in files where ((try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? now) < cutoff { try? FileManager.default.removeItem(at: file) }
        }

        for (remote, _) in lazy {
            scheduleDownload(remote: remote)
        }

        if !blocking.isEmpty {
            let total = blocking.count
            var completed = 0

            try await withThrowingTaskGroup(of: Void.self) { group in
                for remote in blocking.keys {
                    group.addTask {
                        try await ensureCached(remote: remote)
                    }
                }

                for try await _ in group {
                    completed += 1

                    if let progress = progress {
                        let value = Double(completed) / Double(total)
                        await MainActor.run {
                            progress(value)
                        }
                    }
                }
            }
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
        inFullscreen: Bool,
        blocking: inout [String: AssetKind],
        lazy: inout [String: AssetKind]
    ) {
        if let dict = node as? [String: Any] {
            for (key, value) in dict {
                let insideFullscreen = inFullscreen || key == "fullscreens"

                if let string = value as? String,
                   let kind = assetKind(key: key, value: string, parent: dict) {
                    switch kind {
                    case .video:
                        lazy[string] = kind
                    case .image where insideFullscreen:
                        lazy[string] = kind
                    case .image:
                        blocking[string] = kind
                    }
                }

                collectAssets(node: value, inFullscreen: insideFullscreen, blocking: &blocking, lazy: &lazy)
            }
        } else if let array = node as? [Any] {
            for item in array {
                collectAssets(node: item, inFullscreen: inFullscreen, blocking: &blocking, lazy: &lazy)
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
        let mime = (parent["mime_type"] as? String ?? "").lowercased()
        if key == "url", mime.hasPrefix("video/"), !mime.contains("mpegurl") {
            return .video
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

        let (temporaryURL, response) = try await URLSession.shared.download(from: url)
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else { throw URLError(.badServerResponse) }
        try queue.sync(flags: .barrier) {
            guard !FileManager.default.fileExists(atPath: fileURL.path) else { return }
            try FileManager.default.moveItem(at: temporaryURL, to: fileURL)
        }
    }

    private static func filenameFor(_ string: String) -> String {
        let data = Data(string.utf8)
        let digest = SHA256.hash(data: data)
        let ext = URL(string: string)?.pathExtension ?? ""
        return digest.map { String(format: "%02x", $0) }.joined() + (ext.isEmpty ? "" : ".\(ext)")
    }
}
