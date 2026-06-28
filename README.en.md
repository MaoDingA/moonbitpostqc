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
  <img alt="formats SRT + WebVTT + ASS" src="https://img.shields.io/badge/formats-SRT%20%2B%20WebVTT%20%2B%20ASS-f97316?style=flat-square">
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

Both lines share the same SRT/WebVTT/ASS parser, QC rule engine, timecode helpers,
and report formatter. The shared core stays neutral; platform habits and
delivery requirements are expressed through Creator and Delivery profiles.

MoonPost does not decode video, transcode media, or wrap FFmpeg. Its scope is
the post-production infrastructure layer that can be implemented
deterministically in MoonBit: parsers, data models, QC rules, reports, CLI
tools, and Wasm-ready core packages.

MoonPost is an **original MoonBit project**, not a port or rewrite of any
specific third-party library. The industry standards it follows (SMPTE
timecode, SRT/WebVTT/ASS subtitle formats, Netflix TTSG, China NRTA
GY/T 357-2024, etc.) are all public specifications and involve no
third-party source porting. If future work references or ports another
open-source project, the source, license, and scope will be documented.

### Repository & contest status

| Item | Status |
|---|---|
| GitHub repo | [MaoDingA/moonbitpostqc](https://github.com/MaoDingA/moonbitpostqc) |
| GitLink repo | synced with GitHub |
| Project proposal | submitted (2026 MoonBit Open-Source Competition) |
| mooncakes.io | [`moon add MaoDingA/moonpost`](https://mooncakes.io/MaoDingA/moonpost) |
| Local demo | `./wasm-demo/build.sh && python3 -m http.server 8765 -d wasm-demo/public` |
| User experience guide | [user-experience/README.md](user-experience/README.md) |

## Features

Shared foundation:

- Parse and write SRT / WebVTT / ASS subtitle files and convert between them.
- Parse and format SMPTE-style timecode, including precise conversion between
  timecode labels, frame counts, durations, and common frame rates.
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
  manifest, metadata, SHA-256 checksum, and subtitle issues.

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

- Check SRT/WebVTT/ASS subtitles for overlaps, duration, line length, line count,
  and reading speed before delivery.
- Validate frame-rate assumptions, frame-grid alignment, and minimum cue gaps.
- Shift subtitles, convert frame-rate assumptions, or snap cue timing after
  edits and version changes.
- Emit JSON reports and use `--fail-on-error` in automated delivery workflows.

Shared workflows:

- Convert SRT/WebVTT/ASS files and run basic QC in creator and localization flows.
- Run browser-local core QC through the Wasm demo without uploading subtitle
  text.

## Intended Users

MoonPost is primarily for users who directly handle subtitle files,
pre-publish checks, and delivery validation.

| User | How MoonPost helps |
| --- | --- |
| Creators and publishers | Checks AI captions, spoken-content subtitles, punctuation, line length, reading speed, and platform-specific subtitle habits before upload. |
| Editors and subtitle editors | Finds overlaps, empty cues, long lines, short durations, and reading-speed issues before publishing or handoff. |
| Localization teams | Runs repeatable SRT/WebVTT/ASS checks and bilingual subtitle workflows during translation, review, and handoff. |
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

## Installation

MoonPost is published on [mooncakes.io](https://mooncakes.io/MaoDingA/moonpost) and can be used as a dependency in any MoonBit project:

```bash
moon add MaoDingA/moonpost
```

After installation, import the sub-packages you need:

```moonbit
// Subtitle parsing and writing
let track = parse_srt(input)
// Timecode and frame rates
let tc = parse_timecode("01:00:00:00", FrameRate::fps_25())
// QC checks
let issues = check_cues(track.cues, default_profile())
```

Available sub-packages: `MaoDingA/moonpost/subtitle`, `MaoDingA/moonpost/timecode`, `MaoDingA/moonpost/qc`, `MaoDingA/moonpost/creator`, `MaoDingA/moonpost/delivery`, `MaoDingA/moonpost/dcp`, `MaoDingA/moonpost/retime`, and `MaoDingA/moonpost/align`. See the "Core Public API" section for the full API reference and [API_STABILITY.md](API_STABILITY.md) for stability boundaries.

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

### Five-Minute User Path

```bash
moon build cmd/main --target native
./scripts/e2e-acceptance.sh
_build/native/debug/build/cmd/main/main.exe subtitle convert examples/good.srt --to ass
_build/native/debug/build/cmd/main/main.exe creator clean examples/creator/ai-clean-bad.srt --verbose
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check examples/bad.srt --profile nrta --fail-on-warning
```

This path covers format conversion, AI-caption cleanup, China long-form delivery
profiles, and the complete e2e user workflow suite. For a browser pass, run
`./wasm-demo/build.sh` and open the local demo.

### Creator / Delivery Examples

```bash
moon run cmd/main --target native -- creator check examples/bilingual.srt --profile bilingual
moon run cmd/main --target native -- creator clean examples/good.srt --profile douyin -o fixed.srt
moon run cmd/main --target native -- delivery check examples/delivery-package/good --json
moon run cmd/main --target native -- delivery subtitle-check examples/bad.srt --profile ott-zh --fps 25
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-source-srt --fail-on-warning
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-frame-strict --fail-on-warning
```

Choose a `creator clean` profile that matches the language and platform
conventions of the source; the `douyin` command above is illustrative.

Use the built native executable when relying on `--fail-on-error` exit codes.

### Delivery First-Phase Target

The first stable Delivery line is now the directory-level
`delivery check <folder>` preflight:

```bash
moon run cmd/main --target native -- delivery check examples/delivery-package/good --json
moon run cmd/main --target native -- delivery check examples/delivery-package/checksum-bad --fail-on-error
moon run cmd/main --target native -- delivery check examples/delivery-package/bad --profile distribution --subtitle-profile ott-zh --fps 25
moon run cmd/main --target native -- delivery check examples/delivery-package/srt-source-bad --profile distribution --subtitle-profile dcp-source-srt --fail-on-warning
moon run cmd/main --target native -- delivery check examples/delivery-package/srt-source-bad --profile distribution --subtitle-profile dcp-frame-strict --fail-on-warning
```

`delivery check` scans the first level of a delivery folder, classifies video,
subtitle, poster, metadata, checksum, and `moonpost.delivery.json` assets,
checks package-profile and manifest requirements, validates required subtitle
languages, verifies SHA-256 entries from `checksum.txt`, `checksums.txt`, or
`SHA256SUMS`, and runs subtitle QC for SRT/WebVTT/ASS files in the folder. Checksum
files currently support standard `sha256sum`-style `<64hex>  filename` and
`<64hex> *filename` lines; paths that escape the delivery folder are rejected.

Single subtitle files can still be checked directly:

```bash
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/ott-good.srt --profile ott-zh --json
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/srt-basic-good.srt --profile srt-basic --fail-on-error
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-source-srt --fail-on-warning
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-frame-strict --fail-on-warning
moon build cmd/main --target native
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check examples/delivery/ott-bad.srt --profile ott-zh --fps 25 --fail-on-error
```

`--fail-on-error` is suitable for automation; use `--fail-on-warning` when
Warning diagnostics should also block delivery. Use the built native executable
when relying on process exit codes.

Delivery subtitle profiles currently include `ott-zh`, `cinema-zh`,
`broadcast`, `srt-basic`, `dcp-source-srt`, and `dcp-frame-strict`.

| Profile | Use case | Duration/readability | Frame grid |
| --- | --- | --- | --- |
| `srt-basic` | Plain SRT source preflight for format, indexes, WebVTT settings leakage, and style-markup conversion risks. | 500ms to 7000ms, 42 CPL / 20 CPS. | Off by default. |
| `dcp-source-srt` | SRT source-risk preflight before DCP creation, including early first-subtitle risk. | 500ms to 6000ms, 32 CPL / 17 CPS. | Off by default, so W401/W402 are not reported. |
| `dcp-frame-strict` | Explicit final-prep check for DCP frame grid and minimum gap compliance. | 1000ms to 6000ms, 32 CPL / 17 CPS. | 24fps, minimum 2-frame gap. |

The boundary is intentional: these profiles validate SRT text source files.
They are not DCP XML/MXF Timed Text validators, IMF IMSC validators, embedded
subtitle stream analyzers, or burn-in render checks. Font, size, safe area, and
actual rendered position must be verified in the target container, DCP/IMF
package, or video frame output.

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
  explain     Explain a QC diagnostic code
  profile     List or show profile configurations
```

### Creator AI Clean Example

```bash
moon run cmd/main --target native -- creator check examples/creator/ai-clean-bad.srt --profile douyin
```

### Explain and Profile Commands

```bash
moon run cmd/main --target native -- explain C601
moon run cmd/main --target native -- explain E101
moon run cmd/main --target native -- profile list
moon run cmd/main --target native -- profile show creator --name douyin
moon run cmd/main --target native -- profile show delivery --name ott-zh
```

CI integration examples: [`examples/ci-integration.md`](examples/ci-integration.md).

## Subtitle QC

Run QC on an SRT, WebVTT or ASS file:

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
| `W100` | Warning | An SRT source profile received WebVTT input. |
| `W101` | Warning | SRT cue is missing its numeric index. |
| `W102` | Warning | SRT cue indexes are not sequential. |
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
| `W601` | Warning | Source SRT contains font or color markup that may not survive conversion. |
| `W602` | Warning | Source SRT contains ASS/SSA style overrides that may not survive conversion. |
| `W603` | Warning | SRT timing line contains WebVTT-style settings. |
| `W701` | Warning | DCP-source SRT first cue starts too close to program start. |

## Timecode

`MaoDingA/moonpost/timecode` is MoonPost's reusable SMPTE timecode foundation.
It models timecode labels, frame counts, durations, and half-open timecode
ranges separately, with drop-frame boundary handling, same-rate arithmetic,
explicit comparison, and exact numerator/denominator based conversion for
23.976 / 29.97 / 59.94 rates. It also provides 24-hour wrap policy, rational
seconds, ST 12 logical word/user bits/packed LTC bytes for 24h labels at
nominal rates up to 30fps, and lightweight helpers for FCPXML, IMF, Apple
delivery-package, and EDL timecode metadata fields.
Package-level checked examples live in `timecode/README.mbt.md`.

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
01:00:00:00 @23.976fps = 01:00:03:15 @25fps
```

Emit exact IMF composition-style edit-rate timecode fields:

```bash
moon run cmd/main --target native -- timecode imf-from '01:00:00;00' --fps 29.97df
```

Output:

```text
01:00:00;00 @29.97df = editRate 30000/1001 timecodeRate 30 dropFrame true startAddress 01:00:00:00
```

Normalize a compact CMX-style EDL event line:

```bash
moon run cmd/main --target native -- timecode edl-event '001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00' --fps 25
```

Output:

```text
001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
```

Supported CLI frame-rate values:

| Value | Meaning |
| --- | --- |
| `23.976`, `23.98`, `23976`, `2398` | 23.976fps |
| `24` | 24fps |
| `25` | 25fps |
| `47.952`, `47.95`, `47952`, `4795` | 47.952fps |
| `48` | 48fps |
| `29.97`, `29.97ndf`, `2997`, `2997ndf` | 29.97 non-drop |
| `29.97df`, `29.97DF`, `29.97-drop`, `29.97 drop`, `2997df`, `2997drop` | 29.97 drop-frame |
| `30` | 30fps |
| `50` | 50fps |
| `59.94`, `59.94ndf`, `5994`, `5994ndf` | 59.94 non-drop |
| `59.94df`, `59.94DF`, `59.94-drop`, `59.94 drop`, `5994df`, `5994drop` | 59.94 drop-frame |
| `60` | 60fps |
| `72` | 72fps |
| `96` | 96fps |
| `100` | 100fps |
| `119.88`, `11988` | 119.88fps |
| `120` | 120fps |

The library API also exposes `Duration`, `Timecode::add_frames`,
`Timecode::frame_distance`, `Timecode::add_duration`, `TimecodeRange`, and
`parse_timecode_result`. Cross-rate comparison, range, and duration arithmetic
return `None` instead of silently converting. FCPXML, IMF, and Apple delivery
and EDL helpers cover timecode metadata fields, not complete file parsing.

## Subtitle Conversion

MoonPost supports conversion between SRT, WebVTT and ASS (Advanced SubStation Alpha) formats.

Convert SRT to WebVTT:

```bash
moon run cmd/main --target native -- subtitle convert examples/good.srt --to webvtt
```

Convert SRT to ASS:

```bash
moon run cmd/main --target native -- subtitle convert examples/good.srt --to ass -o output.ass
```

Convert ASS to SRT (automatically strips override tags and `\N` line breaks):

```bash
moon run cmd/main --target native -- subtitle convert examples/anime.ass --to srt -o output.srt
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

## Browser Wasm Demo (local)

MoonPost includes a browser demo for subtitle QC. The demo loads the MoonBit
`wasm-gc` build and runs QC in the browser. Subtitle text stays in the local
browser session and is never uploaded.

> Requires a browser with WebAssembly GC support (Chrome 119+ / Firefox 120+ / Edge 119+)

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
| `MaoDingA/moonpost/timecode` | Frame rates, timecode parsing, frame/duration/range conversion, same-rate arithmetic, drop-frame math. |
| `MaoDingA/moonpost/subtitle` | SRT/WebVTT/ASS parsing, timestamp formatting, subtitle writing. |
| `MaoDingA/moonpost/qc` | QC profiles, issue model, cue checks, report formatting. |
| `MaoDingA/moonpost/creator` | Creator subtitle profiles, text checks, and cleanup workflows. |
| `MaoDingA/moonpost/delivery` | Delivery folder assets, manifests, checksums, and subtitle profiles. |
| `MaoDingA/moonpost/dcp` | Lightweight DCP AssetMap, PKL, CPL models and consistency checks. |
| `MaoDingA/moonpost/retime` | Offset, frame-rate conversion, frame snapping for cues. |
| `MaoDingA/moonpost/align` | Bilingual merge and split helpers. |
| `MaoDingA/moonpost/cli` | CLI argument parser. |
| `MaoDingA/moonpost/wasm_demo/core` | Wasm-exported `qc_subtitle` entry point for the demo. |

### Core Public APIs

Timecode:

```text
parse_timecode(String, FrameRate) -> Timecode?
parse_timecode_result(String, FrameRate) -> Result[Timecode, TimecodeParseError]
parse_timecode_with_policy(String, FrameRate, TimecodeParsePolicy) -> Result[Timecode, TimecodeParseError]
Timecode::to_frames() -> Int
Timecode::format() -> String
Timecode::add_frames(Int) -> Timecode
Timecode::sub_frames(Int) -> Timecode
Timecode::add_duration(Duration) -> Timecode?
Timecode::sub_duration(Duration) -> Timecode?
Timecode::frame_distance(Timecode) -> Int?
Timecode::is_before(Timecode) -> Bool?
Timecode::is_after(Timecode) -> Bool?
FrameRate::frames_to_timecode(Int) -> Timecode
FrameRate::frames_to_timecode_with_wrap(Int, TimecodeWrapMode) -> Timecode
FrameRate::parse(String) -> FrameRate?
FrameRate::label() -> String
FrameRate::nominal_fps() -> Int
FrameRate::fps_numerator() -> Int
FrameRate::fps_denominator() -> Int
convert_timecode(Timecode, FrameRate) -> Timecode
rescale_ms_between_rates(Int, FrameRate, FrameRate) -> Int
Duration::from_frames(Int, FrameRate) -> Duration
Duration::from_ms(Int, FrameRate) -> Duration
Duration::to_frames() -> Int
Duration::to_ms() -> Int
Duration::format() -> String
Duration::add(Duration) -> Duration?
Duration::sub(Duration) -> Duration?
Duration::scale(Int) -> Duration
TimecodeRange::new(Timecode, Timecode) -> TimecodeRange?
TimecodeRange::duration() -> Duration?
TimecodeRange::contains(Timecode) -> Bool?
TimecodeRange::overlaps(TimecodeRange) -> Bool?
TimecodeRange::shift(Duration) -> TimecodeRange?
RationalSeconds::parse(String) -> RationalSeconds?
RationalSeconds::format() -> String
RationalSeconds::to_frames(FrameRate) -> Int
RationalSeconds::from_frames(Int, FrameRate) -> RationalSeconds
FcpXmlTimecodeAttrs::to_timecode() -> Result[Timecode, TimecodeInteropError]
FcpXmlTimecodeAttrs::from_timecode(Timecode) -> FcpXmlTimecodeAttrs
ImfTimecode::to_timecode() -> Result[Timecode, TimecodeInteropError]
ImfTimecode::from_timecode(Timecode) -> ImfTimecode
ImfEditRate::from_frame_rate(FrameRate) -> ImfEditRate
ImfEditRate::to_frame_rate(Bool) -> Result[FrameRate, TimecodeInteropError]
ImfCompositionTimecode::to_timecode() -> Result[Timecode, TimecodeInteropError]
ImfCompositionTimecode::from_timecode(Timecode) -> ImfCompositionTimecode
SmpteUserBits::from_hex(String) -> Result[SmpteUserBits, TimecodeInteropError]
SmpteUserBits::format_hex() -> String
SmpteTimecodeWord::from_timecode(Timecode) -> SmpteTimecodeWord
SmpteTimecodeWord::to_timecode() -> Result[Timecode, TimecodeInteropError]
SmpteTimecodeWord::pack_ltc_bytes() -> Result[Bytes, TimecodeInteropError]
SmpteTimecodeWord::unpack_ltc_bytes(Bytes, FrameRate) -> Result[SmpteTimecodeWord, TimecodeInteropError]
EdlEvent::parse(String, FrameRate) -> Result[EdlEvent, TimecodeInteropError]
EdlEvent::format() -> String
AppleDeliveryTimecodeFormat::parse(String) -> FrameRate?
AppleDeliveryTimecodeFormat::format(FrameRate) -> String?
AppleDeliveryTimecodeFormat::supported_rates() -> Array[FrameRate]
AppleDeliveryTimecodeFormat::is_supported(FrameRate) -> Bool
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
check_srt_source_track(SubtitleTrack, SrtSourcePolicy) -> Array[QcIssue]
srt_basic_source_policy() -> SrtSourcePolicy
dcp_source_srt_policy() -> SrtSourcePolicy
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

DCP:

```text
parse_asset_map(String) -> Result[Array[DcpAsset], DcpParseError]
parse_packing_list(String) -> Result[Array[DcpAsset], DcpParseError]
parse_composition_playlist(String) -> Result[DcpComposition, DcpParseError]
check_dcp_package(DcpPackage) -> Array[DcpIssue]
has_dcp_errors(Array[DcpIssue]) -> Bool
classify_dcp_path(String) -> DcpAssetKind
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
├── subtitle/        SRT/WebVTT/ASS parser, timestamp, and writer
├── qc/              Subtitle QC, reports, text style, and punctuation normalization
├── retime/          Offset, frame-rate conversion, and frame snapping
├── align/           Bilingual subtitle merge/split helpers
├── delivery/        Single-episode delivery preflight models and manifest parsing
├── dcp/             Lightweight DCP AssetMap, PKL, CPL parsing and checks
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
