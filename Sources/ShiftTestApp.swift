import SwiftUI

@main
struct ShiftTestApp: App {
    @StateObject private var store = ShiftStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
