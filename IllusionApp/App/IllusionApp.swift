import SwiftUI

@main
struct IllusionApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No window scenes — all windows are managed imperatively via AppDelegate.
        Settings { EmptyView() }
    }
}
