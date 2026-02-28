# Onboarding System

Progressive 6-stage onboarding that introduces each feature the first time the user encounters it. Each stage fires once, persisted via `UserDefaults` bools.

---

## Flow

```
First launch:
  Stage 0 (Welcome)  →  Stage A (Clock tour, 3 steps)  →  user taps board  →  ViewMode.info

First info panel visit:
  Stage B (Info tour, 2 steps)  →  user plays puzzle  →  ViewMode.puzzle

First puzzle visit:
  Stage E (Puzzle explanation)  →  user solves/fails  →  back to info

First puzzle completion (1 game played):
  Stage C (Replay nudge)  →  user taps  →  ViewMode.replay

First replay visit:
  Stage D (Scrub bar explanation, auto-dismiss 5s)
```

All stages are **tap-anywhere-to-advance** — no close buttons, no chip-only tap targets. Exception: Stage B-2 uses pass-through interaction (CTA button is directly clickable).

---

## Architecture

### Persistence: `OnboardingService.swift`

Pure static struct. Each stage has a `shouldShowStageX: Bool` getter and `dismissStageX()` setter.

| Stage | UserDefaults Key | Getter | Dismisser |
|-------|-----------------|--------|-----------|
| 0 | `welcomeScreenShown` | `shouldShowWelcome` | `dismissWelcome()` |
| A | `onboardingDismissed` | `shouldShowStageA` | `dismissStageA()` |
| B | `infoPanelOnboardingSeen` | `shouldShowStageB` | `dismissStageB()` |
| C | `replayNudgeSeen` | `shouldShowStageC` | `dismissStageC()` |
| D | `replayOnboardingSeen` | `shouldShowStageD` | `dismissStageD()` |
| E | `puzzleOnboardingSeen` | `shouldShowStageE` | `dismissStageE()` |

`resetAll()` clears all 6 keys (for testing).

### Orchestration: `ClockView.swift`

ClockView owns all `@State` flags and renders overlays in ZStack order **after** content layers so they're always on top:

```
ZStack {
    // 1. Content (boardWithRing / InfoPanelView / GuessMoveView / GameReplayView)
    // 2. Ring layers (GoldRingLayerView / PuzzleRingView)
    // 3. Stage 0 overlay (WelcomeOverlayView)
    // 4. Stage A overlay (OnboardingOverlayView)
    // 5. Stage B overlay (stageBOverlay computed property)
    // 6. Stage C overlay (stageCOverlay computed property)
    // 7. Stage D overlay (stageDOverlay computed property)
    // Stage E is rendered inside GuessMoveView's own ZStack
}
```

**State flags:**

| Flag | Default | Stage |
|------|---------|-------|
| `showWelcome` | `OnboardingService.shouldShowWelcome` | 0 |
| `showOnboarding` | `false` (set after welcome dismisses) | A |
| `showInfoOnboarding` | `false` | B |
| `infoOnboardingStep` | `1` | B (substep) |
| `showReplayNudge` | `false` | C |
| `showReplayOnboarding` | `false` | D |
| `highlightReplayBar` | `false` | D (progress bar glow, separate from overlay) |
| `showPuzzleOnboarding` | `false` | E |
| `ctaOnboardingBrighten` | `false` | B-2 / C (auto-brighten CTA button) |
| `hideTickMarks` | `OnboardingService.shouldShowStageA` | A (tick marks hidden during steps 1–2) |
| `forceFullRing` | `OnboardingService.shouldShowStageA` | A (ring shown full during steps 1–2) |

**Triggers** (in `.onChange(of: viewMode)`):
- B: `viewMode == .info && shouldShowStageB` → 0.6s delay
- D: `viewMode == .replay && shouldShowStageD` → 0.8s delay, auto-dismiss after 5s
- E: `viewMode == .puzzle && shouldShowStageE` → 0.8s delay

