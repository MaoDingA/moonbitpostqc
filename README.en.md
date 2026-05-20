# MoonPost

<p align="right">
English | <a href="README.md">简体中文</a>
</p>

<p align="left">
  <a href="https://github.com/MaoDingA/moonbitpostqc/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/MaoDingA/moonbitpostqc/actions/workflows/ci.yml/badge.svg"></a>
  <a href="README.en.md"><img alt="English current" src="https://img.shields.io/badge/English-current-0f766e?style=flat-square"></a>
  <a href="README.md"><img alt="简体中文 README" src="https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-README-64748b?style=flat-square"></a>
  <img alt="MoonBit native" src="https://img.shields.io/badge/MoonBit-native-8b5cf6?style=flat-square">
  <img alt="license Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-22c55e?style=flat-square">
  <img alt="terminal first" src="https://img.shields.io/badge/terminal-first-475569?style=flat-square">
  <img alt="mode CLI + Wasm" src="https://img.shields.io/badge/mode-CLI%20%2B%20Wasm-2563eb?style=flat-square">
  <img alt="formats SRT + WebVTT" src="https://img.shields.io/badge/formats-SRT%20%2B%20WebVTT-f97316?style=flat-square">
  <img alt="QC ready" src="https://img.shields.io/badge/QC-ready-0ea5e9?style=flat-square">
</p>

MoonPost is a pure MoonBit toolkit for subtitles, timecode, and post-production
quality checks across two real production workflows: creator-side subtitle
cleanup before publishing, and film/OTT subtitle delivery validation.

MoonPost is organized into two capability lines instead of mixing creator
habits and delivery requirements into one oversized checker:

- Creator: for self-media, spoken content, short-form video, and AI-generated
  subtitle cleanup. It defaults to gentle hints and focuses on text
  conventions, punctuation, typo and terminology hints, reading experience,
  and platform-specific subtitle habits.
- Delivery: for film, OTT, broadcast, and subtitle delivery QC. It defaults to
  stricter validation and focuses on timeline legality, frame grids, CPL/CPS,
  minimum gaps, JSON reports, and automated failure exit codes.

Both lines share the same SRT/WebVTT parser, QC rule engine, timecode helpers,
and report formatter. The shared core stays neutral; platform habits and
delivery requirements are expressed through Creator and Delivery profiles.

MoonPost does not decode video, transcode media, or wrap FFmpeg. Its scope is
the post-production infrastructure layer that can be implemented
deterministically in MoonBit: parsers, data models, QC rules, reports, CLI
tools, and Wasm-ready core packages.

MoonPost is an original MoonBit project rather than a port of a specific
third-party library. If future work references or ports another open-source
project, the source, license, and scope will be documented.

## Features

Shared foundation:

- Parse and write SRT / WebVTT subtitle files and convert between them.
- Parse and format SMPTE-style timecode, including timecode/frame conversion.
- Support common frame rates: `23.976`, `24`, `25`, `29.97`, `29.97df`, `30`,
  `50`, `59.94`, and `59.94df`.
- Retime subtitles by offset, frame-rate conversion, or frame snapping.
- Merge and split bilingual subtitle tracks in the library API.
- Build a browser-local Wasm demo that runs core QC without uploading files.

Creator capabilities:

- Run publishing preflight checks for Douyin, Bilibili, YouTube, bilingual, and
  similar creator profiles.
- Report text issues as gentle Warning / Info diagnostics by default.
- Opt in to Chinese-English text style checks for mixed punctuation, repeated
  punctuation, paired punctuation, long unbroken text blocks, isolated
  single-character lines, and small terminology dictionaries.
- Normalize subtitle punctuation between half-width and full-width styles for
  AI-generated and spoken-content subtitles.
- Use `creator check` and `creator clean` for pre-publish checks and safe
  format cleanup.

Delivery capabilities:

- Run stricter subtitle delivery QC for film, OTT, cinema, and broadcast
  profiles.
- Check overlaps, invalid durations, empty cue text, duration limits, line
  length, line count, reading speed, frame alignment, and minimum cue gaps.
- Emit JSON reports and support `--fail-on-error` for automated delivery gates.
- Use `delivery check` for directory-level package preflight and
  `delivery subtitle-check` for single subtitle files, covering package assets,
  manifest, metadata, checksum, and subtitle issues.

## Two Production Lines

