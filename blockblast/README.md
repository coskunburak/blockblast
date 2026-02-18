# Block Blast

Production-ready SwiftUI + SpriteKit puzzle game with monetization, analytics, remote tuning, and release automation.

## Core flow

- Home -> Mode Selection -> Game -> Results
- Store and Settings are reachable from Home

## Features

- Classic + Daily Challenge game modes
- Rewarded continue and rewarded coin flows
- Interstitial cadence from remote config
- IAP: Remove Ads + Starter Pack
- Accessibility: Large text and high-contrast mode
- Localization: English + Turkish

## Local development

```bash
xcodebuild -project blockblast.xcodeproj -scheme blockblast -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max,OS=18.4' test
```

## QA scripts

```bash
bash blockblast/Scripts/device_matrix_test.sh
bash blockblast/Scripts/leak_check.sh
```

## Fastlane

```bash
fastlane ios quality_gate
fastlane ios beta
fastlane ios upload_metadata
fastlane ios release_ready
```

## Docs

- `Docs/Phase6_Polish_UI_VFX_Accessibility_Localization.md`
- `Docs/Phase7_QA_TestFlight_Store.md`
- `Docs/AppStore_Privacy_Texts.md`
