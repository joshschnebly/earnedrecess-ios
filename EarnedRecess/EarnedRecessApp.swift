import SwiftUI

@main
struct EarnedRecessApp: App {
    let persistenceController = CoreDataStack.shared
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            LaunchRouter()
                .environment(\.managedObjectContext, persistenceController.context)
                .environmentObject(appState)
        }
    }
}
