//
//  messing_with_spotifyApp.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 2/2/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

@main
struct messing_with_spotifyApp: App {
    
    @StateObject var spotify = Spotify()
    
    @Environment(\.scenePhase) private var scenePhase

    init() {
        UIView.appearance().tintColor = UIColor(named: "AccentColor")
        SpotifyAPILogHandler.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(spotify)
                .task {
                    do {
                        (spotify.userTags, spotify.songTags, spotify.trackCache) = try await Spotify.load()
                    } catch {
                        fatalError("Error loading data.")
                    }
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .inactive { saveAction() }
                }

        }
    }
    
    func saveAction() {
        Task {
            do {
                try await Spotify.save(userTags: spotify.userTags, trackTags: spotify.songTags, trackCache: spotify.trackCache)
            } catch {
                fatalError("Error saving data.")
            }
        }
    }

}
