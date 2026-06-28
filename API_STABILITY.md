# MoonPost API Stability

MoonPost is still pre-1.0, but exported APIs are grouped by intended stability
so downstream users can choose the right integration surface.

## Stable For 0.x Users

These packages are intended to stay source-compatible across patch releases.
Breaking changes should wait for a minor release and be called out in release
notes.

- `MaoDingA/moonpost/subtitle`: SRT/WebVTT/ASS parsing and writing types.
- `MaoDingA/moonpost/timecode`: frame rates, `Timecode`, `Duration`,
  `TimecodeRange`, rational seconds, and explicit interop helpers.
- `MaoDingA/moonpost/qc`: `QcProfile`, `QcIssue`, report formatting, and cue
  checks.
- `MaoDingA/moonpost/retime`: cue offset, frame-rate conversion, and frame
  snapping.
- `MaoDingA/moonpost/align`: bilingual merge and split helpers.

## Profile APIs

Creator and delivery profiles are public because they are useful for
applications and CI workflows. Profile thresholds may be tuned when real sample
calibration shows a better default, but profile names should remain stable once
published.

- `MaoDingA/moonpost/creator`
- `MaoDingA/moonpost/delivery`

## Experimental APIs

These APIs are public for early adopters, but may change in minor releases as
real packages and edge cases are added.

- `MaoDingA/moonpost/dcp`: lightweight DCP AssetMap / PKL / CPL parsing and
  package consistency checks.
- `MaoDingA/moonpost/cli`: command-line parser model used by the bundled CLI.
- `MaoDingA/moonpost/wasm_demo/core`: browser demo bindings.

## Compatibility Rules

- Patch releases should avoid removing or renaming public declarations.
- Minor releases may add public APIs and may adjust experimental APIs.
- Cross-rate timecode behavior stays explicit: APIs should return `None` or
  `Result` instead of silently choosing a conversion policy.
- Package validators should report structured issues rather than panic on
  malformed user input.
