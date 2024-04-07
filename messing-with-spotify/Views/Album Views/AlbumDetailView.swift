import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent

struct AlbumDetailView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var alert: AlertItem? = nil
    
    @State private var loadTracksCancellable: AnyCancellable? = nil
    
    @State private var isLoadingTracks = false
    @State private var couldntLoadTracks = false
    
    @State var allTracks: [Track] = []
    
    var sharedTags: [String] {
        if allTracks.isEmpty || isLoadingTracks || spotify.songTags[allTracks[0].id!] == nil {
            return []
        }
        
        var tags: Set<String> = Set(spotify.songTags[allTracks[0].id!]!)
        
        for track in allTracks {
            tags = tags.union(spotify.songTags[track.id!, default: []])
        }
        
        return Array(tags)
    }


    let album: Album
    let image: Image
    
    @State private var presentAlert = false
    @State private var tagName: String = ""

    
    init(album: Album, image: Image) {
        self.album = album
        self.image = image
    }
    
    /// Used by the preview provider to provide sample data.
    fileprivate init(album: Album, image: Image, tracks: [Track]) {
        self.album = album
        self.image = image
        self._allTracks = State(initialValue: tracks)
    }

    /// The album and artist name; e.g., "Abbey Road - The Beatles".
    var albumAndArtistName: String {
        var title = album.name
        if let artistName = album.artists?.first?.name {
            title += " - \(artistName)"
        }
        return title
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ZStack {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(20)
                        .shadow(radius: 20)
                }
                    .frame(width: 300, height: 300)
                    .padding(30)
                Text(albumAndArtistName)
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
                    .padding(.top, -10)
                Text("\(album.tracks?.total ?? 0) Tracks")
                    .foregroundColor(.secondary)
                    .font(.title2)
                    .padding(.vertical, 10)
                HStack {
                    Menu("Add tag") {
                        ForEach(spotify.userTags, id: \.self) { tag in
                            Button(tag, action: {
                                for track in allTracks {
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
                                for track in allTracks {
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

                if allTracks.isEmpty {
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
                        else if couldntLoadTracks {
                            Text("Couldn't Load Tracks")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                }
                else {
                    ForEach(
                        Array(allTracks.enumerated()),
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
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear(perform: loadTracks)
    }
    
    func addTag(track: Track, tag: String) {
        if spotify.songTags[track.id!] == nil {
            spotify.songTags[track.id!] = []
        }
        spotify.songTags[track.id!]!.append(tag)
    }

    
    /// Loads the album tracks.
    func loadTracks() {
        
        if ProcessInfo.processInfo.isPreviewing { return }
        
        guard let tracks = self.album.tracks else {
            return
        }
        
        self.isLoadingTracks = true
        self.allTracks = []
        self.loadTracksCancellable = self.spotify.api.extendPages(tracks)
            .map(\.items)
            .receive(on: RunLoop.main)
            .sink(
                receiveCompletion: { completion in
                    self.isLoadingTracks = false
                    switch completion {
                    case .finished:
                        self.couldntLoadTracks = false
                    case .failure(let error):
                        self.couldntLoadTracks = true
                        self.alert = AlertItem(
                            title: "Couldn't Load Tracks",
                            message: error.localizedDescription
                        )
                    }
                },
                receiveValue: { tracks in
                    self.allTracks.append(contentsOf: tracks)
                    spotify.trackCache.append(contentsOf: tracks)
                }
            )
    }
}

//struct AlbumDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        AlbumDetailView()
//    }
//}
