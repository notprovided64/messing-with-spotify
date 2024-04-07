import SwiftUI
import Combine
import SpotifyWebAPI

struct SavedAlbumsView: View {
    @EnvironmentObject var spotify: Spotify

    @State private var alert: AlertItem? = nil

    let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 200))
    ]
    
    var body: some View {
        Group {
            if spotify.savedAlbums.isEmpty {
                if spotify.loadingSavedAlbums {
                    HStack {
                        ProgressView()
                            .padding()
                        Text("Loading Albums")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                else if spotify.failedLoadingSavedAlbums {
                    Text("Couldn't Load Albums")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
                else {
                    Text("No Albums")
                        .font(.title)
                        .foregroundColor(.secondary)
                }
            }
            else {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach(spotify.savedAlbums, id: \.id) { album in
                            AlbumView(album: album)
                        }
                    }
                    .padding()
                    .accessibility(identifier: "Saved Albums Grid")
                }
                .refreshable {
                    if !spotify.loadingSavedAlbums {
                        retrieveSavedAlbums()
                    }
                }

            }
            
        }
        .navigationTitle("Saved Albums")
        .navigationBarItems(trailing: refreshButton)
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onAppear {
            if spotify.savedAlbums.isEmpty && !spotify.loadingSavedAlbums {
                retrieveSavedAlbums()
            }
        }
    }
    
    var refreshButton: some View {
        Button(action: retrieveSavedAlbums) {
            Image(systemName: "arrow.clockwise")
                .font(.title)
                .scaleEffect(0.8)
        }
        .disabled(spotify.loadingSavedAlbums)
    }
    
    func retrieveSavedAlbums() {
        Task {
            do {
                try await spotify.loadSavedAlbums()
            } catch {
                alert = AlertItem(
                    title: "Couldn't Retrieve Albums",
                    message: error.localizedDescription
                )
            }
        }
    }
}

struct SavedAlbumsView_Previews: PreviewProvider {
    static var previews: some View {
        SavedAlbumsView()
    }
}
