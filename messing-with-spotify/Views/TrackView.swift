import Combine
import SpotifyWebAPI
import SpotifyExampleContent
import SwiftUI
import UIKit

struct TrackView: View {
    @EnvironmentObject var spotify: Spotify
    
    let track: Track
    
    @State private var presentAlert = false
    @State private var tagName: String = ""
    
    var body: some View {
        Menu {
            Text(spotify.songTags[track.id!, default: []].isEmpty ? "No tags" : spotify.songTags[track.id!]!.joined(separator:", "))
            Menu("Add tag") {
                ForEach((spotify.userTags.subtracting(spotify.songTags[track.id!, default: []])), id: \.self) { tag in
                    Button(tag, action: {
                        if spotify.songTags[track.id!] == nil {
                            spotify.songTags[track.id!] = []
                        }
                        spotify.songTags[track.id!]!.append(tag)
                    })
                }
                Button(action: { presentAlert = true }, label:{Label("New", systemImage: "plus")})
            }
            Menu("Remove tag") {
                ForEach(spotify.songTags[track.id!, default: []], id: \.self) { tag in
                    Button(tag, action: {
                        spotify.songTags[track.id!]!.remove(tag)
                        
                        /// the spotify song list won't trigger update when a value in the song object changes
                        /// therefore you need to tell it to update manually when that happens, or else computed
                        /// properties won't
                        spotify.objectWillChange.send()
                    })
                }
            }
            if !spotify.songTags[track.id!, default: []].isEmpty {
                Button("Clear tags", role: .destructive, action: {
                    spotify.songTags[track.id!] = []
                    spotify.objectWillChange.send()
                })
            }
        } label : {
            HStack {
                VStack(alignment: .leading) {
                    Text(track.name)
                    Text(artistNames())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
        .foregroundColor(.primary)
        .alert("New Tag", isPresented: $presentAlert, actions: {
            TextField("Username", text: $tagName)
                .autocorrectionDisabled()
            Button("Add", action: {
                if spotify.songTags[track.id!] == nil {
                    spotify.songTags[track.id!] = []
                }
                spotify.songTags[track.id!]!.append(tagName)

                spotify.userTags.append(tagName)
                spotify.objectWillChange.send()
            })
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text("Enter tag name: ")
        })

    }
    
    /// The display name for the track. E.g., "Eclipse - Pink Floyd".
    func artistNames() -> String {
        guard let artists = track.artists?.map({$0.name}) else {
            return ""
        }
        
        
        return artists.joined(separator: ", ")
    }
}

struct TrackView_Previews: PreviewProvider {
    
    static let tracks: [Track] = [
        .because, .comeTogether, .faces,
        .illWind, .odeToViceroy, .reckoner,
        .theEnd, .time
    ]

    static var previews: some View {
        List(tracks, id: \.id) { track in
            TrackView(track: track)
        }
        .environmentObject(Spotify())
    }
}
