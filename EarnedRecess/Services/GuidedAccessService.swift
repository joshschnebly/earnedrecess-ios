import UIKit
import SwiftUI

enum GuidedAccessService {
    static var isEnabled: Bool {
        UIAccessibility.isGuidedAccessEnabled
    }

    static var statusLabel: String {
        isEnabled ? "Active ✓" : "Not Active"
    }

    static var statusColor: Color {
        isEnabled ? .erGreen : .erOrange
    }
}
