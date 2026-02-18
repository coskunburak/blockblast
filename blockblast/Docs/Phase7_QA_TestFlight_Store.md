# Phase 7 — QA, TestFlight, Store Readiness

## Device matrix

Run on both baseline and stress profiles:

- iPhone 16e — compact baseline / lower-end profile
- iPhone 16 Pro Max — target flagship profile
- iPad Pro 13-inch (M4) — tablet layout and spacing validation

Command:

```bash
bash blockblast/Scripts/device_matrix_test.sh
```

## Memory leak checks

Command:

```bash
bash blockblast/Scripts/leak_check.sh
```

Produces:

- `build/memory-leaks.trace`

Fail release if leaks are reproducible in repeated sessions.

## Fastlane release automation

### Quality checks

```bash
fastlane ios quality_gate
```

### TestFlight upload

```bash
fastlane ios beta
```

### Metadata + screenshots upload

```bash
fastlane ios upload_metadata
```

### Full release-ready pipeline

```bash
fastlane ios release_ready
```

## App Store package

Prepared in `fastlane/metadata`:

- `en-US`: name, subtitle, description, keywords, promo, release notes, urls
- `tr-TR`: same metadata set

Screenshots folders prepared:

- `fastlane/screenshots/en-US`
- `fastlane/screenshots/tr-TR`

## Crash-free target

Release gate recommendation:

- Crash-free sessions >= 99.5%
- No blocker leaks from `Leaks` template
- Test matrix green on all listed devices

## CI

GitHub workflows added:

- `.github/workflows/ci.yml` for PR/push test validation
- `.github/workflows/release.yml` for manual release pipeline execution
