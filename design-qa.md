# Liftoff Design QA

## Comparison Target

- Source visual truth: `DesignReferences/Liftoff-Home-Option-1.png`
- Implementation screenshot: `QA/home-implementation-final.png`
- Device viewport: iPhone 17 Pro Max, 440 x 956 points
- Source pixels: 853 x 1844
- Implementation pixels: 1320 x 2868 at 3x simulator density
- Normalization: both images were scaled to 853 x 1844 pixels before comparison
- State: light appearance, Today not logged, prior Bench Press entry at 225 lb x 5, Gold rank
- Expected frame difference: the source omits iOS device chrome; the implementation includes the Dynamic Island, status bar, and home safe areas

## Evidence

- Full view: `QA/home-source-vs-implementation-final.png`
- Hero and status focus: `QA/home-hero-focused-final.png`
- CTA, last lift, and navigation focus: `QA/home-actions-focused-final.png`
- Dark appearance: `QA/home-dark-final.png`
- Largest accessibility text setting after the fix: `QA/home-accessibility-xxxl.png`

## Findings

No actionable P0, P1, or P2 differences remain.

- Fonts and typography: Bebas Neue reproduces the tall condensed poster headline and all-caps CTA. Semantic condensed system styles preserve mixed-case UI text and Dynamic Type behavior. Wrapping, hierarchy, and optical weight are consistent with the source.
- Spacing and layout rhythm: the source order, page margins, hero/status grouping, flexible empty space, CTA, last-lift card, and persistent navigation are preserved. Remaining top offset is expected from native iPhone status chrome.
- Colors and tokens: adaptive paper, ink, muted ink, hairline, Gold, and safety-orange tokens match the source intent and maintain contrast in dark appearance.
- Image quality and asset fidelity: the screen has no photographic or decorative image assets. SF Symbols provide sharp native exercise, profile, and navigation icons at device density.
- Copy and content: visible static copy matches the selected visual target. Dynamic lift, rank, and status content remains coherent in logged and unlogged states.
- Interaction and accessibility: the primary CTA, tab bar, last-lift card, logger, history, exercise detail, settings, onboarding, and rank-up routes were exercised. VoiceOver labels are present on primary controls. At the largest system text category, semantic labels scale to an Accessibility 1 ceiling while the decorative poster type remains fixed; the screen remains readable, scrollable, and operable.

## Comparison History

1. Pass 1 found a P2 typography mismatch: the system compressed fallback was substantially shorter than the source display face and weakened the hero hierarchy.
   - Evidence: `QA/home-source-vs-implementation-pass2.png`
   - Fix: bundled and registered Bebas Neue, then separated poster typography from mixed-case UI typography.
   - Post-fix evidence: `QA/home-source-vs-implementation-final.png`
2. Accessibility pass found a P1 resilience issue: unrestricted semantic scaling at the largest accessibility category obscured persistent navigation and pushed the primary flow below the viewport.
   - Evidence: `QA/home-accessibility-before-cap.png`
   - Fix: kept decorative poster type fixed, converted functional labels to semantic styles, capped the Today surface and persistent tab labels at Accessibility 1, and retained scrolling.
   - Post-fix evidence: `QA/home-accessibility-xxxl.png`

## Primary Interactions Tested

- Completed all onboarding choices and metric entry
- Opened the quick logger from Today and History
- Switched recent, ranked, and custom exercises
- Verified exercise-specific last-set prefill and replacement on exercise changes
- Saved lifts and observed PR, XP, score, streak, and rank feedback
- Opened exercise-first history, timeline, search, and exercise detail
- Verified per-exercise chart, personal best, volume, rank, and log list
- Logged again from an exercise detail route
- Opened Progress, Settings, and rank-up celebration
- Checked light, dark, and largest accessibility text appearances

## Follow-up Polish

- P3: the source uses a conceptual bench-machine pictogram while the implementation uses the closest native strength-training SF Symbol. The native icon is intentionally retained for consistency, accessibility, and rendering quality.

final result: passed
