//
//  RankingsCache.swift
//  FTC Nexus
//
//  Created by Suman Muppavarapu on 5/6/26.
//


import Foundation

final class RankingsCache {
    static let shared = RankingsCache()

    /// What we actually persist per season: the teams plus when they were fetched.
    struct Snapshot: Codable {
        let lastUpdated: Date
        let teams: [TeamRanking]
    }

    private let fileManager = FileManager.default
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    private init() {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        self.encoder = e

        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        self.decoder = d

        try? fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    private var cacheDirectory: URL {
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("rankings", isDirectory: true)
    }

    private func fileURL(for season: Int) -> URL {
        cacheDirectory.appendingPathComponent("season_\(season).json")
    }

    /// Replace the cached snapshot for a season with a fresh one.
    /// Stamps `lastUpdated` to now.
    func save(teams: [TeamRanking], for season: Int) {
        let snapshot = Snapshot(lastUpdated: Date(), teams: teams)
        do {
            let data = try encoder.encode(snapshot)
            try data.write(to: fileURL(for: season), options: .atomic)
        } catch {
            print("[RankingsCache] save failed for season \(season): \(error)")
        }
    }

    /// Load the cached snapshot for a season, or nil if no cache exists
    /// (or the cache is corrupted / has an outdated schema).
    func load(for season: Int) -> Snapshot? {
        let url = fileURL(for: season)
        guard fileManager.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url)
        else { return nil }
        return try? decoder.decode(Snapshot.self, from: data)
    }

    func clear(season: Int) {
        try? fileManager.removeItem(at: fileURL(for: season))
    }

    func clearAll() {
        try? fileManager.removeItem(at: cacheDirectory)
    }
}