**WindowObserver reset:** All flags set to `false` on popover reopen (don't replay anything).

### Shared callout pill: `OnboardingCalloutView.swift` — "Gold Ember" design

Reusable opaque callout pill used by every stage. VStack layout: centered text → optional subtext → optional progress dots. No icons, no close button. The pill itself does NOT handle tap — the parent overlay's `.onTapGesture` handles all interaction.

**Visual design — "Gold Ember":** The pill belongs to the gold ring's visual family. Fully opaque (no material, no transparency) so it renders identically on every scrim level and over raw UI (Stage E has no scrim).

| Layer | Detail |
|-------|--------|
| Base | Dark espresso `Color(red: 0.10, green: 0.08, blue: 0.06)` — warm enough to belong, dark enough to contrast with board squares |
| Depth gradient | `accentGoldLight` at 6% top → clear → black 15% bottom |
| Top gleam | `accentGoldLight` at 12% → clear, concentrated to top 35% |
| Border | `accentGold` at 30%, 0.75pt stroke — crisp gold edge |
| Surface warmth | `brightness(0.05)` — pill feels slightly lit |
| Outer glow | `accentGold` at 38%, 28pt radius — warm golden halo |
| Inner glow | `accentGold` at 18%, 8pt radius — tighter definition |
| Grounding shadow | Black 40%, 10pt radius, 4pt y-offset |

**Typography:** Warm cream `(0.94, 0.89, 0.78)` for primary text, same at 55% opacity for subtext — harmonizes with the gold glow, no cold-white anywhere. 12.5pt regular weight. Inactive progress dots use the same cream at 25% opacity; active dots use `accentGold`.

**Signature:**
```swift
struct OnboardingCalloutView: View {
    let text: String
    var subtext: String? = nil
    var step: Int = 0         // current step (for dot highlighting)
    var totalSteps: Int = 0   // 0 = no dots shown
    let onTap: () -> Void     // unused in current design, kept for API
}
```

### Spotlight scrim pattern

Used by stages A, B, C, D to darken everything except a target area. Implemented via mask + destinationOut:

```swift
Rectangle()
    .fill(Color.black.opacity(0.55))
    .mask {
        Rectangle().fill(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: r)
                    .fill(Color.black)
                    .frame(width: w, height: h)
                    .position(x: cx, y: cy)
                    .blur(radius: 4)       // soft feather
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
    }
```

ClockView has a reusable helper: `spotlightScrim(cutout: CGRect, cornerRadius: CGFloat)`.

---

## Stage Details

### Stage 0 — Welcome Screen

**File:** `WelcomeOverlayView.swift`
**Trigger:** First launch (`shouldShowWelcome`)
**Duration:** Auto-dismiss after 3s, or tap anywhere

**Content:** "Chess Clock" (24pt semibold) + gold divider line + "Every board tells the time" (13pt regular)

**Animations:**
- Entrance: staggered — scrim (0.5s) → title slide-up+fade (0.7s, 0.15s delay) → gold divider scale-in (0.5s, 0.35s delay) → subtitle slide-up+fade (0.7s, 0.5s delay)
- Exit: content lifts up + fades (0.5s easeInOut), then calls `onDismiss()`

**Transition to Stage A:** After welcome dismisses, 0.3s delay, then `showOnboarding = true`.

---

### Stage A — Clock Tour (3 steps)

**File:** `OnboardingOverlayView.swift` (self-contained, manages its own 3-step state)
**Trigger:** After Stage 0 dismisses (or on launch if welcome already seen)
**ViewMode:** `.clock`

| Step | Copy | Spotlight |
|------|------|-----------|
| 1 | "Every hour, a real game\nThe board shows the hour" | Board bright (280x280 crisp cutout, **no blur**), ring **extra dark** (0.72), tick marks **hidden**, ring **forced full** |
| 2 | "The ring shows the minutes" | Ring bright (annulus cutout, eoFill, **no blur** — crisp edge), board **extra dark** (0.72), tick marks **hidden**, ring **forced full** |
| 3 | "Tap anywhere for game details" | No scrim — ring fill animation sequence → tick marks slide in |

**Pill position:** Always at bottom (`.padding(.bottom, 16)`)
**Progress dots:** 3 dots, gold = completed
**Step 3 is 1-click:** Calls `dismissStageA()` + `onDismiss()` + `onBoardTap()` — dismisses overlay AND navigates to info panel

**Full ring:** During steps 1–2, the ring appears fully filled (as if XX:59:59) via `forceFullRing` flag. The progress mask is set to the full bounds rect, making all gold noise visible around the entire ring. This creates a richer visual on A-2 when the ring is spotlighted.

**Step 3 — Ring Fill Animation Sequence** (triggered by `onReachFinalStep` setting `forceFullRing = false`):
1. **Gold fade-out** (0.3s easeInEaseOut): goldContainer opacity → 0
2. **Snap reset** (instant, after 0.35s): mask set to empty, opacity restored to 1
3. **Clockwise fill** (fixed velocity, linear): frame-by-frame fill from 0 → actual minute progress via `wedgePath`. Duration = `progress * 3.0s` (3s for a full ring, proportional for partial — e.g. 30 min = 1.5s, 15 min = 0.75s)
4. **Tick marks slide in** (0.5s easeOut): each tick slides from its edge (top↑, right→, bottom↓, left←) with opacity fade. Delayed until fill completes: `0.35 + progress * 3.0 + 0.15` seconds after step 3 entry

**Reuse note:** This fill animation sequence lives entirely in `GoldRingLayerView.updateNSView` — it triggers whenever `forceFullRing` transitions from `true` to `false`. To reuse (e.g. on app open), set `forceFullRing = true` initially, then set it to `false` when the fill should begin. The tick mark delay is computed separately in `ClockView.onReachFinalStep` based on current progress.

**Tick marks:** Hidden (opacity 0, translated 8pt toward their respective edges) during steps 1–2 via `hideTickMarks` flag. Each tick is wrapped in a per-tick `CALayer` group stored in `tickGroups`. Tick reveal is delayed dynamically until after fill animation completes. Ensures ticks and ring state are also restored on `onBoardTap` (step 3 dismiss) and in `debugReplay`.

**Butt rounding:** The ring's trailing edge at 12 o'clock uses a subtle quadratic bezier curve (~1pt leftward bulge) instead of a flat close, ensuring smooth appearance during the fill animation. The bulge stays within half the tick width (1.25pt) to not protrude past the tick mark.

**Helper shape:** `RingAnnulusShape` (private) — even-odd ring path (`FillStyle(eoFill: true)`), outer 300 minus inner 280.

---

### Stage B — Info Panel Tour (2 steps)

**File:** `ClockView.swift` → `stageBOverlay` computed property
**Trigger:** First `viewMode == .info` transition, 0.6s delay
**ViewMode:** `.info`

| Step | Copy | Pill Position | Spotlight Cutout |
|------|------|---------------|-----------------|
| 1 | "See the players and the event" | Top | Metadata area: `CGRect(x:6, y:220, w:288, h:66)` |
| 2 | "Play the winning moves from this game" | Bottom | Board+CTA area: `CGRect(x:55, y:13, w:190, h:212)` |

**Progress dots:** 2 dots
**Persistence:** Stage B is persisted (`dismissStageB()`) when advancing from step 1 to step 2 — prevents replaying step 1 on popover reopen.
**InfoPanelView highlight props:** `highlightMetadata` (step 1) and `highlightCTA` (step 2) add subtle gold glow overlays (0.3 and 0.35 opacity respectively).

**Step 2 pass-through interaction:** The overlay has `allowsHitTesting(false)` on step 2 — clicks and hovers pass through to the CTA button underneath. A background `Color.clear` tap handler behind InfoPanelView catches taps on non-button areas to dismiss the overlay.

**Step 2 auto-brighten effect:** After step 2 appears, 0.5s delay → CTA button brightens (+0.08, same as hover). If user hovers, button just grows (1.04x scale, already bright). If user clicks CTA, navigates to puzzle mode. If user taps elsewhere (dismisses overlay), 1s delay → brightness animates back to normal (0.4s easeInOut). State flag: `ctaOnboardingBrighten` in ClockView, passed to InfoPanelView as `onboardingBrighten`. Brightness modifier: `(isHovered || onboardingBrighten) ? 0.08 : 0.0`.

---

### Stage C — Replay Nudge

**File:** `ClockView.swift` → `stageCOverlay` computed property
**Trigger:** First puzzle completion (`guessService.stats.totalPlayed == 1`), after navigating back to info, 0.6s delay
**ViewMode:** `.info`

**Copy:**
- If solved: "See how the full game played out"
- If failed: "Study the full game and the winning line"

**Pill position:** Top
**Spotlight cutout:** CTA/Review button area: `CGRect(x:99, y:186, w:104, h:38)`

**Pass-through interaction:** Overlay has `allowsHitTesting(false)` — clicks and hovers pass through to the CTA button. A background `Color.clear` tap handler behind InfoPanelView catches taps on non-button areas to dismiss via `dismissStageCOverlay()`.

**Auto-brighten effect:** After overlay appears, 0.5s delay → CTA button brightens (+0.08). If user hovers, button just grows. If user clicks CTA, navigates to replay. If user taps elsewhere (dismisses overlay), 1s delay → brightness animates back to normal. Reuses `ctaOnboardingBrighten` state flag (same as B-2).

---

### Stage D — Replay Scrub Explanation

**File:** `ClockView.swift` → `stageDOverlay` computed property
**Trigger:** First `viewMode == .replay` transition, 0.8s delay
**ViewMode:** `.replay`
**Auto-dismiss:** 5s after appearing

**Copy:** "Drag the golden bar or use arrows to scrub"
**Pill position:** Lowered from top (`Spacer().frame(height: 40)`) to avoid covering game title
**Spotlight cutout:** Progress bar: `CGRect(x:12, y:270, w:276, h:20)`

**Progress bar enhancement:** When `highlightProgressBar` is true, the `ReplayProgressBar` gets `.brightness(0.25)` + gold glow (0.7 opacity). `highlightReplayBar` state is separate from `showReplayOnboarding` — on dismiss, highlight is removed instantly (no animation) before the overlay fades out, preventing material flash artifacts on `topRow` and `controlsRow`.

---

### Stage E — Puzzle Explanation

**File:** `GuessMoveView.swift` (rendered inside its own ZStack)
**Trigger:** First `viewMode == .puzzle` transition, 0.8s delay
**ViewMode:** `.puzzle`

**Copy:** `"It's {H}:{MM} {AM/PM}\nFind the mate in {N} as {White/Black}"`
(Dynamic, computed from `state.hour`, `state.minute`, `state.isAM`)

**Pill position:** Bottom (`.padding(.bottom, 12)`)
**Scrim:** None (no darkness — nothing specific to focus on)

**Props passed from ClockView:**
```swift
showOnboarding: showPuzzleOnboarding,
onDismissOnboarding: {
    OnboardingService.dismissStageE()
    withAnimation(ChessClockAnimation.smooth) { showPuzzleOnboarding = false }
}
```

---

## Design Rules

1. **Z-order:** Overlays always render AFTER content in ZStack — never behind the scrim
2. **Click-anywhere:** Every overlay has `.contentShape(Rectangle()).onTapGesture` on the full frame. Exception: Stage B-2 uses `allowsHitTesting(false)` so the CTA button is directly interactive
3. **No icons:** Callout pills are text-only (icons were removed for visual cleanliness)
4. **No X buttons:** Dismissed by tapping anywhere (removed `showDismiss` from the API)
5. **Gold Ember pills:** All pills use the "Gold Ember" design — opaque dark espresso base, gold-tinted gradients, gold border, warm cream text, and a golden outer glow. No material, no transparency, guaranteed identical across all scrim levels. Text uses explicit warm cream color `(0.94, 0.89, 0.78)`, never system `.primary`/`.secondary`
6. **Animation:** All show/hide uses `ChessClockAnimation.smooth` (0.4s easeInOut). Stage D dismiss uses `.dramatic` (0.6s). Welcome has custom staggered entrance.
7. **No replay on reopen:** `WindowObserver.onBecomeKey` resets all flags to `false`

---

## Debug Replay

`OnboardingService.debugReplay` (in `OnboardingService.swift`) — when `true`, all onboarding replays from Stage 0 every time the popover opens. No rebuild or terminal commands needed between tests, just close and reopen the popover.

**Turn off:** tell Claude "turn off debugReplay"
