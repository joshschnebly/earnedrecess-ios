# EarnedRecess — iOS iPad App Design Document
### Version 2.0 | POC Build Complete | Last Updated: April 2026

---

## 📊 Current Status

| Area | Status | Notes |
|---|---|---|
| **App compiles & builds** | ✅ Done | Verified on MacinCloud |
| **Core loop (draw → earn → watch)** | ✅ Done | All 3 modes working |
| **Drawing engine (A–Z, a–z)** | ✅ Done | 52 letters, 3 phases, tracing arrows |
| **Scoring (5 components)** | ✅ Done | Overlap, proportion, stroke count, smoothness, key points |
| **Star Minutes system** | ✅ Done | Award, spend, daily cap, bedtime, quality multiplier |
| **YouTube browser + player** | ✅ Done | WKWebView, channel shortcuts, mock fallback |
| **Timer engine** | ✅ Done | Background handling, expiry gate |
| **Parent PIN gate** | ✅ Done | Keychain, bcrypt, lockout, device salt |
| **Parent settings** | ✅ Done | All configurable (see Section 11) |
| **Parent dashboard** | ✅ Done | Overview, Letters, History, Watch Time |
| **Auto-calibration** | ✅ Done | Suggests threshold adjustments |
| **WriteToWatch mode** | ✅ Done | Child writes video title letters to unlock |
| **Voice prompts** | ✅ Done | AVSpeechSynthesizer |
| **Word association** | ✅ Done | A=Apple 🍎, etc. |
| **Unit tests** | ✅ Done | 98 tests across 10 test files |
| **YouTube API key** | ⏳ TODO | Falls back to mock data until added |
| **App icon / mascot art** | ⏳ TODO | Needed before TestFlight |
| **Cocomelon channel ID** | ⏳ TODO | Placeholder in Constants.swift |
| **AWS EC2 Mac** | ⏳ Pending | Quota approved, activation pending |

---

## 🧭 Document Purpose

This document is the single source of truth for the EarnedRecess iPad app.
The developer is a senior .NET/web developer with 25 years experience.
All Swift/SwiftUI code is AI-generated (Claude in VS Code) and reviewed by the developer.
Dev machine is Windows. Build machine is MacinCloud (or AWS EC2 Mac).

---

## 📋 Table of Contents

