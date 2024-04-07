//
//  ActionsListView.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 2/2/23.
//

import SwiftUI


struct ActionsListView: View {
    var body: some View {
        List {
            Section("Tags") {
                NavigationLink("Tag List", destination: UserTagsView())
                NavigationLink("Search Tags", destination: TagView())
            }
            Section("User Content") {
                NavigationLink("Tracks", destination: SavedTracksView())
                NavigationLink("Albums", destination: SavedAlbumsView())
                NavigationLink("Playlists", destination: SavedPlaylistsView())
            }
            Section("Settings") {
                NavigationLink("Debug", destination: DebugMenuView())
                NavigationLink("lol", destination: ContentView())
            }
        }
    }
}

struct ActionsListView_Previews: PreviewProvider {
    static var previews: some View {
        ActionsListView()
    }
}