| Line | Goal | Default posture | Typical entry points |
| --- | --- | --- | --- |
| Creator | Subtitle cleanup before self-media, short-form, spoken-content, and AI-caption publishing | Gentle hints, safe cleanup, no default hard failure | `creator check`, `creator clean` |
| Delivery | Film, OTT, broadcast, and localization subtitle delivery validation | Strict QC, Error diagnostics can fail automation | `delivery check`, `delivery subtitle-check` |

## Use Cases

Creator workflows:

- Clean AI-generated, spoken-content, and short-form subtitles before upload.
- Check Chinese-English mixing, punctuation style, repeated punctuation, paired
  punctuation, and isolated single-character lines.
- Normalize half-width/full-width punctuation without changing meaning.
- Check line length, reading speed, and visual density against platform habits.

Delivery workflows:

- Check SRT/WebVTT subtitles for overlaps, duration, line length, line count,
  and reading speed before delivery.
- Validate frame-rate assumptions, frame-grid alignment, and minimum cue gaps.
- Shift subtitles, convert frame-rate assumptions, or snap cue timing after
  edits and version changes.
- Emit JSON reports and use `--fail-on-error` in automated delivery workflows.

Shared workflows:

- Convert SRT/WebVTT files and run basic QC in creator and localization flows.
- Run browser-local core QC through the Wasm demo without uploading subtitle
  text.

## Intended Users

MoonPost is primarily for users who directly handle subtitle files,
pre-publish checks, and delivery validation.

| User | How MoonPost helps |
| --- | --- |
| Creators and publishers | Checks AI captions, spoken-content subtitles, punctuation, line length, reading speed, and platform-specific subtitle habits before upload. |
| Editors and subtitle editors | Finds overlaps, empty cues, long lines, short durations, and reading-speed issues before publishing or handoff. |
| Localization teams | Runs repeatable SRT/WebVTT checks and bilingual subtitle workflows during translation, review, and handoff. |
| Post-production and media QA | Checks timecode, frame grids, cue gaps, and readable QC reports. |
| Delivery engineers and platform operators | Uses JSON reports and failure exit codes to integrate subtitle QC into batch or CI workflows. |

## Requirements

- MoonBit toolchain.
- A shell environment for running `moon` commands.
- Python 3 only if you want to serve the local Wasm demo with the example
  command below.

This repository is tested with the current local MoonBit toolchain used during
development:

```text
moon 0.1.20260512
moonc v0.9.2
```

## Quick Start

Clone the repository and run the test suite:

```bash
moon test --target native
moon test --target wasm-gc
```

Run the CLI from source:

```bash
moon run cmd/main --target native -- --help
```

The source-run prefix is:

```bash
moon run cmd/main --target native --
```

The examples below use that prefix. If the command is packaged as a standalone
binary later, replace the prefix with `moonpost`.

### Creator / Delivery Examples

```bash
moon run cmd/main --target native -- creator check examples/bilingual.srt --profile bilingual
moon run cmd/main --target native -- creator clean examples/good.srt --profile douyin -o fixed.srt
moon run cmd/main --target native -- delivery check examples/delivery-package/good --json
moon run cmd/main --target native -- delivery subtitle-check examples/bad.srt --profile ott-zh --fps 25
```

Choose a `creator clean` profile that matches the language and platform
conventions of the source; the `douyin` command above is illustrative.

Use the built native executable when relying on `--fail-on-error` exit codes.

### Delivery First-Phase Target

The first stable Delivery line is now the directory-level
`delivery check <folder>` preflight:

```bash
moon run cmd/main --target native -- delivery check examples/delivery-package/good --json
moon run cmd/main --target native -- delivery check examples/delivery-package/bad --profile distribution --subtitle-profile ott-zh --fps 25
```

`delivery check` scans the first level of a delivery folder, classifies video,
subtitle, poster, metadata, checksum, and `moonpost.delivery.json` assets,
checks package-profile and manifest requirements, validates required subtitle
languages, and runs subtitle QC for SRT/WebVTT files in the folder.

Single subtitle files can still be checked directly:

```bash
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/ott-good.srt --profile ott-zh --json
moon build cmd/main --target native
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check examples/delivery/ott-bad.srt --profile ott-zh --fps 25 --fail-on-error
```

`--fail-on-error` is suitable for automation; use `--fail-on-warning` when
Warning diagnostics should also block delivery. Use the built native executable
when relying on process exit codes.

