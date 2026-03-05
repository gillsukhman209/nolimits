You are a senior iOS engineer. Build an MVP iOS app in SwiftUI called “Liftoff”.

Core principle

- Keep it extremely simple and fast.
- This is NOT a nutrition app. No calories, macros, meal logging, water, or anything like that.
- No social, no community, no AI coaching, no workout plans.
- The entire MVP is: onboarding → paywall → daily lift logging → rank progress.

Platform and tech

- SwiftUI (iOS 17+).
- Use Superwall for the paywall.
- No authentication. No accounts. No sign-in. User should hit paywall quickly and pay to unlock.
- Store user data locally (SwiftData preferred; CoreData acceptable if needed).
- Use scalable architecture and best practices: clean separation of concerns, testable services, dependency injection, modular structure, and maintainable navigation.

MVP user flow

1. Launch
2. Simple onboarding (only a few screens, minimal questions)
   - Ask: experience level (Beginner/Intermediate/Advanced)
   - Ask: primary goal (Strength/Muscle/Fat loss)
   - Ask: bodyweight + height (for ranking calculation inputs)
3. Immediately show Superwall paywall
   - If user purchases or already has access: continue
   - If user closes paywall without purchasing: keep them blocked behind a soft gate (show home blurred/locked with “Unlock to start” button that re-opens paywall)
4. Home screen (post-paywall unlock)
   - Show current rank badge (Iron/Bronze/Silver/Gold/Platinum/Diamond/Titan)
   - Show strength score (a single number)
   - Show progress bar to next rank
   - Show “Log Today’s Lift” primary CTA
   - Show streak (days logged in a row)
5. Log screen (daily logging)
   - Goal: user logs a single lift for the day quickly
   - Fields: Lift type (Bench/Squat/Deadlift) + weight + reps
   - Save entry for today; prevent multiple “daily logs” unless the user explicitly edits
   - Show immediate feedback: XP gained, updated score, updated rank/progress
6. Rank-up celebration screen (only when rank increases)
   - Short animation + “You ranked up to X”
   - Return to home

Ranking system (simple, transparent)

- Convert (weight, reps) into estimated 1RM using:
  e1RM = weight \* (1 + reps/30)
- Normalize by bodyweight:
  score = e1RM / bodyweight
- Convert score to rank using thresholds (tuneable constants):
  Iron < 0.60
  Bronze 0.60–0.79
  Silver 0.80–0.99
  Gold 1.00–1.19
  Platinum 1.20–1.39
  Diamond 1.40–1.59
  Titan >= 1.60
- Also maintain XP as a simple gamification layer:
  +10 XP per saved log
  +25 XP bonus if today’s e1RM beats the user’s prior best for that lift
  Streak bonus: +20 XP each day of streak
- Rank is determined only by the normalized score, not XP. XP is just for motivation and future features.

Notifications (simple)

- Local notifications only.
- Default reminder time: 7:30 PM local time.
- If user has not logged today by reminder time, send: “Log today’s lift to keep your streak.”
- Provide a simple settings screen to toggle reminders and change the time.

UI/UX requirements

- Polished, modern, minimal.
- Smooth transitions and microinteractions.
- One-handed friendly layout.
- Clear typography and spacing.
- Dark mode first, but support light mode.
- Use SwiftUI best practices: small reusable components, consistent design system, accessibility (Dynamic Type, VoiceOver labels), and haptics for key actions (save, rank-up).

Project structure (scalable)

- Use an app architecture that can scale, e.g.:
  - Presentation layer (Views, ViewModels)
  - Domain layer (Models, Use Cases)
  - Data layer (Repositories, Storage)
  - Services (Paywall, Notifications)
- Provide a clean folder structure and explain responsibilities.
- Use dependency injection (simple container pattern).
- Use async/await appropriately.
- Avoid massive view files; keep files focused.
- Include basic unit-testable logic for ranking and streak calculations.

Deliverables

1. A clear high-level plan (screens + navigation).
2. Data model definitions (SwiftData models) for:
   - UserProfile (height, weight, goal, experience)
   - LiftEntry (date, liftType, weight, reps, e1RM)
   - Stats (streak, bests per lift, lastLoggedDate, xp)
3. Implementation in SwiftUI with sample code for each screen.
4. Ranking + XP calculation utilities with unit-testable functions.
5. Superwall integration points:
   - where to initialize
   - how to present paywall
   - how to check entitlement/unlocked state
6. Local notification scheduling code.
7. Make sure the app compiles and runs.

Important constraints

- Do not add authentication.
- Do not add nutrition features.
- Do not add workout programs.
- Keep MVP very small and shippable.

Start by proposing the file/folder structure and navigation flow, then generate the SwiftUI code.
