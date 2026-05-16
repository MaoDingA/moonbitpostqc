# Delivery Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single-episode delivery directory preflight checker with creator and distribution profiles.

**Architecture:** Add a `delivery` package that owns asset classification, manifest parsing, rules, and report formatting. CLI parsing lives in `cli`, filesystem I/O stays in `cmd/main`, and existing `subtitle`, `qc`, and `timecode` packages provide subtitle validation.

**Tech Stack:** MoonBit packages, `moonbitlang/core/json`, `moonbitlang/async/fs`, existing MoonPost subtitle/QC/timecode libraries.

---

### Task 1: Delivery Package Skeleton And Tests

**Files:**
- Create: `delivery/moon.pkg`
- Create: `delivery/types.mbt`
- Create: `delivery/delivery_wbtest.mbt`

- [ ] Write tests for asset classification, language inference, and profile defaults.
- [ ] Run `moon test delivery --target native` and verify it fails because the package/API does not exist.
- [ ] Implement `DeliveryProfile`, `AssetKind`, `DeliveryAsset`, `classify_asset`, `language_from_subtitle_name`, `creator_profile`, and `distribution_profile`.
- [ ] Run `moon test delivery --target native`.

### Task 2: Manifest Parsing

**Files:**
- Create: `delivery/manifest.mbt`
- Modify: `delivery/delivery_wbtest.mbt`

- [ ] Write tests for parsing manifest JSON with `series`, `season`, `episode`, `title`, `frame_rate`, `duration`, `required_subtitles`, and `required_assets`.
- [ ] Run `moon test delivery --target native` and verify failure.
- [ ] Implement `parse_manifest`.
- [ ] Run `moon test delivery --target native`.

### Task 3: Delivery Checks And Reports

**Files:**
- Create: `delivery/check.mbt`
- Create: `delivery/report.mbt`
- Modify: `delivery/delivery_wbtest.mbt`

- [ ] Write tests for missing video, missing subtitle language, missing metadata/checksum, subtitle QC counts, duration overflow, human report, and JSON report.
- [ ] Run `moon test delivery --target native` and verify failure.
- [ ] Implement `check_delivery`, `format_delivery_report`, `format_delivery_json_report`, and `delivery_has_errors`.
- [ ] Run `moon test delivery --target native`.

### Task 4: CLI Parser And Main Wiring

**Files:**
- Modify: `cli/command.mbt`
- Modify: `cli/cli_wbtest.mbt`
- Modify: `cmd/main/moon.pkg`
- Modify: `cmd/main/main.mbt`
- Modify: `cmd/main/main_wbtest.mbt`

- [ ] Write parser and main tests for `moonpost delivery check <dir> --profile creator --manifest file --json --fail-on-error`.
- [ ] Run targeted tests and verify failure.
- [ ] Implement CLI command parsing and native filesystem directory scanning.
- [ ] Run targeted tests.

### Task 5: Examples, Docs, And CI

**Files:**
- Create example delivery directories under `examples/`.
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `.github/workflows/ci.yml`

- [ ] Add a good delivery example and a bad delivery example.
- [ ] Add README usage for `delivery check`.
- [ ] Add CI smoke tests for human report, JSON report, and fail-on-error.
- [ ] Run `moon fmt`, `moon info`, `moon check --target native`, `moon check --target wasm-gc`, `moon test --target native`, and `moon test --target wasm-gc`.