1. [Product Overview](#1-product-overview)
2. [Technical Stack](#2-technical-stack)
3. [Architecture Overview](#3-architecture-overview)
4. [Data Models](#4-data-models)
5. [App Modes](#5-app-modes)
6. [User Experience Flows](#6-user-experience-flows)
7. [Drawing Engine](#7-drawing-engine)
8. [Star Minutes System](#8-star-minutes-system)
9. [YouTube Kids Integration](#9-youtube-kids-integration)
10. [Parent Module](#10-parent-module)
11. [Parent Settings Reference](#11-parent-settings-reference)
12. [Parental Dashboard](#12-parental-dashboard)
13. [Guided Access Strategy](#13-guided-access-strategy)
14. [File & Folder Structure](#14-file--folder-structure)
15. [Build & Deployment](#15-build--deployment)
16. [Future Architecture Hooks](#16-future-architecture-hooks)
17. [Backlog](#17-backlog)

---

## 1. Product Overview

### What Is EarnedRecess?

EarnedRecess is a **reward-gated learning platform** for iPads. Children earn screen time
(watching YouTube Kids) by completing educational tasks (drawing letters with Apple Pencil).
The parent controls all settings behind a PIN. The iPad is locked to the app via iOS Guided Access.

### Core Loop

```
Child opens EarnedRecess
  → Prompted to complete a learning task
  → Draws letters using Apple Pencil on iPad
  → Scored for accuracy (5-component algorithm)
  → Earns "Star Minutes" on pass
  → YouTube Kids unlocks inside the app
  → Timer counts down Star Minutes
  → Time expires → YouTube pauses → new task required
```

### Design Principles

- **Child-first UI**: Age 5 target. Giant buttons. No text required to navigate.
  Bright, friendly, animated. Voice prompts where possible.
- **Parent-in-control**: Every setting locked behind PIN. Dashboard always available.
- **Progression-aware**: The app gets harder as the child improves. Never static.
- **Future-proof**: Architecture supports pluggable tasks and rewards in V2.
- **App Store ready**: COPPA-aware, no 3rd party analytics, on-device data only for V1.

---

## 2. Technical Stack

| Layer | Technology | Notes |
|---|---|---|
| Language | Swift 5.9+ | |
| UI Framework | SwiftUI | iOS 16+ declarative |
| Drawing | PencilKit (PKCanvasView) | Native Apple Pencil support |
| Video | WKWebView + YouTube IFrame API | Embedded in-app |
| Data Persistence | CoreData | On-device, COPPA-safe |
| Security | Security framework (Keychain) | PIN storage, bcrypt hash |
| Voice | AVSpeechSynthesizer | Letter/word prompts |
| Animation | SwiftUI animations + CAKeyframeAnimation | No Lottie yet |
| Target Device | iPad (Apple Pencil compatible) | iPad 6th gen or later |
| iOS Target | iOS 16.0+ | |
| Xcode | 15.0+ | |
| Charts | Swift Charts (built-in, iOS 16+) | No external charts lib |

---

## 3. Architecture Overview

```
EarnedRecess/
│
├── App Entry Point (LaunchRouter)
│   └── firstLaunch → Setup Flow  |  else → ChildHome
│
├── Core/
│   ├── AppState               ← ObservableObject, app-wide state
│   ├── Theme                  ← Colors, fonts, spacing (er* prefix)
│   ├── Constants              ← Scoring weights, defaults, keychain keys
│   ├── AppEnums               ← AppMode, LetterCase, TemplateStyle
│   ├── PhoneticLibrary        ← A-Z sounds ("Ay", "Bee", etc.)
│   ├── WordAssociationLibrary ← A-Z emoji + words (A=Apple🍎)
│   └── Extensions/            ← Color+Theme, View+Helpers, Date+Formatting,
│                                  Int+Timer, Collection+Safe
│
├── Data/
│   ├── CoreData/              ← EarnedRecess.xcdatamodeld, CoreDataStack
│   ├── Models/                ← NSManagedObject subclasses (+Extensions files)
│   │   ├── ChildProfile       ← name, phasePerLetter (JSON), star balance
│   │   ├── LetterSession      ← each practice session per letter
│   │   ├── DrawingAttempt     ← individual draw attempt + all scores
│   │   ├── RewardSession      ← YouTube watch time record
│   │   └── ParentSettings     ← singleton config record
│   └── Repositories/
│       ├── LetterRepository   ← recentScores, allSessions per letter
│       ├── SessionRepository  ← today's stats, recent reward sessions
│       └── SettingsRepository ← getOrCreate singleton
│
├── Services/
│   ├── KeychainService        ← PIN hash, attempts, lockout, device salt
│   ├── StarMinutesService     ← award, spend, spendOneMinute, daily cap
│   ├── ScoringService         ← finaliseSession, bedtime guard, phase check
│   ├── CalibrationService     ← analyze recent sessions → tooEasy/tooHard
│   ├── SpeechService          ← AVSpeechSynthesizer singleton
│   ├── YouTubeKidsService     ← search, featured channels, mock fallback
│   └── GuidedAccessService    ← UIAccessibility.isGuidedAccessEnabled
│
├── DrawingEngine/
│   ├── DrawingCanvasView      ← PKCanvasView UIViewRepresentable
│   ├── LetterTemplate         ← model: letter, path, keyPoints, aspectRatio
│   ├── LetterTemplateLibrary  ← all 52 letters, image cache, glyph path
│   ├── StrokeAnalyzer         ← 5-component scoring algorithm
│   ├── ProgressionEngine      ← shouldAdvancePhase, nextPhase
│   ├── StrokePathLibrary      ← ordered stroke sequences for tracing arrows
│   ├── TracingArrowsView      ← UIView, CAKeyframeAnimation arrowheads
│   └── CanvasViewTag          ← enum for subview tags (template/alignment/arrows)
│
├── TimerEngine/
│   └── RewardTimer            ← countdown, background handling, onExpired
│
└── Features/
    ├── Launch/                ← LaunchRouter, FirstLaunchFlow (6 screens)
    ├── Child/                 ← ChildHomeView, StarWalletView, MascotView
    ├── Task/                  ← TaskGateView, DrawingSessionView,
    │                             SingleAttemptView, SessionCompleteView,
    │                             WriteToWatchView, LetterIntroSplashView
    ├── Reward/                ← RewardPlayerView, VideoBrowserView,
    │                             YouTubePlayerView, TimerExpiredOverlayView
    └── Parent/                ← PINEntryView, ParentTabView
        ├── Settings/          ← ParentSettingsView + 5 section files
        └── Dashboard/         ← DashboardView, OverviewTab, LettersTab,
                                  HistoryTab, WatchTimeTab, CalibrationBannerView
```

---

## 4. Data Models

### CoreData Entities (codeGenerationType="none" on all)

```swift
// ChildProfile
id: UUID, name: String, createdAt: Date
phasePerLetterData: Binary          // JSON-encoded [String:Int] — e.g. {"A":2,"b":1}
starMinutesBalance: Int32           // current spendable balance
totalStarMinutesEarned: Int32
totalStarMinutesSpent: Int32
→ relationship: letterSessions (LetterSession[])
→ relationship: rewardSessions (RewardSession[])

// LetterSession
id: UUID, letter: String, sessionDate: Date
phase: Int16                        // 1=tracing, 2=guided, 3=freehand
attemptsRequired: Int16, attemptsCompleted: Int16
averageScore: Double (0.0–1.0), passed: Bool
starMinutesEarned: Int32, duration: Double
→ relationship: child (ChildProfile)
→ relationship: attempts (DrawingAttempt[])

// DrawingAttempt
id: UUID, attemptNumber: Int16, letter: String
overlapScore: Double, proportionScore: Double
strokeCountScore: Double, smoothnessScore: Double
keyPointsScore: Double, compositeScore: Double
passed: Bool, inkData: Data?, timestamp: Date
→ relationship: session (LetterSession)

// RewardSession
id: UUID, startTime: Date, endTime: Date?
minutesWatched: Int32, minutesEarned: Int32
videoTitle: String?, videoId: String?
→ relationship: child (ChildProfile)

// ParentSettings (singleton — fetchLimit:1, no relationship to ChildProfile)
id: UUID
// Task
activeLetters: String               // comma-separated, e.g. "A,B,C"
attemptsPerSession: Int32           // default 10
passingThreshold: Double            // default 0.60
progressionThreshold: Double        // default 0.85
autoProgressionEnabled: Bool
requireAllLetters: Bool             // must draw ALL active letters before watching
letterCase: String                  // "uppercase" | "lowercase" | "both"
templateStyle: String               // "solid" | "dotted" | "none"
showAlignmentLines: Bool
tracingArrowsEnabled: Bool
tracingArrowsContinuous: Bool
tracingArrowsSequential: Bool
letterSoundsEnabled: Bool
wordAssociationEnabled: Bool
// Reward
appMode: String                     // "standard" | "writeToWatch" | "both"
timerDurationMinutes: Int32         // star minutes awarded per session (default 20)
maxDailyMinutes: Int32              // daily cap (default 120)
bedtimeHour: Int32                  // hour after which no awards (default 20 = 8pm)
writeToWatchThreshold: Double       // passing threshold for WriteToWatch (default 0.50)
// Calibration
autoCalibrationEnabled: Bool
calibrationWindow: Int32            // sessions to analyze (default 10)
// Child name
childName: String
```

---

## 5. App Modes

Three modes selectable in parent settings:

| Mode | Description |
|---|---|
| **Standard** | Draw letters → earn Star Minutes → watch YouTube freely |
| **WriteToWatch** | No Star Minutes banking — must draw the video's title letters before each video plays |
| **Both** | Standard mode + WriteToWatch intercept before each video |

WriteToWatch flow:
1. Child taps a video thumbnail
2. App extracts first word of title (uppercase A–Z letters only)
3. Child draws each letter at 50% passing threshold (configurable)
4. On pass → video plays; on fail → try again

---

## 6. User Experience Flows

### 6.1 First Launch (Parent)

```
Launch → WelcomeView
  → PINSetupView (enter PIN × 2, stored in Keychain)
  → GuidedAccessInstructionsView
  → ChildNameEntryView
  → LetterSelectionView (default: A only)
  → SetupCompleteView → ChildHome
```

### 6.2 Daily Child Flow

```
ChildHome
  ├── [TAP: DRAW LETTERS]
  │     → TaskGateView (shows letter, instructions, stars to earn)
  │     → DrawingSessionView (manages N attempts)
  │         → LetterIntroSplashView (2s splash: emoji + letter + word)
  │         → SingleAttemptView (draw → score → next)
  │     → SessionCompleteView (avg score + stars + celebration)
  │     → ChildHome (balance updated)
  │
  └── [TAP: WATCH YOUTUBE] (requires stars > 0, or all letters practiced if requireAllLetters=true)
        → VideoBrowserView (channel shortcuts + thumbnail grid)
        │   [WriteToWatch/Both mode: intercept here]
        │   → WriteToWatchView (draw title letters at 50% threshold)
        │   → on pass: video plays
        → RewardPlayerView (embedded YouTube + countdown timer)
        → Timer expires → TimerExpiredOverlayView
            → [Draw More] → TaskGateView
            → [Done for now] → ChildHome
```

### 6.3 Parent Access

```
ChildHome → [Triple-tap top-right corner]
  → PINEntryView (custom numpad, 3-attempt lockout, 30s countdown)
  → ParentTabView
      ├── Dashboard tab (charts, history, calibration banner)
      ├── Settings tab (all settings sections)
      └── Exit to Child (Guided Access reminder alert if GA is off)
```

### 6.4 Letter Selection (TaskGateView)

Picks letter to practice:
1. Get all active letters from settings
2. Get all letters practiced today (sessions with letter != nil/empty)
3. Find unpracticed letters → pick first alphabetically
4. If all practiced → find least-practiced (fewest sessions today)
5. Fallback: first active letter

---

## 7. Drawing Engine

### 7.1 Phases

| Phase | Visual Aid | Notes |
|---|---|---|
| 1 — Tracing | Solid semi-transparent letter (25% opacity) | Default start |
| 2 — Guided | Dotted outline only | Auto-advance when rolling avg ≥ progressionThreshold |
| 3 — Freehand | No visual aid | Most advanced |

Phase stored per-letter in ChildProfile.phasePerLetterData (JSON).
Auto-progression checks last 10 sessions rolling average.

### 7.2 Scoring Algorithm (5 Components)

| Component | Weight | What It Measures |
|---|---|---|
| Overlap | 35% | Pixel coverage of reference path |
| Proportion | 18% | Bounding box aspect ratio vs expected |
| Stroke Count | 18% | Actual vs expected stroke count (−33% per extra/missing) |
| Smoothness | 14% | Point-to-point angle variance |
| Key Points | 15% | Coverage of critical letter waypoints |

Composite ≥ passingThreshold (default 0.60) → session passes.

All weights defined in `Constants.Scoring`. All thresholds stored in ParentSettings.

### 7.3 Tracing Arrows

- `StrokePathLibrary` contains ordered stroke sequences for all 26 uppercase letters
- `TracingArrowsView` (UIView) animates arrowheads along paths using CAKeyframeAnimation
- Two modes: **continuous** (all arrows always moving) and **sequential** (one stroke at a time)

### 7.4 Session Rules

- Attempts per session: configurable (default 10, range 5–20)
- [DONE] button available after ≥ 2 strokes (prevents empty submissions)
- Canvas auto-clears after each attempt
- Session passes: average composite ≥ passingThreshold
- Failed session: encouragement shown, retry or go home

---

## 8. Star Minutes System

### 8.1 Earning

```
Base award = settings.timerDurationMinutes (default 20)

Quality multiplier (applied to base):
  composite 60–74% → 1.0× (base)
  composite 75–89% → 1.25×
  composite 90%+   → 1.5×

Daily cap check:
  todayEarned + award > maxDailyMinutes → clamp award to remaining
  
Bedtime guard:
  if current hour >= bedtimeHour → award 0 (session still recorded as passed)
```

### 8.2 Spending

- Star Minutes spend 1:1 as real minutes of YouTube watch time
- `StarMinutesService.spendOneMinute()` called every 60s by RewardPlayerView
- Debounced CoreData save (5s DispatchWorkItem) to avoid excessive writes
- Balance stored on ChildProfile.starMinutesBalance

### 8.3 Auto-Calibration

`CalibrationService.analyze(child:settings:context:)` returns:
- `.tooEasy` — pass rate > 80% AND avg score > 0.90 → suggest raising threshold by 0.05
- `.tooHard` — pass rate < 40% OR avg score < 0.45 → suggest lowering threshold by 0.05
- `.onTrack` — nil (no suggestion)
- `nil` — fewer than 5 sessions in window

CalibrationBannerView appears on parent dashboard OverviewTab when a suggestion is available.

---

## 9. YouTube Kids Integration

### 9.1 API

- YouTube Data API v3 (Google Cloud Console)
- Key stored in `EarnedRecess/Resources/Secrets.swift` (gitignored)
- Falls back to mock video list if key is empty
- `safeSearch=strict`, `type=video`
- Quota: 10,000 units/day free; search = 100 units

### 9.2 Setup (TODO)

```
1. console.cloud.google.com → New project "EarnedRecess"
2. APIs & Services → Library → YouTube Data API v3 → Enable
3. Credentials → Create API Key
4. Restrict to iOS app: bundle ID com.earnedrecess.app
5. Copy key to EarnedRecess/Resources/Secrets.swift:
   enum Secrets { static let youTubeAPIKey = "YOUR_KEY" }
6. echo "EarnedRecess/Resources/Secrets.swift" >> .gitignore
```

### 9.3 Featured Channels

Defined in `Constants.YouTube.featuredChannelIds` and referenced by `YouTubeKidsService.featuredChannels`:

| Channel | Status |
|---|---|
| Bluey | ✅ Real ID |
| Peppa Pig | ✅ Real ID |
| Paw Patrol | ✅ Real ID |
| Cocomelon | ⚠️ TODO — placeholder using Bluey's ID |

### 9.4 Player

`YouTubePlayerView` (UIViewRepresentable wrapping WKWebView):
- YouTube IFrame API via injected HTML
- JS message handlers: ready, ended, playing, paused
- Blocks navigation away from youtube.com
- Exposes `onPlayerReady` and `onVideoEnded` callbacks

---

## 10. Parent Module

### 10.1 PIN Gate

- 4-digit custom numpad (no iOS keyboard)
- PIN hash stored in Keychain with device-specific random salt
- 3 wrong attempts → 30-second lockout with countdown
- Lockout state persisted in Keychain (survives app kill)
- Access triggered: triple-tap top-right corner of ChildHome

### 10.2 Settings Organization

Five sections (see Section 11 for full reference):
1. Task Settings
2. Reward Settings
3. YouTube Settings
4. Calibration Settings
5. Account Settings

### 10.3 Exit to Child

- Shows Guided Access status
- Alert if Guided Access is OFF before handing to child
- "Hand to [ChildName]" button

---

## 11. Parent Settings Reference

| Setting | Default | Where Used |
|---|---|---|
| Active letters | A | TaskGateView, ChildHomeView |
| Attempts per session | 10 | DrawingSessionView |
| Passing threshold | 0.60 | ScoringService, SingleAttemptView |
| Progression threshold | 0.85 | ProgressionEngine |
| Auto-progression | on | ScoringService |
| Require all letters | off | ChildHomeView, TaskGateView |
| Letter case | uppercase | DrawingSessionView.effectiveLetter |
| Template style | solid | DrawingCanvasView.effectivePhase |
| Show alignment lines | off | DrawingCanvasView |
| Tracing arrows | off | DrawingCanvasView |
| Tracing arrows continuous | on | TracingArrowsView |
| Tracing arrows sequential | off | TracingArrowsView |
| Letter sounds | on | SingleAttemptView |
| Word association | on | LetterIntroSplashView |
| App mode | standard | VideoBrowserView, RewardPlayerView |
| Star minutes per session | 20 | StarMinutesService |
| Daily max minutes | 120 | StarMinutesService |
| Bedtime hour | 20 (8pm) | ScoringService |
| WriteToWatch threshold | 0.50 | WriteToWatchView |
| Auto-calibration | on | CalibrationService, CalibrationBannerView |
| Calibration window | 10 | CalibrationService |

---

## 12. Parental Dashboard

### Tabs

**Overview:**
- Today: letters practiced, stars earned, minutes watched, progress bar vs daily cap
- 7-day bar chart (earned vs watched per day)
- Calibration banner (orange, appears when CalibrationService has a suggestion)

**Letters:**
- Grid of active letters with avg score, phase badge, trend arrow (↑↓→)
- Trend based on newest vs second-newest session score
- Adaptive columns by size class

**History:**
- Session list: date, letter, phase, score, passed/failed, stars earned
- Tap session → attempt-by-attempt breakdown with individual scores

**Watch Time:**
- Today / this week / all time minutes watched
- Recent reward sessions list

---

## 13. Guided Access Strategy

### What It Does
Locks iPad to one app. Disables Home button/gesture, notifications, hardware buttons.

### In-App Setup Guide
Shown during first launch and accessible from parent settings:

```
1. Settings → Accessibility → Guided Access → Toggle ON
2. Passcode Settings → Set Guided Access Passcode
   ⚠️ Use different code than EarnedRecess PIN
3. To START: Open EarnedRecess → Triple-click Side/Home button → Start
4. To STOP: Triple-click Side/Home button → Enter passcode → End
```

### Detection
```swift
UIAccessibility.isGuidedAccessEnabled  // checked in ParentTabView exit flow
```

---

## 14. File & Folder Structure

```
EarnedRecess.xcodeproj
EarnedRecess/
├── EarnedRecessApp.swift
├── AppState.swift
│
├── Core/
│   ├── Theme.swift
│   ├── Constants.swift
│   ├── AppEnums.swift                   // AppMode, LetterCase, TemplateStyle
│   ├── PhoneticLibrary.swift            // A-Z sounds
│   ├── WordAssociationLibrary.swift     // A-Z emoji + words
│   └── Extensions/
│       ├── Color+Theme.swift
│       ├── View+Helpers.swift
│       ├── Date+Formatting.swift
│       ├── Int+Timer.swift
│       └── Collection+Safe.swift
│
├── Data/
│   ├── CoreData/
│   │   ├── EarnedRecess.xcdatamodeld
│   │   └── CoreDataStack.swift
│   ├── Models/
│   │   ├── ChildProfile+Extensions.swift
│   │   ├── LetterSession+Extensions.swift   // includes Collection<LetterSession>.letters
│   │   ├── DrawingAttempt+Extensions.swift
│   │   ├── RewardSession+Extensions.swift
│   │   └── ParentSettings+Extensions.swift
│   └── Repositories/
│       ├── LetterRepository.swift
│       ├── SessionRepository.swift
│       └── SettingsRepository.swift
│
├── Services/
│   ├── KeychainService.swift
│   ├── StarMinutesService.swift
│   ├── ScoringService.swift
│   ├── CalibrationService.swift
│   ├── SpeechService.swift
│   ├── YouTubeKidsService.swift
│   └── GuidedAccessService.swift
│
├── DrawingEngine/
│   ├── CanvasViewTag.swift              // enum: template=999, alignment=998, arrows=997
│   ├── DrawingCanvasView.swift
│   ├── LetterTemplate.swift
│   ├── LetterTemplateLibrary.swift      // 52 letters, image+dotted caches
│   ├── StrokeAnalyzer.swift
│   ├── ProgressionEngine.swift
│   ├── StrokePathLibrary.swift          // ordered stroke sequences A-Z
│   └── TracingArrowsView.swift
│
├── TimerEngine/
│   └── RewardTimer.swift
│
├── Features/
│   ├── Launch/
│   │   ├── LaunchRouter.swift
│   │   └── FirstLaunchFlow/
│   │       ├── WelcomeView.swift
│   │       ├── PINSetupView.swift
│   │       ├── GuidedAccessInstructionsView.swift
│   │       ├── ChildNameEntryView.swift
│   │       ├── LetterSelectionView.swift
│   │       └── SetupCompleteView.swift
│   │
│   ├── Child/
│   │   ├── ChildHomeView.swift
│   │   ├── StarWalletView.swift
│   │   └── MascotView.swift
│   │
│   ├── Task/
│   │   ├── TaskGateView.swift
│   │   ├── DrawingSessionView.swift
│   │   ├── SingleAttemptView.swift
│   │   ├── AttemptScoreView.swift
│   │   ├── SessionCompleteView.swift
│   │   ├── WriteToWatchView.swift
│   │   └── LetterIntroSplashView.swift
│   │
│   ├── Reward/
│   │   ├── RewardPlayerView.swift
│   │   ├── VideoBrowserView.swift
│   │   ├── YouTubePlayerView.swift
│   │   ├── VideoThumbnailView.swift
│   │   └── TimerExpiredOverlayView.swift
│   │
│   └── Parent/
│       ├── PINEntryView.swift
│       ├── ParentTabView.swift
│       ├── Settings/
│       │   ├── ParentSettingsView.swift
│       │   ├── TaskSettingsSection.swift
│       │   ├── RewardSettingsSection.swift
│       │   ├── YouTubeSettingsSection.swift
│       │   ├── CalibrationSettingsSection.swift
│       │   └── AccountSettingsSection.swift
│       └── Dashboard/
│           ├── DashboardView.swift
│           ├── OverviewTab.swift
│           ├── LettersTab.swift
│           ├── HistoryTab.swift
│           ├── WatchTimeTab.swift
│           └── CalibrationBannerView.swift
│
└── Resources/
    ├── Assets.xcassets
    └── Secrets.swift                    // GITIGNORED — YouTube API key

EarnedRecessTests/
├── TestHelpers.swift
├── ScoringServiceTests.swift
├── StarMinutesServiceTests.swift
├── CalibrationServiceTests.swift
├── KeychainServiceTests.swift
├── AppEnumsTests.swift
├── ChildProfileTests.swift
├── RewardTimerTests.swift
├── PINLockoutTests.swift
├── PhaseAdvancementTests.swift
└── PracticedLettersTests.swift
```

---

## 15. Build & Deployment

### Prerequisites

- Mac with macOS 14+ Sonoma, Xcode 15+
- Apple Developer account (paid $99/yr — ✅ confirmed)
- iPad with Apple Pencil, iOS 16+
- GitHub: https://github.com/joshschnebly/earnedrecess-ios.git

### Build Process (Windows Dev → Mac Build)

```bash
# On Mac build machine:
cd ~/earnedrecess-ios && git pull

# New files must be added to Xcode project manually:
# File → Add Files to "EarnedRecess"... → select new .swift files
# Ensure they're added to the EarnedRecess target
```

### Add YouTube API Key (TODO)

```bash
# Create EarnedRecess/Resources/Secrets.swift (NOT in git):
enum Secrets {
    static let youTubeAPIKey = "YOUR_KEY_HERE"
}
# Then update the YoutubeAPIKey stub at bottom of YouTubeKidsService.swift:
# Replace: static let value: String = ""
# With:    static let value = Secrets.youTubeAPIKey
```

### Sideload to iPad

```
1. Open EarnedRecess.xcodeproj in Xcode
2. Plug iPad into Mac via USB
3. Select iPad as target
4. Product → Run (⌘R)
5. First time: iPad Settings → General → VPN & Device Management → Trust developer
```

---

## 16. Future Architecture Hooks

### 16.1 Pluggable Task System

```swift
protocol LearningTask {
    var taskId: String { get }
    var displayName: String { get }
    var estimatedDuration: TimeInterval { get }
    func present(on viewController: UIViewController) async -> TaskResult
    func calculateStarsEarned(result: TaskResult, settings: ParentSettings) -> Int
}
// V1: LetterDrawingTask
// V2: AppTimerTask, KhanAcademyTask, ReadingTask
```

### 16.2 Pluggable Reward System

```swift
protocol RewardContent {
    var rewardId: String { get }
    func launch(earnedMinutes: Int) async
    func getCurrentMinutesRemaining() -> Int
}
// V1: YouTubeKidsReward
// V2: ExternalAppReward (requires Family Controls entitlement)
```

### 16.3 Multiple Child Profiles

CoreData schema already supports multiple ChildProfile records.
V1: AppState.currentChild is always the single profile.
V2: Profile picker on launch.

### 16.4 Web Dashboard

.NET 8 Minimal API + Azure/AWS. iPad syncs via REST. Sign in with Apple.
Not in POC.

### 16.5 Family Controls

Replace Guided Access with FamilyControls/DeviceActivity/ManagedSettings.
Requires Apple entitlement — apply after POC ships with real child usage.

---

## 17. Backlog

### Ready to Build (V1.1)
| Feature | Notes |
|---|---|
| Streak tracking | Days in a row with ≥1 session |
| Achievement badges | First A, Perfect session, 7-day streak, etc. |
| Number writing (0–9) | Same drawing engine, new templates |
| Drawing gallery | Parent can review saved PKDrawing ink data |

### Requires Design / Assets
| Feature | Notes |
|---|---|
| App icon | Needed before TestFlight |
| Mascot artwork | Placeholder emoji in MascotView |
| Lottie animations | Celebration, stars flying, loading spinner |
| Sound effects | Short cheerful tones on pass/fail |

### V2 (Post-POC)
| Feature | Notes |
|---|---|
| Multiple child profiles | CoreData schema ready |
| Scheduled screen time | Time windows for earning/watching |
| Star multiplier days | Parent sets bonus star days |
| Savings goal | Child saves stars for a special event |
| Weekly parent email report | Requires backend |
| Cursive mode | New template set |
| Web dashboard | .NET 8 backend |
| External app rewards | Requires Apple Family Controls entitlement |
| iCloud sync | Multi-device |
| App Store submission | COPPA, privacy policy, age rating |

---

## Appendix: Known Channel IDs

| Channel | ID | Status |
|---|---|---|
| Bluey Official | UCbCmjCuTUZos6Inko4u57UQ | ✅ Verified |
| Peppa Pig | UCAOtE1V7Ots4twtDCWhpHYg | ✅ Verified |
| Paw Patrol | UCF2M_-q5oKF8cHk1KWo9gkA | ✅ Verified |
| Cocomelon | TBD | ⚠️ Find real ID at youtube.com/@Cocomelon |

To find a channel ID: go to the channel page → view page source → search for `"channelId"`.

---

*Document Version: 2.0*  
*Last Updated: April 21, 2026*  
*Status: POC Feature-Complete — pending YouTube API key + app icon before TestFlight*
