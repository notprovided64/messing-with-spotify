import Combine
import SwiftUI
import SpotifyWebAPI
import KeychainAccess
import OrderedCollections

struct TagView: View {
    @EnvironmentObject var spotify: Spotify
    
    @State var isLoading: Bool = false
    @State var selectedTags: OrderedSet<String> = []
    @State var excludedTags: OrderedSet<String> = []

    @State private var alert: AlertItem? = nil
    
    var body: some View {
        List {
            Section {
                TagSelectionPicker(title: "Selected Tags", selection: $selectedTags)
                TagSelectionPicker(title: "Excluded Tags", selection: $excludedTags)
            }
            
            Section("Results") {
                ForEach(searchResults, id: \.id) { track in
                    TrackView(track: track)
                }
            }
        }
        .navigationBarItems(trailing: uploadButton)

    }
    
    
    var searchResults: [Track] {
        if selectedTags == [] {
            return []
        } else {
            return spotify.trackCache.filter({
                selectedTags.isSubset(of: Set(spotify.songTags[$0.id!, default: []]))
                &&
                spotify.songTags[$0.id!, default: []].intersection(excludedTags).isEmpty
            })
        }
    }
    
    var uploadButton: some View {
        Button(action: uploadPlaylist) {
            Image(systemName: "square.and.arrow.up")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(isLoading)
    }
    
    func uploadPlaylist() {
        isLoading = true
        
//        var uri = Keychain(service: "com.notpr.messing-with-spotify")["playlist_uri"]
        var uri: String? = nil

        Task {
            if uri == nil {
                uri = try await spotify.api
                    .createPlaylist(for: spotify.currentUser!.uri, PlaylistDetails(name: "messing-with-spotify playlist"))
                    .async().uri
                Keychain(service: "com.notpr.messing-with-spotify")["playlist_uri"] = uri
            }
            
            guard uri != nil else {
                isLoading = false
                return
            }
            
            try await spotify.clearPlaylist(playlist: uri!)
            try await spotify.addTracksToPlaylist(playlist: uri!, uris: playlistURIs())
            
            await UIApplication.shared.open(URL(string: uri!)!)

            isLoading = false
        }
        
        
    }
    
    func makePlaylist() async throws -> String {
        return try await spotify.api
            .createPlaylist(for: spotify.currentUser!.uri, PlaylistDetails(name: "messing-with-spotify"))
            .async().uri
    }
    
    
    func playlistURIs() -> [String] {
        var links = [String]()
        
        for track in searchResults {
            links.append(track.uri!)
        }
        
        return links
    }
}


struct TagSelectionPicker: View {
    let title: String
    
    @EnvironmentObject var spotify: Spotify
    @Binding var selection: OrderedSet<String>
    
    var body: some View {
        Menu {
            ForEach(spotify.userTags, id: \.self) { tag in
                Toggle(tag, isOn: Binding<Bool>(get: {
                    return selection.contains([tag])
                }, set: { value in
                    if value {
                        selection.append(tag)
                    } else {
                        selection.remove(tag)
                    }
                }))
            }
        } label : {
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Text(selection.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)

            }
        }
    }
}

struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        TagView()
            .environmentObject(Spotify())
    }
}
