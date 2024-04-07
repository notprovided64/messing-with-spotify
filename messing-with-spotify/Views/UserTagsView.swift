//
//  UserTagsView.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 3/31/23.
//

import SwiftUI
import OrderedCollections


struct UserTagsView: View {
    @EnvironmentObject var spotify: Spotify
    
    @State private var presentAlert = false
    @State private var tagName: String = ""

    var body: some View {
        Group {
            List{
                ForEach(spotify.userTags, id: \.self) { tag in
                    Text(tag)
                }
                .onDelete(perform: delete)
                .onMove { from, to in
                    spotify.userTags.elements.move(fromOffsets: from, toOffset: to)
                }
            }
        }
        .alert("New Tag", isPresented: $presentAlert, actions: {
            TextField("Username", text: $tagName)
                .autocorrectionDisabled()
            Button("Add", action: {
                spotify.userTags.append(tagName)
                spotify.objectWillChange.send()
                tagName = "" 
            })
            Button("Cancel", role: .cancel, action: { tagName = "" })
        }, message: {
            Text("Enter tag name: ")
        })
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { presentAlert = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .navigationTitle("Tags")
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let tag = spotify.userTags.elements[index]
            spotify.userTags.elements.remove(at: index)
            
            for track in spotify.trackCache {
                spotify.songTags[track.id!, default: []].remove(tag)
            }
        }
    }
}

struct UserTagsView_Previews: PreviewProvider {
    static var previews: some View {
        UserTagsView()
    }
}
