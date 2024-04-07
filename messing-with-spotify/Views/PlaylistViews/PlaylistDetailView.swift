//
//  PlaylistDetailView.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 3/23/23.
//

import SwiftUI
import SpotifyWebAPI
import Combine

struct PlaylistDetailView: View {
    @EnvironmentObject var spotify: Spotify
        
    @State var tracks: [Track] = []
    @State var isLoadingTracks: Bool = false
    
    var sharedTags: [String] {
        if tracks.isEmpty || isLoadingTracks || spotify.songTags[tracks[0].id!] == nil {
            return []
        }
        
        var tags: Set<String> = Set(spotify.songTags[tracks[0].id!]!)
        
        for track in tracks {
            tags = tags.union(spotify.songTags[track.id!, default: []])
        }
        
        return Array(tags)
    }
    
    let playlist: Playlist<PlaylistItemsReference>
    
    @State private var presentAlert = false
    @State private var tagName: String = ""

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                Text(playlist.name)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top)
                Text("\(playlist.items.total) Tracks")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.vertical, 10)
                HStack {
                    Menu("Add tag") {
                        ForEach(spotify.userTags, id: \.self) { tag in
                            Button(tag, action: {
                                for track in tracks {
                                    addTag(track: track, tag: tag)
                                }
                            })
                        }
                        Button(action: { presentAlert = true }, label:{Label("New", systemImage: "plus")})
                    }
                    .disabled(isLoadingTracks)
                    .menuStyle(.button)
                    .padding()
                    Menu("Remove tag") {
                        ForEach(sharedTags, id: \.self) { tag in
                            Button(tag, action: {
                                for track in tracks {
                                    spotify.songTags[track.id!]!.remove(tag)
                                }
                                spotify.objectWillChange.send()
                            })
                        }
                    }
                    .disabled(sharedTags.isEmpty)
                    .menuStyle(.button)
                    .padding()
                }
                .disabled(isLoadingTracks)
                .padding()
                if tracks.isEmpty {
                    Group {
                        if isLoadingTracks {
                            HStack {
                                ProgressView()
                                    .padding()
                                Text("Loading Tracks")
                                    .font(.title)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                else {
                    ForEach(
                        Array(tracks.enumerated()),
                        id: \.offset
                    ) { track in
                        HStack {
                            Text(String(track.offset+1))
                                .padding(.leading)
                            TrackView(track: track.element)
                                .padding()
                            Spacer()
                        }
                        Divider()
                    }
                    .refreshable {
                        if !isLoadingTracks {
                            loadTracks()
                        }
                    }
                }
            }
        }
        .navigationBarTitle("", displayMode: .inline)
        .onAppear(perform: loadTracks)
        .alert("New Tag", isPresented: $presentAlert, actions: {
            TextField("Username", text: $tagName)
                .autocorrectionDisabled()
            Button("Add", action: {
                for track in tracks {
                    addTag(track: track, tag: tagName)
                }

                spotify.userTags.append(tagName)
                spotify.objectWillChange.send()
            })
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text("Enter tag name: ")
        })
    }
    /// Loads the album tracks.
    func loadTracks() {
        isLoadingTracks = true
        tracks = []
        
        Task {
            do {
                try await spotify
                    .loadPlaylistItems(playlist: playlist) { newTracks in
                        tracks.append(contentsOf: newTracks)
                        spotify.trackCache.append(contentsOf: newTracks)
                }
                isLoadingTracks = false
            } catch {
                print("failed to load tracks")
            }
        }
    }
    
    func addTag(track: Track, tag: String) {
        if spotify.songTags[track.id!] == nil {
            spotify.songTags[track.id!] = []
        }
        spotify.songTags[track.id!]!.append(tag)
    }
}

//struct PlaylistDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaylistDetailView()
//    }
//}
