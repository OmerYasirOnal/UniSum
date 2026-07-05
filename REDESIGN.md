# UniSum — UI Redesign Notes

A full visual refresh of the app. **No business logic, networking, or backend
contracts were changed** — only the presentation layer, plus a DEBUG-only
preview harness and new brand assets.

## Brand & Design System

New folder `UNICalculate/DesignSystem/`:

- **`Theme.swift`** — all design tokens:
  - Brand palette (indigo → violet): `Color.brandPrimary` `#4F46E5`, `Color.brandSecondary` `#7C3AED`, plus `brandDeep`, `brandTint`.
  - Status colors: `successGreen`, `warningAmber`, `dangerRed`.
  - Surfaces: `appBackground`, `cardBackground`, `hairline` (all light/dark aware).
  - `LinearGradient.brand`, spacing (`DS.Spacing`), radii (`DS.Radius`), `softShadow`/`brandGlow`.
  - `GradeColor.forGPA(_:)` / `forScore(_:)` — maps performance to a semantic color.
- **`Components.swift`** — reusable views: `PrimaryButtonStyle`, `SecondaryButtonStyle`,
  `FloatingAddButton`, `GPARing`, `GradeBadge`, `StatTile`, `WeightBar`, `EmptyStateView`,
  `AppLogoMark`, `AppWordmark`, `SectionHeaderLabel`, `.card()`, `.plainCardRow()`.

`AccentColor` in the asset catalog is now indigo (was empty); hardcoded `.blue`
usages across the app were replaced with tokens.

## What changed per screen

Auth (Login/Signup/ForgotPassword), Terms, Courses (GPA ring + color-coded cards),
Course Detail (GPA ring hero + weight bars), Sidebar, Profile, and the add/edit
modals were rebuilt on the design system. All light + dark mode verified in the
simulator.

Fixes made along the way (all presentation/localization, no logic):
- Profile language picker showed raw keys (`english`/`turkish`) — now localized.
- Added 12 missing localization keys to **both** `tr.lproj` and `en.lproj`.
- `CourseListView` hardcoded Turkish empty-state string → localized.
- `GradeFormView` weight-exceeded alert built a broken key → now uses `weight_exceed_error`.
- `SettingsView` (currently unlinked) hardcoded English strings → localized.

## App icon

`Assets.xcassets/AppIcon.appiconset/` regenerated (light/dark/tinted, 1024²) with
the indigo→violet cap mark that matches the in-app logo. Originals are preserved
in git history. Regenerate with `scratchpad/makeicon.swift` if needed.

## DEBUG demo / preview harness

`DesignSystem/DemoData.swift` + a router in `ContentView` let you launch any
screen with sample data and **no backend** — compiled out of Release via `#if DEBUG`.

Launch from the command line:

```bash
# any screen: terms | courses | detail | profile | signup | forgot | addterm | addcourse | login
SIMCTL_CHILD_UNISUM_DEMO_SCREEN=courses \
  xcrun simctl launch "iPhone 17" onal.UNICalculate -UIDemoMode
```

Or add `-UIDemoMode` to the scheme's Run arguments in Xcode.

## Building / running

`NetworkManager` reads `BaseURL` from `UNICalculate/Secrets.plist` (gitignored). A
local placeholder is required for the app to launch; create it with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>BaseURL</key><string>http://YOUR_BACKEND_HOST</string>
</dict></plist>
```
