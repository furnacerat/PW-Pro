import SwiftUI

@main
struct PWProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .background(Theme.slate900)
                #if os(macOS)
                .frame(minWidth: 800, minHeight: 600)
                #endif
        }
    }
}
