//
//  SavedPlaylistsView.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 3/23/23.
//

import SwiftUI
import SpotifyWebAPI

struct SavedPlaylistsView: View {
    @EnvironmentObject var spotify: Spotify
    
    var body: some View {
        Group {
            if spotify.savedPlaylists.isEmpty {
                if spotify.loadingSavedPlaylists {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Albums")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                } else if spotify.failedLoadingSavedPlaylists {
                    Text("Couldn't Load Albums")
                        .font(.title)
                        .foregroundColor(.secondary)
                } else {
                    Text("No Albums")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                List {
                    ForEach(spotify.savedPlaylists, id: \.id) { playlist in
                        NavigationLink(
                            destination: {
                                PlaylistDetailView(playlist: playlist)
                            }, label: {
                                Text(playlist.name)
                            })
                        
                    }
                }
                .refreshable {
                    if !spotify.loadingSavedPlaylists {
                        retrieveSavedPlaylists()
                    }
                }
            }
        }
        .navigationTitle("Saved Playlists")
        .navigationBarItems(trailing: refreshButton)
        .onAppear {
            if spotify.savedPlaylists == [] {
                retrieveSavedPlaylists()
            }
        }
    }
    
    var refreshButton: some View {
        Button(action: retrieveSavedPlaylists) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(spotify.loadingSavedPlaylists)
    }
    
    func retrieveSavedPlaylists() {
        Task {
            try await spotify.loadSavedPlaylists()
        }
    }
}

struct SavedPlaylistsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedPlaylistsView()
    }
}
