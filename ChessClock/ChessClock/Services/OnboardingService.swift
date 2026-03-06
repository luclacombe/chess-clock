import Foundation

struct OnboardingService {
    // Stage 0 (welcome screen)
    private static let stage0Key = "welcomeScreenShown"
    // Stage A (first-launch clock tour)
    private static let stageAKey = "onboardingDismissed"
    // Stage B (first info panel visit)
    private static let stageBKey = "infoPanelOnboardingSeen"
    // Stage C (replay nudge after first puzzle)
    private static let stageCKey = "replayNudgeSeen"
    // Stage D (first replay visit)
    private static let stageDKey = "replayOnboardingSeen"
    // Stage E (first puzzle visit)
    private static let stageEKey = "puzzleOnboardingSeen"

    // Stage 0
    static var shouldShowWelcome: Bool { !UserDefaults.standard.bool(forKey: stage0Key) }
    static func dismissWelcome() { UserDefaults.standard.set(true, forKey: stage0Key) }

    // Stage A
    static var shouldShowStageA: Bool { !UserDefaults.standard.bool(forKey: stageAKey) }
    static func dismissStageA() { UserDefaults.standard.set(true, forKey: stageAKey) }

    // Stage B
    static var shouldShowStageB: Bool { !UserDefaults.standard.bool(forKey: stageBKey) }
    static func dismissStageB() { UserDefaults.standard.set(true, forKey: stageBKey) }

    // Stage C
    static var shouldShowStageC: Bool { !UserDefaults.standard.bool(forKey: stageCKey) }
    static func dismissStageC() { UserDefaults.standard.set(true, forKey: stageCKey) }

    // Stage D
    static var shouldShowStageD: Bool { !UserDefaults.standard.bool(forKey: stageDKey) }
    static func dismissStageD() { UserDefaults.standard.set(true, forKey: stageDKey) }

    // Stage E
    static var shouldShowStageE: Bool { !UserDefaults.standard.bool(forKey: stageEKey) }
    static func dismissStageE() { UserDefaults.standard.set(true, forKey: stageEKey) }

    // Backward compat
    static var shouldShowOnboarding: Bool { shouldShowStageA }
    static func dismissOnboarding() { dismissStageA() }

    /// When true, onboarding replays from Stage 0 every time the popover opens.
    /// Set to false when done testing.
    static let debugReplay = false

    // Testing
    static func resetAll() {
        for key in [stage0Key, stageAKey, stageBKey, stageCKey, stageDKey, stageEKey] {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
