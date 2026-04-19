# EarnedRecess — iOS iPad App Design Document
### Version 1.0 | POC Build | For Claude AI-Assisted Development

---

## 0. Pre-Flight Checklist — Complete Before Session 1

Do not start coding until every item below is checked off.

| # | Task | Status | Notes |
|---|---|---|---|
| 1 | **Mac with Xcode 15+** | 🔄 MacinCloud | Sign up at macincloud.com when ready to code. Managed plan $29/mo. 24hr free trial available. |
| 2 | **Apple Developer Account** | ✅ Done | Paid $99/yr account confirmed |
| 3 | **iPad with Apple Pencil** | ⚠️ Phase 2 | Needed for drawing engine testing. Not required for Sessions 1-4. |
| 4 | **Google Cloud account** | ⏳ Later | Create when building YouTube feature (Session 11) |
| 5 | **YouTube Data API v3 key** | ⏳ Later | See steps below. Do when Session 11 begins. |
| 6 | **Create Secrets.swift** | ⏳ Later | Create same time as YouTube API key |
| 7 | **Bundle ID** | ✅ Done | `com.earnedrecess.app` — registered in Apple Developer portal |
| 8 | **Lottie package ready** | ✅ Done | Add via SPM in Session 1. URL: https://github.com/airbnb/lottie-spm.git |
| 9 | **Repo / version control** | ✅ Done | earnedrecess-ios on GitHub. Swift .gitignore + Secrets.swift excluded |
| 10 | **App name** | ✅ Done | "Earned Recess" reserved on App Store Connect |
| 11 | **Domains** | ✅ Done | EarnedRecess.com + EarnedRecess.app purchased |
| 12 | **Social handles** | ✅ Done | @earnedrecess on X, Instagram, TikTok |

---

### Step-by-Step: YouTube API Key

```
1. Go to console.cloud.google.com
2. Create new project → name it "EarnedRecess"
3. Left menu → APIs & Services → Library
4. Search "YouTube Data API v3" → Enable
5. Left menu → APIs & Services → Credentials
6. + Create Credentials → API Key
7. Click the key → Application restrictions → iOS apps
8. Add bundle ID: com.earnedrecess.app
9. Copy key → paste into Secrets.swift (see below)
```

### Step-by-Step: Secrets.swift Setup

```bash
# In your Xcode project root, create this file:
# EarnedRecess/Resources/Secrets.swift

# Contents:
enum Secrets {
    static let youTubeAPIKey = "PASTE_YOUR_KEY_HERE"
}

# Then in terminal from project root:
echo "EarnedRecess/Resources/Secrets.swift" >> .gitignore
```

### Step-by-Step: Add Lottie via Swift Package Manager

```
1. Open Xcode
2. File → Add Package Dependencies
3. Enter URL: https://github.com/airbnb/lottie-spm.git
4. Select version: Up to Next Major from 4.0.0
5. Add to target: EarnedRecess
6. Done — import Lottie in any Swift file
```

### Lottie Animation Files Needed

Download these free animations from lottiefiles.com before Session 1:
- **Celebration / confetti** → used on task pass screen
- **Stars flying** → used when Star Minutes are awarded
- **Loading spinner** → used while YouTube loads
- **Empty state** → used when no videos found

Save all `.json` files to `EarnedRecess/Resources/Animations/`

---

## 🧭 Document Purpose

This document is the single source of truth for building the EarnedRecess iPad app.
It is written to be handed directly to Claude (AI) in VS Code for code generation.
The developer is a senior .NET/web developer with 25 years experience.
All Swift/SwiftUI code will be AI-generated and reviewed by the developer.

---

## 📋 Table of Contents

