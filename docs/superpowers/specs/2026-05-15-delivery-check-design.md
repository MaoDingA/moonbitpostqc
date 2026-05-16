# Delivery Check Design

MoonPost will add a single-episode delivery package preflight command. The
feature turns the existing subtitle, timecode, QC, and JSON reporting logic into
a real delivery workflow without parsing media containers.

## Scope

First version supports one delivery directory at a time. It may read
`moonpost.delivery.json`, but it will not recursively scan a season folder.
Manifest fields may include `series` and `season` so the schema can grow into
batch season checks later.

## Command

```bash
moonpost delivery check <dir> --profile creator
moonpost delivery check <dir> --profile distribution
moonpost delivery check <dir> --manifest moonpost.delivery.json --json
```

Without a manifest, MoonPost scans the directory and applies profile defaults.
With a manifest, manifest requirements override profile defaults.

## Profiles

`creator` requires one video asset and at least one subtitle. Missing poster and
metadata are warnings. Checksums are ignored.

`distribution` requires video, subtitle, metadata, and checksum assets. Missing
poster is a warning. Checksum content is not validated in version one.

## Assets

Video: `.mp4`, `.mov`, `.mxf`.
Subtitle: `.srt`, `.vtt`.
Poster: `.jpg`, `.jpeg`, `.png`, `.webp`.
Metadata: `.json`, excluding `moonpost.delivery.json`.
Checksum: `checksum.txt`, `checksums.txt`, `SHA256SUMS`.

Subtitle language is inferred from the token before the subtitle extension, for
example `E01.zh-Hans.srt` or `E01.en-US.vtt`.

## Manifest

```json
{
  "series": "Moon Drama",
  "season": "S01",
  "episode": "E01",
  "title": "Episode 1",
  "frame_rate": "25",
  "duration": "00:08:12:00",
  "required_subtitles": ["zh-Hans", "en-US"],
  "required_assets": ["video", "subtitle", "metadata", "checksum"]
}
```

Frame rate and duration are used for subtitle QC and end-bound checks when
present. Unknown or malformed manifest fields produce delivery issues instead
of panics.

## Rules

```text
D101 Error   delivery path does not exist
D102 Error   delivery path is not a directory
D103 Warning delivery directory is empty
D201 Error   missing required video asset
D202 Error   missing required subtitle asset
D203 Error   missing required subtitle language
D204 Warning unrecognized subtitle language token
D301 Error   subtitle parse failed
D302 Warning subtitle has QC warnings
D303 Error   subtitle has QC errors
D304 Error   subtitle end exceeds manifest duration
D401 Warning poster asset missing
D501 Error   metadata file required but missing
D601 Error   checksum file required but missing
```

Human and JSON reports share the same issue model. JSON output is intended for
CI and upload scripts.
