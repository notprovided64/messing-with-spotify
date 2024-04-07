//
//  SaveLoad.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 3/26/23.
//

import Foundation
import SpotifyWebAPI
import SwiftUI
import OrderedCollections

extension Spotify {
    private static func fileURL() throws -> URL {
        try FileManager.default.url(for: .documentDirectory,
                                    in: .userDomainMask,
                                    appropriateFor: nil,
                                    create: false)
                                    .appendingPathComponent("spotify.data")
    }
    
    static func load() async throws -> (OrderedSet<String>, [String : OrderedSet<String>], OrderedSet<Track>) {
        try await withCheckedThrowingContinuation { continuation in
            load { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let data):
                    continuation.resume(returning: data)
                }
            }
        }
    }

    static func load(completion: @escaping (Result<(OrderedSet<String>, [String : OrderedSet<String>], OrderedSet<Track>), Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let fileURL = try fileURL()
                guard let file = try? FileHandle(forReadingFrom: fileURL) else{
                    DispatchQueue.main.async {
                        completion(.success( ([], [:], []) ))
                    }
                    return
                }
                let data = try JSONDecoder().decode(UserDataStore.self, from: file.availableData)
                DispatchQueue.main.async {
                    completion(.success( (data.tags, data.trackTags, OrderedSet(data.trackCache) ) ) )
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    @discardableResult
    static func save(userTags: OrderedSet<String>, trackTags: [String : OrderedSet<String>], trackCache: OrderedSet<Track>) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            save(data: UserDataStore(tags: userTags, trackTags: trackTags, trackCache: trackCache)) { result in
                switch result {
                case .failure(let error):
                    continuation.resume(throwing: error)
                case .success(let saved):
                    continuation.resume(returning: saved)
                }
            }
        }
    }

    static func save(data: UserDataStore, completion: @escaping (Result<Int, Error>)->Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let json = try JSONEncoder().encode(data)
                let outfile = try fileURL()
                try json.write(to: outfile)
                DispatchQueue.main.async {
                    completion(.success(1))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

struct UserDataStore: Codable {
    let tags: OrderedSet<String>
    let trackTags: [String : OrderedSet<String>]
    
    let trackCache: OrderedSet<Track>
}

