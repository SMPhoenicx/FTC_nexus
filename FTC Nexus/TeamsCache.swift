//
//  TeamsCache.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/11/26.
//


import Foundation

final class TeamsCache {
    static let shared = TeamsCache()

    struct Snapshot: Codable {
        let lastUpdated: Date
        let teams: [TeamInfo]
    }

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let e = JSONEncoder(); e.dateEncodingStrategy = .iso8601
        self.encoder = e
        let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601
        self.decoder = d
        try? fileManager.createDirectory(
            at: cacheDirectory, withIntermediateDirectories: true
        )
    }

    private var cacheDirectory: URL {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("teams", isDirectory: true)
    }

    private func fileURL(for season: Int) -> URL {
        cacheDirectory.appendingPathComponent("season_\(season).json")
    }

    func save(teams: [TeamInfo], for season: Int) {
        let snapshot = Snapshot(lastUpdated: Date(), teams: teams)
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL(for: season), options: .atomic)
        } catch {
            print("[TeamsCache] save failed for season \(season): \(error)")
        }
    }

    func load(for season: Int) -> Snapshot? {
        let url = fileURL(for: season)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url) else { return nil }
        return try? decoder.decode(Snapshot.self, from: data)
    }

    func clear(season: Int) { try? fileManager.removeItem(at: fileURL(for: season)) }
    func clearAll() { try? fileManager.removeItem(at: cacheDirectory) }
}

