import SwiftUI
import CoreData

struct LaunchRouter: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    var body: some View {
        Group {
            if appState.isFirstLaunch {
                FirstLaunchFlow()
            } else {
                ChildHomeView()
            }
        }
        .onAppear {
            appState.loadChild(context: context)
            appState.loadSettings(context: context)
        }
    }
}

// MARK: - First Launch Flow coordinator

struct FirstLaunchFlow: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    enum Step {
        case welcome, pinSetup, guidedAccess, childName, letterSelection, complete
    }

    @State private var step: Step = .welcome
    @State private var childName: String = ""
    @State private var selectedLetters: [String] = ["A"]

    var body: some View {
        switch step {
        case .welcome:
            WelcomeView(onContinue: { step = .pinSetup })

        case .pinSetup:
            PINSetupView(onComplete: { step = .guidedAccess })

        case .guidedAccess:
            GuidedAccessInstructionsView(onContinue: { step = .childName })

        case .childName:
            ChildNameEntryView(onComplete: { name in
                childName = name
                step = .letterSelection
            })

        case .letterSelection:
            LetterSelectionView(onComplete: { letters in
                selectedLetters = letters
                step = .complete
            })

        case .complete:
            SetupCompleteView(childName: childName, onFinish: finishSetup)
        }
    }

    private func finishSetup() {
        let child = ChildProfile.create(name: childName, context: context)
        let settings = ParentSettings.createDefaults(context: context)
        settings.activeLetterArray = selectedLetters
        do {
            try context.save()
        } catch {
            print("[EarnedRecess] Fetch error: \(error.localizedDescription)")
        }
        appState.currentChild = child
        appState.parentSettings = settings
        appState.completeSetup()
    }
}
