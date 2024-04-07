//
//  RootView.swift
//  messing-with-spotify
//
//  Created by Preston Clayton on 2/2/23.
//

import SwiftUI
import Combine
import SpotifyWebAPI

struct RootView: View {
    
    @EnvironmentObject var spotify: Spotify

    @State private var alert: AlertItem? = nil
    @State private var loading: Bool = false

    @State private var cancellables: Set<AnyCancellable> = []
    
    var body: some View {
        NavigationView {
            ActionsListView()
                .navigationBarTitle("Home")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        logoutButton
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        refreshButton
                    }
                    
                }
                .refreshable {
                    if !loading {
                        loadSpotifyData()
                    }
                }
                .disabled(!spotify.isAuthorized)
        }
        .modifier(LoginView())
        // Presented if an error occurs during the process of authorizing with
        .alert(item: $alert) { alert in
            Alert(title: alert.title, message: alert.message)
        }
        .onOpenURL(perform: handleURL(_:))
        
    }
    
    func handleURL(_ url: URL) {
        
        guard url.scheme == self.spotify.loginCallbackURL.scheme else {
            print("not handling URL: unexpected scheme: '\(url)'")
            self.alert = AlertItem(
                title: "Cannot Handle Redirect",
                message: "Unexpected URL"
            )
            return
        }
        
        print("received redirect from Spotify: '\(url)'")
        
        spotify.isRetrievingTokens = true
        
        // Complete the authorization process by requesting the access and
        // refresh tokens.
        spotify.api.authorizationManager.requestAccessAndRefreshTokens(
            redirectURIWithQuery: url,
            // This value must be the same as the one used to create the
            // authorization URL. Otherwise, an error will be thrown.
            state: spotify.authorizationState
        )
        .receive(on: RunLoop.main)
        .sink(receiveCompletion: { completion in
            // Whether the request succeeded or not, we need to remove the
            // activity indicator.
            self.spotify.isRetrievingTokens = false
            
            /*
             After the access and refresh tokens are retrieved,
             `SpotifyAPI.authorizationManagerDidChange` will emit a signal,
             causing `Spotify.authorizationManagerDidChange()` to be called,
             which will dismiss the loginView if the app was successfully
             authorized by setting the @Published `Spotify.isAuthorized`
             property to `true`.

             The only thing we need to do here is handle the error and show it
             to the user if one was received.
             */
            if case .failure(let error) = completion {
                print("couldn't retrieve access and refresh tokens:\n\(error)")
                let alertTitle: String
                let alertMessage: String
                if let authError = error as? SpotifyAuthorizationError,
                   authError.accessWasDenied {
                    alertTitle = "You Denied The Authorization Request :("
                    alertMessage = ""
                }
                else {
                    alertTitle =
                        "Couldn't Authorization With Your Account"
                    alertMessage = error.localizedDescription
                }
                self.alert = AlertItem(
                    title: alertTitle, message: alertMessage
                )
            }
        })
        .store(in: &cancellables)
        
        // MARK: IMPORTANT: generate a new value for the state parameter after
        // MARK: each authorization request. This ensures an incoming redirect
        // MARK: from Spotify was the result of a request made by this app, and
        // MARK: and not an attacker.
        self.spotify.authorizationState = String.randomURLSafe(length: 128)
        
    }
    
    /// Removes the authorization information for the user.
    var logoutButton: some View {
        // Calling `spotify.api.authorizationManager.deauthorize` will cause
        // `SpotifyAPI.authorizationManagerDidDeauthorize` to emit a signal,
        // which will cause `Spotify.authorizationManagerDidDeauthorize()` to be
        // called.
        
        
        Button("Logout", action: {
            spotify.api.authorizationManager.deauthorize()
            ///Keychain(service: "com.notpr.messing-with-spotify")["playlist_uri"]
            /// set this value to be nil as well, learn how to do that later
            
        })
            .buttonStyle(.borderedProminent)
    }
    var refreshButton: some View {
        Button("Refresh", action: loadSpotifyData)
            .buttonStyle(.borderedProminent)
            .disabled(loading || !spotify.isAuthorized)
    }
    
    func loadSpotifyData() {
        loading = true
        
        Task {
            do {
                try await spotify.loadSavedTracks()
                try await spotify.loadSavedAlbums()
                try await spotify.loadSavedPlaylists()
                loading = false
            } catch {
                print("error loading all user data")
                loading = false
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    
    static let spotify: Spotify = {
        let spotify = Spotify()
        spotify.isAuthorized = true
        return spotify
    }()
    
    static var previews: some View {
        RootView()
            .environmentObject(spotify)
    }
}
