import SwiftUI
import Combine
import SpotifyWebAPI
import SpotifyExampleContent
import OrderedCollections

struct SavedTracksView: View {
    
    @EnvironmentObject var spotify: Spotify
    
    @State private var alert: AlertItem? = nil
    
    @State private var searchText = ""

    @State private var couldntLoadTracks = false
            
    init() { }
    
    fileprivate init(sampleTracks: [Track]) {
        spotify.savedTracks = sampleTracks
    }

    var body: some View {
        Group {
            if spotify.savedTracks.isEmpty {
                if spotify.loadingSavedTracks {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Tracks")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if spotify.failedLoadingSavedTracks {
                    Text("Couldn't Load Tracks")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    Text("No Tracks")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                List {
                    ForEach(searchResults, id: \.id) { track in
                        TrackView(track: track)
                        Divider()
                    }
                    .searchable(text: $searchText)
                    .autocorrectionDisabled()
                }
                .refreshable {
                    if !spotify.loadingSavedTracks {
                        retrieveSavedTracks()
                    }
                }
            }
            
        }
        .navigationTitle("Saved Tracks")
        .navigationBarItems(trailing: refreshButton)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear {
            if !spotify.loadingSavedTracks && spotify.savedTracks.isEmpty {
                retrieveSavedTracks()
            }
        }
    }
    
    var searchResults: [Track] {
        if searchText.isEmpty {
            return spotify.savedTracks
        } else {
            return spotify.savedTracks.filter {
                $0.name.contains(searchText)
            }
        }
    }
    
    var refreshButton: some View {
        Button(action: retrieveSavedTracks) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(spotify.loadingSavedTracks)
        
    }
    
    func retrieveSavedTracks() {
        Task {
            do {
                try await spotify.loadSavedTracks()
                couldntLoadTracks = false
            } catch {
                couldntLoadTracks = true
                alert = AlertItem(
                    title: "Couldn't Retrieve Tracks",
                    message: error.localizedDescription
                )
            }
        }
    }
}

//struct SavedTracksView_Previews: PreviewProvider {
//    static let sampleTracks: [Track] = [
//            .because, .comeTogether, .faces,
//            .illWind, .odeToViceroy, .reckoner,
//            .theEnd, .time
//        ]
//
//    static var previews: some View {
//        
//        NavigationView {
//            SavedTracksView(sampleTracks: sampleTracks)
//                .environmentObject(UserData())
//                .environmentObject(Spotify())
//        }
//            
//    }
//    
//}