1. [Product Overview](#1-product-overview)
2. [POC Scope & Constraints](#2-poc-scope--constraints)
3. [Technical Stack](#3-technical-stack)
4. [Architecture Overview](#4-architecture-overview)
5. [Module Specifications](#5-module-specifications)
6. [Data Models](#6-data-models)
7. [User Experience Flows](#7-user-experience-flows)
8. [Drawing Engine Specification](#8-drawing-engine-specification)
9. [Star Minutes System](#9-star-minutes-system)
10. [YouTube Kids Integration](#10-youtube-kids-integration)
11. [Parent Module](#11-parent-module)
12. [Parental Dashboard](#12-parental-dashboard)
13. [Guided Access Strategy](#13-guided-access-strategy)
14. [Future Architecture Hooks](#14-future-architecture-hooks)
15. [File & Folder Structure](#15-file--folder-structure)
16. [Build & Deployment](#16-build--deployment)
17. [Session Prompting Guide](#17-session-prompting-guide)

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
  → Scored for accuracy
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
- **Future-proof**: Architecture must support pluggable tasks and rewards in V2.
- **App Store ready someday**: COPPA-aware, no 3rd party analytics, on-device data only for V1.

---

## 2. POC Scope & Constraints

### In Scope for POC (V1)

| Feature | Description |
|---|---|
| Letter drawing task | Apple Pencil, uppercase A–Z + lowercase a–z |
| Tracing phase only | Semi-transparent letter shown, child traces over it |
| Stroke scoring | Overlap %, proportion, stroke count, smoothness |
| Star Minutes | Earned on task pass, spent watching YouTube Kids |
| YouTube Kids embed | WKWebView inside the app using YouTube Kids API |
| Timer engine | Counts down Star Minutes during reward time |
| Parent PIN gate | 4-digit PIN locks all settings |
| Basic settings | Timer duration, letter set, passing threshold |
| On-device dashboard | Session history, accuracy per letter, time watched |
| Single child profile | One child, one iPad |
| Guided Access support | Parent instructions provided in-app to enable it |

### Out of Scope for POC

- Family Controls framework (requires Apple entitlement — apply after POC)
- External reward apps (ABCmouse, Minecraft, etc.) — requires Family Controls
- Multiple child profiles
- Web companion dashboard (.NET backend)
- Push notifications
- App-based tasks (e.g., "do 10 min in ABCmouse")
- Numbers, shapes, sight words (future learning tasks)
- Guided/freehand drawing phases (tracing only for POC)
- iCloud sync
- Monetization / subscriptions

### POC Success Criteria

- A 5-year-old can complete the full loop without parent help
- Guided Access prevents escape from the app
- Letter scoring correctly identifies good vs poor attempts
- YouTube Kids plays and pauses correctly based on Star Minutes
- Parent can review session history and adjust settings

---

## 3. Technical Stack

| Layer | Technology | Notes |
|---|---|---|
| Language | Swift 5.9+ | AI-generated, developer reviews |
| UI Framework | SwiftUI | Declarative, modern |
| Drawing | PencilKit (PKCanvasView) | Native Apple Pencil support |
| Letter Recognition | Vision framework | On-device, no API calls needed |
| Video | WKWebView + YouTube Kids API | Embedded in-app |
| Data Persistence | CoreData | On-device, COPPA-safe |
| Keychain | SwiftUI KeychainAccess or Security framework | PIN storage |
| Animation | Lottie or SwiftUI animations | Celebration screens |
| Target Device | iPad (any model with Apple Pencil support) | |
| iOS Target | iOS 16.0+ | |
| Xcode | 15.0+ | |
| Apple Developer | Personal team or paid ($99/yr) | Paid required for long-term install |

---

## 4. Architecture Overview

```
EarnedRecess/
│
├── App Entry Point
│   └── Determines: show Parent Setup OR Child Experience
│
├── ParentModule/
│   ├── PINGate             ← 4-digit PIN entry/verification
│   ├── ParentSettings      ← All config behind PIN
│   └── ParentDashboard     ← Session history, scores, charts
│
├── ChildModule/
│   ├── ChildHome           ← Main screen child sees
│   ├── TaskGate            ← "Draw your letters to earn stars!"
│   ├── RewardPlayer        ← YouTube Kids embedded player
│   └── StarWallet          ← Visual star minutes balance
│
├── DrawingEngine/
│   ├── DrawingCanvas       ← PKCanvasView SwiftUI wrapper
│   ├── LetterTemplate      ← Reference paths for all letters
│   ├── StrokeAnalyzer      ← Scoring logic
│   └── ProgressionEngine   ← Phase management per letter
│
├── TimerEngine/
│   ├── RewardTimer         ← Countdown during YouTube time
│   └── EarnedRecessr           ← Optional: how long task takes
│
├── DataLayer/
│   ├── CoreDataStack       ← Setup and context management
│   ├── Models (CoreData)
│   │   ├── ChildProfile    ← Name, current phase per letter
│   │   ├── LetterSession   ← Each time child practices a letter
│   │   ├── DrawingAttempt  ← Individual letter draw attempt + score
│   │   └── RewardSession   ← YouTube watch time records
│   └── Repositories
│       ├── LetterRepository
│       └── SessionRepository
│
├── Services/
│   ├── YouTubeKidsService  ← API calls, search, filtering
│   ├── ScoringService      ← Wraps StrokeAnalyzer with business logic
│   └── StarMinutesService  ← Balance management
│
└── Shared/
    ├── AppState            ← ObservableObject, app-wide state
    ├── Theme               ← Colors, fonts, spacing constants
    └── Extensions          ← Swift/SwiftUI helpers
```

---

## 5. Module Specifications

### 5.1 App Entry Point

On launch, the app checks:

```swift
// Pseudocode
if firstLaunch {
    show ParentSetupFlow  // walks parent through PIN setup + Guided Access instructions
} else if parentSessionActive {
    show ParentModule
} else {
    show ChildModule
}
```

**First Launch Flow:**
1. Welcome screen with EarnedRecess branding
2. "Set up your parental PIN" → 4-digit PIN entry + confirmation
3. "Set up Guided Access" → step-by-step instructions screen with screenshots
4. "Add your child's name" → text field
5. "Choose starting letters" → default: A only for POC, expandable
6. "You're ready!" → exit to Child Home

---

### 5.2 Parent PIN Gate

- 4-digit numeric PIN
- Stored in iOS Keychain (never CoreData, never UserDefaults)
- 3 wrong attempts → 30 second lockout (show countdown)
- PIN entry via custom large-button numpad (not iOS keyboard)
- Parent access triggered by: triple-tapping a hidden corner of child home screen

```swift
// PIN entry component
struct PINEntryView: View {
    // Custom numpad, 4 digit dots, backspace
    // On success: present ParentTabView
    // On failure: shake animation + attempt counter
}
```

---

### 5.3 Child Home Screen

This is what the child sees when they open the app.

**Layout:**
```
┌─────────────────────────────────────┐
│  ⭐ 45 Star Minutes                  │  ← Star wallet (top bar)
│                                     │
│        [Animated character]         │  ← Friendly mascot
│                                     │
│   "You have 45 star minutes!"       │
│                                     │
│  ┌─────────────┐  ┌──────────────┐  │
│  │  🎨 DRAW   │  │  📺 WATCH   │  │
│  │  LETTERS   │  │  YOUTUBE    │  │
│  │            │  │  (if stars) │  │
│  └─────────────┘  └──────────────┘  │
└─────────────────────────────────────┘
```

**Rules:**
- WATCH button disabled (grayed out) if Star Minutes balance = 0
- WATCH button active if Star Minutes > 0
- DRAW LETTERS always available
- No text navigation required — icons + simple words

---

## 6. Data Models

### CoreData Entities

```swift
// ChildProfile
entity ChildProfile {
    id: UUID
    name: String
    createdAt: Date
    currentPhasePerLetter: [String: Int]  // "A": 1, "b": 2, etc. (stored as transformable)
    starMinutesBalance: Int32             // current balance in minutes
    totalStarMinutesEarned: Int32
    totalStarMinutesSpent: Int32
}

// LetterSession
entity LetterSession {
    id: UUID
    letter: String                        // "A", "b", etc.
    sessionDate: Date
    phase: Int16                          // 1=tracing, 2=guided, 3=freehand
    attemptsRequired: Int16               // how many draws required (e.g. 10)
    attemptsCompleted: Int16
    averageScore: Double                  // 0.0 to 1.0
    passed: Bool
    starMinutesEarned: Int32
    duration: Double                      // seconds to complete session
    relationship: child (ChildProfile)
    relationship: attempts (DrawingAttempt[])
}

// DrawingAttempt
entity DrawingAttempt {
    id: UUID
    attemptNumber: Int16                  // 1-10
    letter: String
    overlapScore: Double                  // stroke coverage %
    proportionScore: Double               // height/width ratio match
    strokeCountScore: Double              // correct number of strokes
    smoothnessScore: Double               // jitter measurement
    compositeScore: Double                // weighted final score
    passed: Bool
    inkData: Data?                        // optional: store PKDrawing for review
    timestamp: Date
    relationship: session (LetterSession)
}

// RewardSession
entity RewardSession {
    id: UUID
    startTime: Date
    endTime: Date?
    minutesWatched: Int32
    minutesEarned: Int32                  // how many stars used
    videoTitle: String?
    videoId: String?
    relationship: child (ChildProfile)
}

// ParentSettings (singleton — one record)
entity ParentSettings {
    id: UUID
    timerDurationMinutes: Int32           // how many star minutes earned per task (default: 20)
    taskIntervalMinutes: Int32            // NOT USED IN V1 (reserved)
    passingThreshold: Double              // 0.0-1.0, default 0.60
    autoProgressionEnabled: Bool          // auto-advance phases
    progressionThreshold: Double          // rolling avg needed to advance phase
    activeLetters: String                 // comma-separated, e.g. "A,B,C"
    maxDailyMinutes: Int32                // daily cap, default 120
    bedtimeHour: Int32                    // hour after which no more rewards (24hr)
    requireAllLettersBeforeReward: Bool   // must draw ALL active letters, not just one
}
```

---

## 7. User Experience Flows

### 7.1 First Launch (Parent)

```
Launch → FirstLaunchWelcome
  → ParentPINSetup (enter PIN × 2)
  → GuidedAccessInstructions (with screenshots)
  → ChildNameEntry
  → LetterSelection (default: just "A" to start)
  → StarMinutesConfig (default: draw 10 letters = earn 20 min)
  → SetupComplete → ChildHome
```

### 7.2 Daily Child Flow

```
ChildHome
  ├── [TAP: DRAW LETTERS]
  │     → TaskGate (shows letter, instructions)
  │     → DrawingCanvas (draw 10 letters)
  │     → ScoreDisplay (after each letter)
  │     → SessionComplete (total score + stars earned)
  │     → StarWallet updated
  │     → ChildHome
  │
  └── [TAP: WATCH YOUTUBE] (only if stars > 0)
        → RewardPlayer launches
        → YouTube Kids browsable inside app
        → Star Minutes countdown shown (top bar)
        → 0 stars → YouTube pauses
        → "Time to draw more letters!" overlay
        → [TAP: Draw More] → TaskGate
        → [TAP: Done for now] → ChildHome
```

### 7.3 Parent Access Flow

```
ChildHome
  → [Triple-tap top-right corner] (hidden trigger)
  → PINEntry
  → [SUCCESS] ParentTabView
      ├── Tab: Dashboard (charts, history)
      ├── Tab: Settings (timer, letters, thresholds)
      └── Tab: Exit to Child
```

### 7.4 Task Gate Flow (Detail)

```
TaskGate
  Shows:
    - Letter to practice (large, animated)
    - How many to draw (e.g., "Draw 10 uppercase A's")
    - Stars to earn (e.g., "Earn ⭐ 20 Star Minutes!")
    - [START] button

  → DrawingSession
      For each attempt (1 of 10):
        - Show letter template (semi-transparent)
        - Child draws over it
        - [DONE] button or auto-detect stroke completion
        - Score calculated instantly
        - Feedback shown: ⭐⭐⭐ (1-3 stars per letter)
        - Canvas clears for next attempt

  → SessionComplete
      - Show total score (avg of 10 attempts)
      - Show stars earned
      - Celebration animation if passed
      - If failed: encouragement + option to try again
      - [WATCH YOUTUBE] button (if passed)
      - [TRY AGAIN] button
      - [GO HOME] button
```

---

## 8. Drawing Engine Specification

### 8.1 Overview

The drawing engine is the core technical differentiator of EarnedRecess.
It uses PencilKit to capture strokes and scores them against reference letter paths.

### 8.2 PencilKit Canvas Setup

```swift
struct DrawingCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var letterTemplate: UIImage        // reference letter as background
    var isEnabled: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput      // Apple Pencil + finger
        canvas.backgroundColor = .white
        canvas.tool = PKInkingTool(.pen, color: .systemBlue, width: 8)
        // Overlay letter template as background image
        // Do NOT add template to canvas drawing — it's a separate UIImageView behind canvas
        return canvas
    }
}
```

### 8.3 Letter Template System

Each letter has:
1. **Visual template**: PNG image of the letter, semi-transparent (opacity: 0.25)
2. **Reference path**: CGPath representing the ideal letter strokes for scoring
3. **Stroke count**: Expected number of strokes (e.g., "A" = 3)
4. **Bounding box**: Normalized bounding box for proportion scoring
5. **Key points**: Array of critical points the stroke must pass through

```swift
struct LetterTemplate {
    let letter: String                   // "A"
    let isUppercase: Bool
    let templateImage: UIImage           // semi-transparent overlay
    let referencePath: CGPath            // for overlap scoring
    let expectedStrokeCount: Int         // A=3, B=2, C=1, etc.
    let keyPoints: [CGPoint]             // must-hit points (normalized 0-1)
    let aspectRatio: CGFloat             // expected width/height ratio
}
```

**Letter Stroke Counts Reference (A-Z):**

| Letter | Strokes | Notes |
|---|---|---|
| A | 3 | Left leg, right leg, crossbar |
| B | 2 | Vertical stroke, two bumps |
| C | 1 | Single arc |
| D | 2 | Vertical, curve |
| E | 4 | Vertical + 3 horizontal |
| F | 3 | Vertical + 2 horizontal |
| G | 1 | Arc + inward |
| H | 3 | Two verticals + crossbar |
| I | 1 or 3 | Vertical (+ serifs optional) |
| J | 1 | Hook |
| K | 3 | Vertical + two diagonals |
| L | 2 | Vertical + horizontal |
| M | 4 | Two verticals + two diagonals |
| N | 3 | Two verticals + diagonal |
| O | 1 | Oval |
| P | 2 | Vertical + bump |
| Q | 2 | Oval + tail |
| R | 3 | Vertical + bump + leg |
| S | 1 | S-curve |
| T | 2 | Vertical + horizontal |
| U | 1 | U-shape |
| V | 2 | Two diagonals |
| W | 4 | Four diagonals |
| X | 2 | Two diagonals |
| Y | 3 | Two diagonals + vertical |
| Z | 3 | Top horizontal + diagonal + bottom horizontal |

### 8.4 Scoring Algorithm

```swift
struct StrokeAnalyzer {

    struct ScoreWeights {
        static let overlapCoverage: Double = 0.40    // Did they hit the letter's path?
        static let proportion: Double = 0.20          // Correct height/width ratio?
        static let strokeCount: Double = 0.20         // Right number of strokes?
        static let smoothness: Double = 0.20          // Non-jagged lines?
    }

    func score(drawing: PKDrawing, template: LetterTemplate, canvasSize: CGSize) -> DrawingScore {

        let overlapScore = calculateOverlap(drawing, template, canvasSize)
        let proportionScore = calculateProportion(drawing, template)
        let strokeCountScore = calculateStrokeCount(drawing, template)
        let smoothnessScore = calculateSmoothness(drawing)

        let composite = (overlapScore * ScoreWeights.overlapCoverage) +
                        (proportionScore * ScoreWeights.proportion) +
                        (strokeCountScore * ScoreWeights.strokeCount) +
                        (smoothnessScore * ScoreWeights.smoothness)

        return DrawingScore(
            overlapScore: overlapScore,
            proportionScore: proportionScore,
            strokeCountScore: strokeCountScore,
            smoothnessScore: smoothnessScore,
            compositeScore: composite
        )
    }

    // OVERLAP: Rasterize both drawing and reference path.
    // Count pixels that overlap vs total reference pixels.
    private func calculateOverlap(_ drawing: PKDrawing, _ template: LetterTemplate, _ size: CGSize) -> Double {
        // 1. Render drawing to bitmap
        // 2. Render reference path to bitmap
        // 3. Count overlapping pixels / total reference pixels
        // Returns 0.0 - 1.0
    }

    // PROPORTION: Compare bounding box of drawn strokes to expected aspect ratio
    private func calculateProportion(_ drawing: PKDrawing, _ template: LetterTemplate) -> Double {
        // Get bounding rect of PKDrawing strokes
        // Compare to template.aspectRatio
        // Score = 1.0 - abs(drawnRatio - expectedRatio) clamped to 0-1
    }

    // STROKE COUNT: Compare actual stroke count to expected
    private func calculateStrokeCount(_ drawing: PKDrawing, _ template: LetterTemplate) -> Double {
        let actualCount = drawing.strokes.count
        let expectedCount = template.expectedStrokeCount
        if actualCount == expectedCount { return 1.0 }
        let diff = abs(actualCount - expectedCount)
        return max(0.0, 1.0 - (Double(diff) * 0.33))  // -33% per extra/missing stroke
    }

    // SMOOTHNESS: Measure variance in stroke curvature
    private func calculateSmoothness(_ drawing: PKDrawing) -> Double {
        // For each stroke, measure point-to-point angle variance
        // High variance = jagged = low score
        // Low variance = smooth = high score
    }
}
```

### 8.5 Scoring Thresholds & Progression

```swift
enum DrawingPhase: Int {
    case tracing = 1        // Semi-transparent letter shown underneath
    case guided = 2         // Dotted outline only (V2)
    case freehand = 3       // No visual aid (V2)
}

// POC uses Phase 1 (tracing) only.
// Thresholds are stored in ParentSettings and adjustable.

struct ProgressionEngine {
    // Rolling average of last 10 sessions per letter
    // If rollingAverage > progressionThreshold → auto-advance phase
    // progressionThreshold default: 0.85 (85%)

    func shouldAdvancePhase(letter: String, recentScores: [Double], threshold: Double) -> Bool {
        guard recentScores.count >= 5 else { return false }  // need at least 5 sessions
        let recent = Array(recentScores.suffix(10))
        let avg = recent.reduce(0, +) / Double(recent.count)
        return avg >= threshold
    }
}
```

### 8.6 Session Rules

- Child draws the required number of letters (default: 10 per session)
- Each letter scored individually (1-3 stars displayed: 1=poor, 2=ok, 3=great)
- Session passes if: average composite score ≥ passingThreshold (default: 0.60)
- Failed session: child can retry (encouragement shown, not punishment language)
- Canvas auto-clears after each attempt
- [DONE] button available after minimum 2 strokes detected (prevents empty submissions)

---

## 9. Star Minutes System

### 9.1 Earning

```swift
struct StarMinutesService {

    // Called when a task session passes
    func awardStarMinutes(session: LetterSession, settings: ParentSettings) -> Int {
        // Base award from settings (default: 20 minutes per session)
        var award = settings.timerDurationMinutes

        // Quality multiplier (optional, enable in settings)
        // 60-74% avg score → 1x (base)
        // 75-89% avg score → 1.25x
        // 90%+ avg score   → 1.5x
        if settings.qualityMultiplierEnabled {
            award = Int(Double(award) * qualityMultiplier(score: session.averageScore))
        }

        // Daily cap enforcement
        let todaySpent = getTodayTotalMinutes(type: .earned)
        let remaining = settings.maxDailyMinutes - todaySpent
        return min(award, max(0, remaining))
    }
}
```

### 9.2 Spending

- Star Minutes spend 1:1 as real minutes watching YouTube Kids
- Timer ticks down in real-time (visible in top bar during reward)
- At 0: YouTube pauses, overlay appears
- No rollover in V1 — unused minutes expire at configured bedtime hour
- Balance stored in CoreData on ChildProfile

### 9.3 Wallet UI (Child-Facing)

```
Top bar during reward:
┌─────────────────────────────────────┐
│  ⭐ 18:32 remaining   [◀ STOP]     │
└─────────────────────────────────────┘

Star wallet on home screen:
┌─────────────────────────────────────┐
│         ⭐ ⭐ ⭐ ⭐ ⭐              │
│      You have 45 Star Minutes!      │
│     That's 45 minutes of YouTube!   │
└─────────────────────────────────────┘
```

### 9.4 Timer Engine

```swift
class RewardTimer: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var isRunning: Bool = false
    private var timer: Timer?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    func start(minutes: Int) { ... }
    func pause() { ... }
    func resume() { ... }
    func stop() { ... }   // called when time expires → triggers gate

    // NOTE: Background timer — use UIBackgroundTaskIdentifier to keep
    // timer alive if app briefly backgrounds (even though Guided Access
    // prevents full backgrounding, handle edge cases)
}
```

---

## 10. YouTube Kids Integration

### 10.1 API Setup

- **API**: YouTube Data API v3
- **Key**: Stored in app (for V1/POC — not in source control)
- **Search filters**:
  - `safeSearch=strict`
  - `videoCategoryId=1` (Film & Animation)
  - `type=video`
  - Optional: channel whitelist (parent-configurable in settings)
- **Quota**: 10,000 units/day free. Search = 100 units. Sufficient for personal use.

```swift
struct YouTubeKidsService {

    func searchCartoons(query: String = "cartoons for kids",
                        channelId: String? = nil) async -> [YouTubeVideo] {
        // GET https://www.googleapis.com/youtube/v3/search
        // params: part=snippet, safeSearch=strict, videoCategoryId=1,
        //         type=video, maxResults=20, key=API_KEY
    }

    func featuredChannels() -> [String] {
        // Curated whitelist of safe channels
        // Bluey, Peppa Pig, Cocomelon, Paw Patrol official channels
        // Parent can add/remove in settings
        return ["UCbCmjCuTUZos6Inko4u57UQ",   // Bluey
                "UCAOtE1V7Ots4twtDCWhpHYg",   // Peppa Pig
                // etc.
        ]
    }
}
```

### 10.2 Video Player

```swift
struct YouTubePlayerView: UIViewRepresentable {
    let videoId: String
    @Binding var isPlaying: Bool

    // WKWebView loading YouTube iframe
    // HTML template with YouTube embed:
    // <iframe src="https://www.youtube.com/embed/{videoId}?autoplay=1&rel=0&modestbranding=1">

    // Controls exposed to SwiftUI:
    // pause() → inject JS: player.pauseVideo()
    // resume() → inject JS: player.playVideo()
}
```

### 10.3 Content Browser (Child-Facing)

```
┌─────────────────────────────────────┐
│  ⭐ 18:32    [🔍 Search]  [🏠]     │
├─────────────────────────────────────┤
│  [Bluey]  [Peppa] [Paw Patrol]     │  ← channel shortcuts
├─────────────────────────────────────┤
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐      │
│  │    │ │    │ │    │ │    │      │  ← video thumbnails
│  │    │ │    │ │    │ │    │      │
│  └────┘ └────┘ └────┘ └────┘      │
│  Title1  Title2 Title3 Title4      │
│                                     │
│  ┌────┐ ┌────┐ ┌────┐ ┌────┐      │
│  │    │ │    │ │    │ │    │      │
│  └────┘ └────┘ └────┘ └────┘      │
└─────────────────────────────────────┘
```

- Tap thumbnail → full screen video player
- Star Minutes timer visible at all times
- Timer reaches 0 → video pauses → full-screen gate overlay appears
- Search limited to safe terms (or disabled for age 5, parent preference)

---

## 11. Parent Module

### 11.1 Settings Screen

```swift
struct ParentSettingsView: View {
    // Sections:
    // 1. TASK SETTINGS
    //    - Letters to practice (multi-select A-Z, upper/lower toggle)
    //    - Attempts per session (stepper: 5-20, default 10)
    //    - Passing threshold (slider: 40%-90%, default 60%)
    //    - Quality multiplier on/off
    //    - Auto-progression on/off
    //    - Progression threshold (slider: 70%-95%, default 85%)

    // 2. REWARD SETTINGS
    //    - Star minutes earned per session (stepper: 5-60, default 20)
    //    - Daily maximum minutes (stepper: 30-240, default 120)
    //    - Bedtime hour (time picker, default 8:00 PM)
    //    - Reset daily balance now (button)

    // 3. YOUTUBE SETTINGS
    //    - Channel whitelist (add/remove channel IDs)
    //    - Allow search (toggle, default off for age 5)
    //    - SafeSearch level (strict/moderate, default strict)

    // 4. ACCOUNT
    //    - Child's name
    //    - Change PIN
    //    - Reset all progress (destructive, confirm dialog)
    //    - Export data (CSV of sessions)

    // 5. GUIDED ACCESS
    //    - Instructions reminder (button → shows setup guide)
    //    - Check status (detect if Guided Access is active)
}
```

### 11.2 PIN Management

```swift
struct KeychainService {
    static let pinKey = "com.tasktime.parentpin"

    func savePIN(_ pin: String) throws { ... }      // bcrypt hash stored
    func verifyPIN(_ pin: String) -> Bool { ... }   // compare hash
    func pinExists() -> Bool { ... }
    func changePIN(current: String, new: String) throws { ... }
}
```

---

## 12. Parental Dashboard

### 12.1 On-Device Dashboard (V1)

Available behind PIN gate. Shows:

**Overview Tab:**
- Today's stats: letters practiced, star minutes earned, star minutes spent
- Streak counter: days in a row with at least one session
- Current phase per active letter (tracing/guided/freehand badges)

**Letters Tab:**
- Grid of all active letters
- Per letter: average score (last 10 sessions), current phase, trend arrow (↑↓→)
- Tap letter → detail view with score history chart

**History Tab:**
- Session list (date, letters practiced, avg score, stars earned)
- Filter by date range
- Tap session → attempt-by-attempt breakdown

**Watch Time Tab:**
- Total minutes watched today / this week / all time
- Videos watched (title, duration)
- Stars earned vs stars spent chart

### 12.2 Charts

Use Swift Charts (iOS 16+, no external dependency):

```swift
import Charts

// Score trend chart per letter
Chart(scores) { score in
    LineMark(x: .value("Session", score.date),
             y: .value("Score", score.compositeScore))
    .foregroundStyle(.blue)
}

// Star minutes earned vs spent (bar chart)
Chart(weekData) { day in
    BarMark(x: .value("Day", day.label),
            y: .value("Minutes", day.earned))
    .foregroundStyle(.yellow)
    BarMark(x: .value("Day", day.label),
            y: .value("Minutes", day.spent))
    .foregroundStyle(.orange)
}
```

### 12.3 Future: Web Dashboard (.NET)

**Not in POC.** Architecture placeholder:

- .NET 8 Minimal API backend
- Hosted on Azure or AWS
- iPad syncs via REST API (iCloud as transport or direct API)
- Auth: Sign in with Apple (required for App Store kids apps)
- Parent views dashboard from any browser
- Push notifications via APNs (FCM alternative)

---

## 13. Guided Access Strategy

### 13.1 What It Does

Guided Access is a native iOS accessibility feature:
- Locks iPad to a single app
- Disables Home button / gesture
- Disables notifications
- Disables hardware buttons (optional)
- Requires passcode (separate from screen lock) to exit

### 13.2 Setup Instructions (Shown In-App to Parent)

The app will include a visual step-by-step guide:

```
Step 1: Open Settings app
Step 2: Tap Accessibility
Step 3: Tap Guided Access
Step 4: Toggle "Guided Access" ON
Step 5: Tap Passcode Settings
Step 6: Tap Set Guided Access Passcode
Step 7: Enter a passcode (different from your device PIN)
        ⚠️ Do NOT use the same code as your EarnedRecess PIN

To START Guided Access when giving iPad to child:
  1. Open EarnedRecess
  2. Triple-click the Side Button (or Home button)
  3. Tap "Start"

To STOP Guided Access (when you want the iPad back):
  1. Triple-click the Side Button (or Home button)
  2. Enter your Guided Access passcode
  3. Tap "End"
```

### 13.3 In-App Detection

```swift
// Detect if Guided Access is currently active
UIAccessibility.isGuidedAccessEnabled  // Bool

// Show status in parent settings
// Show reminder if Guided Access is OFF when parent exits to child mode
```

### 13.4 Future: Programmatic Guided Access

When Apple Family Controls entitlement is obtained (apply after POC):

```swift
// Replace Guided Access with Family Controls
// This enables external apps (ABCmouse, etc.) as rewards
import FamilyControls
import DeviceActivity
import ManagedSettings

// Application for entitlement submitted to Apple with working app
// Estimated approval: 2-4 weeks after submission
// Submit when POC is proven with real child usage
```

---

## 14. Future Architecture Hooks

These are **not built in POC** but the architecture must not prevent them.

### 14.1 Pluggable Task System

```swift
// Protocol — every task type must conform to this
protocol LearningTask {
    var taskId: String { get }
    var displayName: String { get }
    var estimatedDuration: TimeInterval { get }
    func present(on viewController: UIViewController) async -> TaskResult
    func calculateStarsEarned(result: TaskResult, settings: ParentSettings) -> Int
}

// V1 implementation
struct LetterDrawingTask: LearningTask { ... }

// V2 implementations (not built yet)
struct AppTimerTask: LearningTask { ... }           // "Do 10 min in ABCmouse"
struct KhanAcademyTask: LearningTask { ... }        // "Complete 1 lesson"
struct ReadingTask: LearningTask { ... }            // "Read for 15 min in Epic!"
```

### 14.2 Pluggable Reward System

```swift
protocol RewardContent {
    var rewardId: String { get }
    var displayName: String { get }
    var iconName: String { get }
    func launch(earnedMinutes: Int) async
    func getCurrentMinutesRemaining() -> Int
}

// V1 implementation
struct YouTubeKidsReward: RewardContent { ... }

// V2 implementations (requires Family Controls)
struct ExternalAppReward: RewardContent {
    let bundleId: String    // com.disney.disneyplus, etc.
    // Uses Family Controls to unlock/relock app
}
```

### 14.3 Multiple Child Profiles

```swift
// V1: AppState.currentChild is always the only ChildProfile
// V2: Profile picker on launch, each child has own settings + progress
// CoreData schema already supports multiple ChildProfile records
```

---

## 15. File & Folder Structure

```
EarnedRecess.xcodeproj
EarnedRecess/
├── EarnedRecessApp.swift                    // App entry point, @main
├── AppState.swift                       // Global ObservableObject
│
├── Core/
│   ├── Theme.swift                      // Colors, fonts, spacing
│   ├── Extensions/
│   │   ├── Color+Theme.swift
│   │   ├── View+Helpers.swift
│   │   └── Date+Formatting.swift
│   └── Constants.swift                  // API keys (gitignored), config
│
├── Data/
│   ├── CoreData/
│   │   ├── EarnedRecess.xcdatamodeld        // CoreData model file
│   │   └── CoreDataStack.swift          // PersistenceController
│   ├── Models/                          // NSManagedObject subclasses
│   │   ├── ChildProfile+Extensions.swift
│   │   ├── LetterSession+Extensions.swift
│   │   ├── DrawingAttempt+Extensions.swift
│   │   ├── RewardSession+Extensions.swift
│   │   └── ParentSettings+Extensions.swift
│   └── Repositories/
│       ├── LetterRepository.swift
│       ├── SessionRepository.swift
│       └── SettingsRepository.swift
│
├── Services/
│   ├── KeychainService.swift            // PIN storage
│   ├── StarMinutesService.swift         // Balance management
│   ├── YouTubeKidsService.swift         // API calls
│   ├── ScoringService.swift             // Business logic wrapper
│   └── GuidedAccessService.swift        // Detection + instructions
│
├── DrawingEngine/
│   ├── DrawingCanvasView.swift          // UIViewRepresentable for PKCanvasView
│   ├── LetterTemplate.swift             // Template model + factory
│   ├── LetterTemplateLibrary.swift      // All 52 letter templates (A-Z, a-z)
│   ├── StrokeAnalyzer.swift             // Scoring algorithm
│   └── ProgressionEngine.swift          // Phase advancement logic
│
├── TimerEngine/
│   └── RewardTimer.swift                // Countdown timer ObservableObject
│
├── Features/
│   ├── Launch/
│   │   ├── LaunchRouter.swift           // First launch vs returning
│   │   └── FirstLaunchFlow/
│   │       ├── WelcomeView.swift
│   │       ├── PINSetupView.swift
│   │       ├── GuidedAccessInstructionsView.swift
│   │       ├── ChildNameEntryView.swift
│   │       ├── LetterSelectionView.swift
│   │       └── SetupCompleteView.swift
│   │
│   ├── Child/
│   │   ├── ChildHomeView.swift          // Main child screen
│   │   ├── StarWalletView.swift         // Star balance display
│   │   └── MascotView.swift             // Animated character
│   │
│   ├── Task/
│   │   ├── TaskGateView.swift           // "Draw letters to earn stars"
│   │   ├── DrawingSessionView.swift     // Manages sequence of 10 attempts
│   │   ├── SingleAttemptView.swift      // One letter draw + score
│   │   ├── AttemptScoreView.swift       // Star rating after each attempt
│   │   └── SessionCompleteView.swift    // Final results + celebration
│   │
│   ├── Reward/
│   │   ├── RewardPlayerView.swift       // YouTube browser + player wrapper
│   │   ├── YouTubePlayerView.swift      // WKWebView player
│   │   ├── VideoBrowserView.swift       // Thumbnail grid
│   │   ├── VideoThumbnailView.swift     // Individual thumbnail card
│   │   └── TimerExpiredOverlayView.swift // "Time to draw!" gate overlay
│   │
│   └── Parent/
│       ├── PINEntryView.swift           // PIN input (shared component)
│       ├── ParentTabView.swift          // Tab container for parent area
│       ├── Settings/
│       │   ├── ParentSettingsView.swift
│       │   ├── TaskSettingsSection.swift
│       │   ├── RewardSettingsSection.swift
│       │   ├── YouTubeSettingsSection.swift
│       │   └── AccountSettingsSection.swift
│       └── Dashboard/
│           ├── DashboardView.swift
│           ├── OverviewTab.swift
│           ├── LettersTab.swift
│           ├── HistoryTab.swift
│           └── WatchTimeTab.swift
│
└── Resources/
    ├── Assets.xcassets                  // Images, colors, app icon
    ├── LetterTemplates/                 // PNG images for A-Z, a-z
    ├── Animations/                      // Lottie JSON files (celebration etc.)
    └── Localizable.strings              // English only for V1
```

---

## 16. Build & Deployment

### Prerequisites

- Mac with macOS 14+ (Sonoma)
- Xcode 15.0+
- Apple Developer account (✅ confirmed — paid $99/yr)
- iPad with Apple Pencil support running iOS 16+
- USB cable for first install (after that, WiFi works)

### No App Store — Sideload Process

```bash
# 1. Open EarnedRecess.xcodeproj in Xcode
# 2. Plug iPad into Mac via USB
# 3. Select iPad as target device in Xcode toolbar
# 4. Product → Run (or ⌘R)
# 5. First time: Settings → General → VPN & Device Management → Trust developer
# 6. App installs and launches on iPad
```

### Configuration (Pre-Build)

Create `EarnedRecess/Resources/Secrets.swift` (add to .gitignore):

```swift
// Secrets.swift — DO NOT COMMIT
enum Secrets {
    static let youTubeAPIKey = "YOUR_API_KEY_HERE"
}
```

Get YouTube Data API v3 key:
1. Go to console.cloud.google.com
2. Create project "EarnedRecess"
3. Enable "YouTube Data API v3"
4. Credentials → Create API Key
5. Restrict to iOS app (bundle ID: com.earnedrecess.app)

---

## 17. Session Prompting Guide

This section tells you how to work with Claude in VS Code most efficiently.

### Starting a New Session

Always begin with:

```
I am building EarnedRecess, an iPad app described in the design document.
Here is the relevant context for this session: [paste specific section]
Today I want to build: [specific feature]
Please generate complete, working Swift/SwiftUI code.
```

### Recommended Build Order

Work in this sequence for fastest POC:

```
Session 1:  Xcode project setup + folder structure + CoreData model
Session 2:  Theme.swift + AppState.swift + LaunchRouter
Session 3:  First launch flow (PIN setup + child name)
Session 4:  ChildHomeView + StarWalletView (static, no real data)
Session 5:  DrawingCanvasView + LetterTemplate for letter "A" only
Session 6:  StrokeAnalyzer (overlap + proportion + stroke count)
Session 7:  SingleAttemptView + AttemptScoreView
Session 8:  DrawingSessionView (manages 10 attempts)
Session 9:  SessionCompleteView + StarMinutesService (award stars)
Session 10: RewardTimer + connect stars to timer
Session 11: YouTubeKidsService + VideoBrowserView
Session 12: YouTubePlayerView + timer integration
Session 13: TimerExpiredOverlayView + gate logic
Session 14: PINEntryView + parent access hidden trigger
Session 15: ParentSettingsView (all sections)
Session 16: Dashboard (OverviewTab + LettersTab)
Session 17: Dashboard (HistoryTab + WatchTimeTab)
Session 18: GuidedAccessInstructionsView
Session 19: Full A-Z letter templates
Session 20: Polish, edge cases, error handling
```

### Providing Feedback to Claude

```
When code doesn't compile:
"This line throws error: [exact error]. Here is the surrounding code: [paste]. Fix it."

When behavior is wrong:
"The score always returns 0.0 even when the letter is drawn correctly.
 The scoring function receives: [paste data]. Expected: 0.6+. Fix it."

When requesting iteration:
"The ChildHomeView works. Now add the animation where the star count
increases when new minutes are awarded. Use a spring animation."
```

### Key Constraints to Remind Claude

Include these in prompts when relevant:

```
- iOS 16+ target
- iPad only (no iPhone layout needed)
- CoreData for all persistence (no UserDefaults for user data)
- No third-party packages in V1 except possibly Lottie for animations
- All data stays on-device (no network calls except YouTube API)
- Child UI: age 5, large touch targets (min 60x60pt), no small text
- Parent UI: standard iOS design patterns are fine
- No hardcoded API keys in source (use Secrets.swift which is gitignored)
```

---

## Appendix A: Letter Template Generation Strategy

For POC, letter templates can be generated programmatically using Core Graphics:

```swift
// Each letter template generated as:
// 1. Draw letter using system font (large, e.g. 300pt) to CGContext
// 2. Apply 25% opacity for overlay
// 3. Extract CGPath from glyph for scoring reference
// 4. Cache as UIImage + CGPath pair

// Alternative for higher quality:
// Design each letter in Sketch/Figma as SVG
// Import as PDF asset in Xcode (vector, scales perfectly)
// Extract path from PDF for scoring
```

---

## Appendix B: Celebration Animation Ideas

After task passes:
- Stars fly across the screen
- Confetti burst
- Mascot dances
- "Great job! You earned 20 Star Minutes!" with counting animation
- Sound effect (short, cheerful — include in assets)

Implementation options:
- Lottie (JSON animations from LottieFiles.com — many free options)
- Pure SwiftUI particle animation
- SpriteKit (more powerful but heavier)

Recommendation: ✅ **Lottie — confirmed for POC.** Add via Swift Package Manager (see Section 0). Many free kid-friendly animations available at lottiefiles.com.

---

## Appendix C: Questions Still Open

These need decisions before or during development:

| Question | Status | Notes |
|---|---|---|
| Child's name | ⏳ TBD | Developer to update in settings during setup |
| App icon / mascot | ⏳ TBD | Needed before TestFlight |
| App name | ✅ "Earned Recess" | Reserved on App Store Connect |
| Celebration sounds | Simple system sounds | May add custom audio later |
| Lottie dependency | ✅ Confirmed | Only 3rd party dep in V1. Add via SPM. |
| YouTube API key | ⏳ Session 11 | Never commit to repo |
| Bundle ID | ✅ com.earnedrecess.app | Registered in Apple Developer portal |
| Minimum iPad model | Any Pencil-compatible | iPad 6th gen or later |
| Apple Pencil required? | Yes for drawing | Finger fallback optional |

---

## Appendix D: Known Competitor — TimeSchool

Discovered during research. Download and study before Session 1.

```
App:     TimeSchool — Earn Screen Time
Store:   App Store (search "TimeSchool earn screen time")
Concept: Math puzzles → earn stars → unlock screen time
         PIN-protected parent settings
         Ages 4+
         Uses Apple Screen Time API

How EarnedRecess differs:
  → Drawing/handwriting vs math puzzles
  → Apple Pencil + PencilKit (premium input)
  → Quality scoring with progression phases
  → YouTube Kids as integrated reward
  → Sophisticated stroke scoring algorithm
  → Progression phases (tracing → guided → freehand)
  → Pluggable task + reward platform (V2+)
  → Ages 5-12 with adaptive difficulty

Action: Download TimeSchool before Session 1.
        Study the UX. Note what works and what to improve on.
```

---

*Document Version: 2.0*
*Last Updated: April 2026*
*Status: Session 0 Complete — Ready for Session 1*
*Next Step: Sign up for MacinCloud → Session 1 — Xcode project setup*
