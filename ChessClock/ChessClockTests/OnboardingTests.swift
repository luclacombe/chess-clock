import XCTest
@testable import ChessClock

final class OnboardingTests: XCTestCase {
    private let key = "onboardingDismissed"

    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: key)
    }

    // Test 1: key absent → shouldShowOnboarding returns true
    func testKeyAbsent_shouldShowOnboarding_returnsTrue() {
        XCTAssertNil(UserDefaults.standard.object(forKey: key),
                     "Key must be absent before test")
        XCTAssertTrue(OnboardingService.shouldShowOnboarding,
                      "shouldShowOnboarding must return true when key is absent")
    }

    // Test 2: key present → shouldShowOnboarding returns false
    func testKeyPresent_shouldShowOnboarding_returnsFalse() {
        UserDefaults.standard.set(true, forKey: key)
        XCTAssertFalse(OnboardingService.shouldShowOnboarding,
                       "shouldShowOnboarding must return false after key is set")
    }

    // Test 3: dismissOnboarding() writes the key
    func testDismissOnboarding_writesKey() {
        XCTAssertNil(UserDefaults.standard.object(forKey: key),
                     "Key must be absent before dismiss")
        OnboardingService.dismissOnboarding()
        XCTAssertNotNil(UserDefaults.standard.object(forKey: key),
                        "onboardingDismissed key must be written after dismissOnboarding()")
        XCTAssertTrue(UserDefaults.standard.bool(forKey: key),
                      "onboardingDismissed must be true after dismissOnboarding()")
    }
}
