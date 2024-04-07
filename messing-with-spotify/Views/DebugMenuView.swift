//
//  DebugMenuView.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 3/30/23.
//

import SwiftUI

struct DebugMenuView: View {
    @EnvironmentObject var spotify: Spotify
    
    var body: some View {
        List {
            Button("Clear Saved Tracks", role: .destructive, action: {spotify.savedTracks = []})
                .disabled(spotify.savedTracks.isEmpty)
            Button("Clear Track Cache", role: .destructive, action: {spotify.trackCache = []})
                .disabled(spotify.trackCache.isEmpty)
            Button("Clear Saved Albums", role: .destructive, action: {spotify.savedAlbums = []})
                .disabled(spotify.savedAlbums.isEmpty)
            Button("Clear Saved Playlists", role: .destructive, action: {spotify.savedPlaylists = []})
                .disabled(spotify.savedPlaylists.isEmpty)
        }
    }
}

struct DebugMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DebugMenuView()
    }
}
