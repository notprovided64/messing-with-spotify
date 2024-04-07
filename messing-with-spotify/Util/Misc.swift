import Foundation
import SwiftUI
import SpotifyWebAPI

extension View {
    
    func eraseToAnyView() -> AnyView {
        return AnyView(self)
    }

}

extension ProcessInfo {
    
    var isPreviewing: Bool {
        return self.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

}