## CLI Overview

```text
MoonPost - subtitle, timecode and post-production QC toolkit

Usage:
  moonpost <command> [options]

Commands:
  creator     Check and clean creator-platform subtitle files with gentle hints
  delivery    Run strict delivery-profile subtitle checks
  subtitle    Convert subtitle formats
  timecode    Convert SMPTE-style timecode and frame counts
  retime      Shift, speed-convert, or snap subtitle timing
  merge       Merge two subtitle tracks into bilingual cues
  split-bilingual
              Split bilingual cues into two subtitle tracks
  qc          Compatibility alias for subtitle delivery QC
```

## Subtitle QC

Run QC on an SRT or WebVTT file:

```bash
moon run cmd/main --target native -- qc examples/bad.srt --fps 25 --profile streaming
```

Emit a JSON report:

```bash
moon run cmd/main --target native -- qc examples/good.srt --json
```

Opt in to Chinese-English text style checks:

```bash
moon run cmd/main --target native -- qc examples/good.srt --text-style bilingual
```

`--text-style` is disabled by default, so regular `qc` output is unchanged.
Available values are `bilingual`, `zh`, and `en`.

After building the native CLI, `--fail-on-error` returns a non-zero exit code
when Error-level issues are found:

```bash
moon build cmd/main --target native
_build/native/debug/build/cmd/main/main.exe qc examples/bad.srt --fail-on-error
```

Example report:

```text
examples/bad.srt
summary: 3 errors, 7 warnings

WARN W201 cue#1 | duration 377ms below minimum 800ms
WARN W310 cue#1 | 225 cps exceeds max 20
WARN W203 cue#1 | line 1: 85 chars, max 42
WARN W401 cue#1 | cue timing is not aligned to 40ms frame grid
WARN W202 cue#2 | duration 7600ms above maximum 7000ms
WARN W203 cue#2 | line 1: 49 chars, max 42
ERROR E102 cue#3 | end time must be after start time
ERROR E201 cue#3 | empty cue text
WARN W401 cue#3 | cue timing is not aligned to 40ms frame grid
ERROR E101 cue#1 | overlaps cue#2 by 100ms
```

### QC Profiles

Profiles provide practical defaults for different delivery contexts.

| Profile | Max CPL | Max CPS | Max lines | Min duration | Max duration | Min gap | Frame grid |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `default` | 42 | 20 | 2 | 800ms | 7000ms | 2 frames | none |
| `streaming` | 42 | 20 | 2 | 800ms | 7000ms | 2 frames | 25fps |
| `cinema` | 32 | 17 | 2 | 1000ms | 6000ms | 2 frames | 24fps |
| `social-video` | 30 | 24 | 2 | 500ms | 5000ms | 1 frame | 30fps |

The CLI also accepts `--fps <rate>` to override the profile frame grid for a QC
run.

### QC Rule Codes

| Code | Severity | Meaning |
| --- | --- | --- |
| `E101` | Error | Cue overlaps the next cue. |
| `E102` | Error | Cue end time is not after start time. |
| `E201` | Error | Cue text is empty. |
| `W201` | Warning | Cue duration is shorter than the active profile allows. |
| `W202` | Warning | Cue duration is longer than the active profile allows. |
| `W203` | Warning | A text line exceeds the active CPL limit. |
| `W204` | Warning | Cue has more lines than the active profile allows. |
| `W310` | Warning | Reading speed exceeds the active CPS limit. |
| `W401` | Warning | Cue timing is not aligned to the active frame grid. |
| `W402` | Warning | Gap to the next cue is below the active frame-gap limit. |
| `W501` | Warning | Opt-in text style check found mixed punctuation style. |
| `W502` | Warning | Opt-in text style check found repeated punctuation. |
| `W503` | Warning | Opt-in text style check found suspicious paired punctuation. |
| `W510` | Warning | Opt-in text style check found a long unbroken text block. |
| `W511` | Warning | Opt-in text style check found an isolated single-character line. |
| `W520` | Warning | Opt-in text style check found a dictionary typo or terminology issue. |

## Timecode

Convert a SMPTE-style timecode value to frames:

```bash
moon run cmd/main --target native -- timecode to-frames 01:00:00:00 --fps 25
```

Output:

```text
01:00:00:00 @25fps = 90000 frames
```

