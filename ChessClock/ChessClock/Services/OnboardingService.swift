import Foundation

struct OnboardingService {
    private static let key = "onboardingDismissed"

    static var shouldShowOnboarding: Bool {
        return !UserDefaults.standard.bool(forKey: key)
    }

    static func dismissOnboarding() {
        UserDefaults.standard.set(true, forKey: key)
    }
}
