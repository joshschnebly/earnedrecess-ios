import SwiftUI
import CoreData

struct ParentSettingsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.managedObjectContext) var context

    var body: some View {
        Group {
            if let settings = appState.parentSettings,
               let child = appState.currentChild {
                settingsList(settings: settings, child: child)
            } else {
                ProgressView("Loading settings…")
            }
        }
    }

    private func settingsList(settings: ParentSettings, child: ChildProfile) -> some View {
        Form {
            TaskSettingsSection(
                settings: settings,
                onSave: save
            )

            RewardSettingsSection(
                settings: settings,
                child: child,
                onSave: save,
                onResetBalance: { resetBalance(child: child) }
            )

            YouTubeSettingsSection(
                settings: settings,
                onSave: save
            )

            CalibrationSettingsSection(
                settings: settings,
                onSave: save
            )

            AccountSettingsSection(
                child: child,
                onSave: save,
                onResetAll: { resetAll(child: child, settings: settings) }
            )
        }
        .scrollContentBackground(.hidden)
        .background(Color.erBackground)
    }

    // MARK: - Actions

    private func save() {
        CoreDataStack.shared.save()
        appState.refreshBalance()
    }

    private func resetBalance(child: ChildProfile) {
        StarMinutesService.shared.resetDailyBalance(for: child, context: context)
        appState.refreshBalance()
    }

    private func resetAll(child: ChildProfile, settings: ParentSettings) {
        // Delete all letter sessions and reward sessions
        let sessionReq = LetterSession.fetchRequest()
        sessionReq.predicate = NSPredicate(format: "child == %@", child)
        let sessions = (try? context.fetch(sessionReq)) ?? []
        sessions.forEach { context.delete($0) }

        let rewardReq = RewardSession.fetchRequest()
        rewardReq.predicate = NSPredicate(format: "child == %@", child)
        let rewards = (try? context.fetch(rewardReq)) ?? []
        rewards.forEach { context.delete($0) }

        // Reset child stats
        child.starMinutesBalance = 0
        child.totalStarMinutesEarned = 0
        child.totalStarMinutesSpent = 0
        child.phasePerLetter = [:]

        // Reset settings to defaults
        settings.activeLetterArray = ["A"]
        settings.passingThreshold = Constants.App.defaultPassingThreshold
        settings.timerDurationMinutes = Int32(Constants.App.defaultStarMinutesPerSession)

        CoreDataStack.shared.save()
        appState.refreshBalance()
    }
}