Convert a frame count back to timecode:

```bash
moon run cmd/main --target native -- timecode from-frames 90000 --fps 25
```

Output:

```text
90000 frames @25fps = 01:00:00:00
```

Convert a timecode between frame-rate assumptions:

```bash
moon run cmd/main --target native -- timecode convert 01:00:00:00 --from 23.976 --to 25
```

Output:

```text
01:00:00:00 @23.976fps = 00:00:24:12 @25fps
```

Supported CLI frame-rate values:

| Value | Meaning |
| --- | --- |
| `23.976`, `23976` | 23.976fps |
| `24` | 24fps |
| `25` | 25fps |
| `29.97`, `2997` | 29.97 non-drop |
| `29.97df`, `29.97DF`, `29.97-drop`, `2997df` | 29.97 drop-frame |
| `30` | 30fps |
| `50` | 50fps |
| `59.94`, `5994` | 59.94 non-drop |
| `59.94df`, `59.94DF`, `59.94-drop`, `5994df` | 59.94 drop-frame |

## Subtitle Conversion

Convert SRT to WebVTT:

```bash
moon run cmd/main --target native -- subtitle convert examples/good.srt --to webvtt
```

Write converted output to a file:

```bash
moon run cmd/main --target native -- subtitle convert examples/good.srt --to webvtt -o output.vtt
```

Convert WebVTT to SRT:

```bash
moon run cmd/main --target native -- subtitle convert examples/good.vtt --to srt -o output.srt
```

Normalize half-width/full-width punctuation:

```bash
moon run cmd/main --target native -- subtitle normalize examples/good.srt --punctuation bilingual -o fixed.srt
```

`--punctuation` accepts `bilingual`, `zh`, and `en`. This command only rewrites
common punctuation in cue text; it does not replace words, reflow subtitle
lines, or change timing.

Implemented parser behavior:

- SRT cues may include numeric cue indexes.
- SRT cues without numeric indexes are accepted.
- WebVTT files must include a `WEBVTT` header.
- WebVTT cue identifiers are preserved.
- WebVTT cue settings are preserved when writing WebVTT.
- WebVTT `NOTE`, `STYLE`, and `REGION` metadata blocks are skipped by the
  parser.
- UTF-8 BOM at the start of a subtitle file is tolerated.
- CRLF line endings are tolerated.

## Retime

Shift all cues by an offset:

```bash
moon run cmd/main --target native -- retime examples/good.srt --offset +1200ms
```

Output:

```text
1
00:00:02,200 --> 00:00:04,400
Hello, welcome to MoonBit.

2
00:00:05,200 --> 00:00:06,700
This subtitle is ready for QC.
```

Write retimed output to a file:

```bash
moon run cmd/main --target native -- retime examples/good.srt --offset -500ms -o shifted.srt
```

Convert cue timing between frame-rate assumptions:

```bash
moon run cmd/main --target native -- retime examples/good.srt --from-fps 23.976 --to-fps 25 -o converted.srt
```

Snap cue timing to a frame grid:

```bash
moon run cmd/main --target native -- retime examples/good.srt --snap-fps 25 -o snapped.srt
```

## Browser-Local Wasm Demo

MoonPost includes a small browser demo for local subtitle QC. The demo loads
the MoonBit `wasm-gc` build and runs QC in the browser. Subtitle text stays in
the local browser session.

Build the Wasm asset:

```bash
./wasm-demo/build.sh
```

Serve the demo:

```bash
python3 -m http.server 8765 --directory wasm-demo/public
```

Open:

```text
http://localhost:8765
```

The demo expects a browser with WebAssembly GC and JS string builtins support.

## Library Packages

MoonPost is organized as small MoonBit packages. Public APIs are summarized by
the generated `pkg.generated.mbti` files.

| Package | Purpose |
| --- | --- |
| `phenom8010/moonpost/timecode` | Frame rates, timecode parsing, frame conversion, drop-frame math. |
| `phenom8010/moonpost/subtitle` | SRT/WebVTT parsing, timestamp formatting, subtitle writing. |
| `phenom8010/moonpost/qc` | QC profiles, issue model, cue checks, report formatting. |
| `phenom8010/moonpost/creator` | Creator subtitle profiles, text checks, and cleanup workflows. |
| `phenom8010/moonpost/retime` | Offset, frame-rate conversion, frame snapping for cues. |
| `phenom8010/moonpost/align` | Bilingual merge and split helpers. |
| `phenom8010/moonpost/cli` | CLI argument parser. |
| `phenom8010/moonpost/wasm_demo/core` | Wasm-exported `qc_subtitle` entry point for the demo. |

