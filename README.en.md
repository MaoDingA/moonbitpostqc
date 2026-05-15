# MoonPost

<p align="right">
English | <a href="README.md">简体中文</a>
</p>

<p align="left">
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
quality control.

It is designed for text-based media delivery work: checking SRT/WebVTT subtitle
files, converting subtitle formats, calculating SMPTE-style timecode, retiming
cues, and running the same core logic from a native CLI or a browser-local
WebAssembly demo.

MoonPost does not decode video, transcode media, or wrap FFmpeg. Its scope is
the post-production infrastructure layer that can be implemented
deterministically in MoonBit: parsers, data models, QC rules, reports, CLI
tools, and Wasm-ready core packages.

## Features

- Parse and write SRT subtitle files.
- Parse and write WebVTT subtitle files.
- Convert SRT to WebVTT and WebVTT to SRT.
- Parse and format SMPTE-style timecode.
- Convert timecode to frame counts and frame counts to timecode.
- Support common frame rates: `23.976`, `24`, `25`, `29.97`, `29.97df`, `30`,
  `50`, `59.94`, and `59.94df`.
- Run subtitle QC checks for overlap, invalid duration, empty cue text,
  duration limits, line length, line count, reading speed, frame alignment, and
  minimum cue gaps.
- Retime subtitles by offset, frame-rate conversion, or frame snapping.
- Merge and split bilingual subtitle tracks in the library API.
- Build a browser-local Wasm demo that checks subtitles without uploading files.

## Use Cases

MoonPost is useful when a subtitle or post-production workflow needs a small,
repeatable checker before files are delivered or published.

Common workflows:

- Check a subtitle file before delivery to a streaming or publishing platform.
- Convert creator subtitles between SRT and WebVTT.
- Verify that subtitle cues do not overlap.
- Catch very short, very long, empty, or hard-to-read cues.
- Check whether subtitle timing aligns with a target frame grid.
- Shift subtitles after an edit or sync change.
- Convert cue timing between frame-rate assumptions.
- Run QC in a browser without sending subtitle text to a server.

## Intended Users

MoonPost is built for people and teams who work with subtitle text, delivery
checks, and time-based post-production data.

| User | How MoonPost helps |
| --- | --- |
| Subtitle editors | Finds overlaps, empty cues, long lines, short durations, and reading-speed issues before handoff. |
| Localization teams | Provides repeatable SRT/WebVTT checks during translation and review. |
| Post-production assistants | Converts frame counts, validates timecode, and retimes subtitle files after timeline changes. |
| Streaming and media QA teams | Produces consistent human-readable QC reports for delivery review. |
| Creators and publishers | Converts SRT/WebVTT files and catches common subtitle problems before upload. |
| Tool builders | Reuses pure MoonBit parser, QC, retime, and Wasm-ready packages in custom workflows. |
| MoonBit developers | Offers a practical example of text parsing, CLI tooling, tests, and WebAssembly integration. |

## Project Status

MoonPost is currently an early project. The core packages are usable for local
tools and demos, but public APIs may still evolve before a stable release.

Current implemented scope:

| Area | Status |
| --- | --- |
| Timecode | Implemented |
| SRT parser/writer | Implemented |
| WebVTT parser/writer | Implemented |
| Subtitle QC | Implemented |
| CLI | Implemented |
| Retime helpers | Implemented |
| Bilingual merge/split helpers | Implemented in library API |
| Browser Wasm demo | Implemented |
| ASS/SSA | Not implemented |
| TTML/IMSC | Not implemented |
| Media container inspection | Not implemented |

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

## CLI Overview

```text
MoonPost - subtitle, timecode and post-production QC toolkit

Usage:
  moonpost <command> [options]

Commands:
  qc          Check subtitle delivery quality
  timecode    Convert SMPTE-style timecode and frame counts
  subtitle    Convert subtitle formats
  retime      Shift, speed-convert, or snap subtitle timing
```

## Subtitle QC

Run QC on an SRT or WebVTT file:

```bash
moon run cmd/main --target native -- qc examples/bad.srt --fps 25 --profile streaming
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
parse_webvtt(String) -> SubtitleTrack?
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

```text
moonpost/
├── timecode/        SMPTE-style timecode and frame-rate helpers
├── subtitle/        SRT/WebVTT parser and writer
├── qc/              Subtitle delivery QC rules and report formatting
├── retime/          Offset, frame-rate conversion, and frame snapping
├── align/           Bilingual subtitle helpers
├── cli/             Command parser
├── cmd/main/        Native CLI entry point
├── wasm_demo/core/  MoonBit Wasm export package
├── wasm-demo/       Browser demo shell and build script
└── examples/        Sample subtitle files
```

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

## Design Principles

- Keep the core pure MoonBit.
- Prefer deterministic checks over media decoding.
- Keep subtitle text local by default.
- Make CLI output readable by editors, subtitle authors, and developers.
- Keep library packages small enough to reuse independently.
- Treat generated files and local caches as build artifacts, not source.

## Limitations

- ASS/SSA, TTML, and IMSC are not implemented.
- The CLI currently focuses on file-based operations and human-readable output.
- The WebAssembly demo depends on browser support for WebAssembly GC and JS
  string builtins.
- QC profiles are built in; external profile files are not implemented yet.
- The project does not inspect video, audio, MP4, MOV, WAV, or BWF container
  metadata.

## Roadmap

Planned areas for future versions:

- Custom QC profiles from JSON or TOML.
- Machine-readable JSON report output.
- ASS/SSA parser and writer.
- TTML/IMSC subset support.
- CMX3600 EDL parsing.
- BWF/iXML sound metadata inspection.
- Packaged native binary release.
- Published Mooncakes package.

## License

Apache-2.0. See [LICENSE](LICENSE).