### Core Public APIs

Timecode:

```text
parse_timecode(String, FrameRate) -> Timecode?
Timecode::to_frames() -> Int
Timecode::format() -> String
FrameRate::frames_to_timecode(Int) -> Timecode
convert_timecode(Timecode, FrameRate) -> Timecode
rescale_ms_between_rates(Int, FrameRate, FrameRate) -> Int
```

Subtitle:

```text
parse_srt(String) -> SubtitleTrack?
parse_srt_detailed(String) -> Result[SubtitleTrack, ParseError]
parse_webvtt(String) -> SubtitleTrack?
parse_webvtt_detailed(String) -> Result[SubtitleTrack, ParseError]
write_srt(SubtitleTrack) -> String
write_webvtt(SubtitleTrack) -> String
parse_timestamp_ms(String) -> Int?
format_srt_timestamp(Int) -> String
format_vtt_timestamp(Int) -> String
```

QC:

```text
default_profile() -> QcProfile
streaming_profile() -> QcProfile
cinema_profile() -> QcProfile
social_video_profile() -> QcProfile
profile_by_name(String) -> QcProfile?
check_cues(Array[Cue], QcProfile) -> Array[QcIssue]
format_report(String, Array[QcIssue]) -> Array[String]
format_json_report(String, Array[QcIssue]) -> String
has_errors(Array[QcIssue]) -> Bool
```

Retime:

```text
offset_cues(Array[Cue], Int) -> Array[Cue]
convert_fps_cues(Array[Cue], FrameRate, FrameRate) -> Array[Cue]
snap_cues_to_frames(Array[Cue], FrameRate) -> Array[Cue]
```

Align:

```text
merge_bilingual(Array[Cue], Array[Cue], tolerance_ms~ : Int) -> Array[Cue]
split_bilingual(Array[Cue]) -> BilingualSplit
```

Wasm demo core:

```text
qc_subtitle(String, String) -> String
```

## Repository Layout

See [`docs/project-structure.md`](docs/project-structure.md) for the detailed
directory map.

```text
moonpost/
├── timecode/        SMPTE-style timecode and frame-rate helpers
├── subtitle/        SRT/WebVTT parser, timestamp, and writer
├── qc/              Subtitle QC, reports, text style, and punctuation normalization
├── retime/          Offset, frame-rate conversion, and frame snapping
├── align/           Bilingual subtitle merge/split helpers
├── delivery/        Single-episode delivery preflight models and manifest parsing
├── cli/             CLI argument model and parser
├── cmd/main/        Native CLI entry point and filesystem I/O
├── wasm_demo/core/  MoonBit Wasm export package
├── wasm-demo/       Browser demo shell, build script, and static assets
├── examples/        Sample subtitle files
├── docs/            Project structure, design docs, and implementation plans
└── .github/         CI workflow
```

## CI

This repository includes a GitHub Actions workflow at
[`.github/workflows/ci.yml`](.github/workflows/ci.yml). It runs on push, pull
request, and manual dispatch.

CI covers:

- Run `moon fmt` and fail if formatting produces an uncommitted diff.
- Run `moon info` and fail if generated package interfaces are out of sync.
- Run `moon check --target native` and `moon check --target wasm-gc`.
- Run `moon build --target native` and `moon build --target wasm-gc`.
- Run `moon test --target native` and `moon test --target wasm-gc`.
- Build the Wasm demo release asset and verify `wasm-demo/public/moonpost_qc.wasm`.
- Run CLI smoke tests for timecode, subtitle conversion, and QC reports.

## Development

Run all native tests:

```bash
moon test --target native
```

Run Wasm-GC compatible tests:

```bash
moon test --target wasm-gc
```

Check native and Wasm-GC targets:

```bash
moon check --target native
moon check --target wasm-gc
```

Format source:

```bash
moon fmt
```

Regenerate public interface summaries:

```bash
moon info
```

Build the Wasm demo core:

```bash
moon build wasm_demo/core --target wasm-gc --release
```

## License

Apache-2.0. See [LICENSE](LICENSE).
