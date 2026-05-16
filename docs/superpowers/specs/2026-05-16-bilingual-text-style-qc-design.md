# Bilingual Text Style QC Design

MoonPost will add an opt-in bilingual text style layer for subtitle QC and a
separate normalization command for punctuation conversion. The feature is aimed
at Chinese-English subtitle delivery workflows while keeping the existing QC
defaults stable.

## Goals

- Detect common bilingual subtitle text style problems without changing files.
- Keep `moonpost qc <file>` behavior unchanged unless a text style option is
  explicitly enabled.
- Reuse the existing `QcIssue` report model so human and JSON reports continue
  to work.
- Provide explicit punctuation normalization commands for half-width/full-width
  conversion.
- Support deterministic dictionary-based typo and terminology warnings without
  claiming semantic spell checking.

## Non-Goals

- Do not add ML or network-based grammar correction.
- Do not auto-fix text during QC.
- Do not make text style warnings affect existing default QC runs.
- Do not require a large external dictionary for the first version.

## CLI Surface

Text style checks are opt-in:

```bash
moonpost qc input.srt --text-style bilingual
moonpost qc input.srt --text-style bilingual --json
```

Punctuation conversion is explicit and writes subtitle text through the normal
subtitle writer path:

```bash
moonpost subtitle normalize input.srt --punctuation bilingual -o fixed.srt
moonpost subtitle normalize input.srt --punctuation zh -o fixed.srt
moonpost subtitle normalize input.srt --punctuation en -o fixed.srt
```

If `--text-style` is omitted, the existing QC result must remain unchanged.

## Architecture

The first version will live inside the existing `qc` package, split into focused
files:

- `qc/text_style.mbt`: bilingual style profile, character classification,
  punctuation checks, block-length checks, dictionary warnings.
- `qc/text_normalize.mbt`: punctuation conversion helpers used by the CLI.
- `qc/checks.mbt`: calls text style checks only when the caller passes an
  enabled text style profile.
- `cli/command.mbt`: parses `--text-style` for QC and `subtitle normalize`.
- `cmd/main/main.mbt`: wires parsed options to QC and normalization.

This keeps reports integrated with the current `QcIssue` model while keeping the
new rules isolated enough to extract into a future package if they grow.

## Text Style Profiles

First version profiles:

- `none`: default. No text style checks.
- `bilingual`: Chinese-English mixed subtitle rules.
- `zh`: Chinese punctuation preference.
- `en`: English ASCII punctuation preference.

The public data model should keep thresholds configurable enough for future
profiles:

- maximum unbroken text block length.
- whether to warn on isolated single-character lines.
- punctuation mode.
- optional dictionary term list.

## QC Rules

New rule codes should be warnings by default:

```text
W501 mixed punctuation style
W502 repeated punctuation
W503 suspicious paired punctuation
W510 long unbroken text block
W511 isolated single-character line
W520 dictionary typo or terminology warning
```

Rule behavior:

- `W501` reports obvious punctuation style mismatches, such as English ASCII
  commas in a mostly Chinese line or full-width Chinese punctuation in a mostly
  English line.
- `W502` reports repeated punctuation runs such as duplicated commas, repeated
  sentence endings, or repeated question/exclamation marks.
- `W503` reports simple pair mismatches for parentheses and quotes, including
  mixed half-width/full-width pairs.
- `W510` reports long continuous blocks with no whitespace or punctuation break.
  This catches long English tokens, URLs accidentally pasted into subtitles, and
  long Chinese strings that should probably be line-broken.
- `W511` reports a line containing only one visible CJK character, because it is
  usually a broken subtitle line rather than intentional text.
- `W520` reports exact dictionary matches such as common typo replacements,
  fixed names, brand capitalization, or project terminology.

## Normalization

Normalization is not a QC side effect. It is a separate command that transforms
subtitle cue text and preserves timing, format, identifiers, and WebVTT settings
as much as the existing writer supports.

Modes:

- `zh`: convert common ASCII punctuation to Chinese full-width punctuation in
  Chinese contexts.
- `en`: convert common full-width punctuation to ASCII punctuation in English
  contexts.
- `bilingual`: infer from nearby characters and convert conservatively. If
  context is ambiguous, keep the original character.

The first version should normalize only punctuation. It should not rewrite words,
apply dictionary replacements, or reflow subtitle lines.

## Dictionary Warnings

Dictionary checks should be deterministic exact-match rules. A future CLI flag
can load a small text or JSON term list, but the first implementation may start
with package-local defaults plus tests.

Each dictionary entry should be able to express:

- the suspicious text.
- the recommended replacement.
- a short reason or category.

Dictionary warnings should not change severity to `Error` in the first version.

## Data Flow

QC flow:

1. CLI parses the subtitle file with the existing parser.
2. Existing timing, duration, line-count, CPL, CPS, and frame rules run.
3. If text style is enabled, the new text style checker scans cue text lines.
4. All issues are returned as `Array[QcIssue]`.
5. Existing human and JSON report formatters render the combined issue list.

Normalize flow:

1. CLI parses the subtitle file with the existing parser.
2. The selected punctuation mode transforms cue text only.
3. The existing subtitle writer emits SRT or WebVTT output.
4. `-o` writes the output file; without output, the command prints to stdout if
   consistent with existing subtitle commands.

## Error Handling

- Unknown `--text-style` values should print help-oriented output and return a
  non-zero exit code before reading the input file.
- Unknown `--punctuation` values should print help-oriented output, return a
  non-zero exit code, and must not write output.
- Parse failures should keep using the existing `E000` parse issue behavior.
- Dictionary loading failures, when external dictionary loading is added, should
  be reported before QC starts.

## Testing

Tests should cover:

- default QC remains unchanged when `--text-style` is omitted.
- `--text-style bilingual` emits `W501`, `W502`, `W503`, `W510`, `W511`, and
  `W520` for focused examples.
- JSON reports include the new warning codes through the existing formatter.
- normalization preserves cue timing and format while changing punctuation.
- `zh`, `en`, and `bilingual` normalization modes behave conservatively.
- existing native and wasm-gc test suites continue to pass.

Validation commands:

```bash
moon fmt
moon info
moon check --target native
moon check --target wasm-gc
moon test --target native
moon test --target wasm-gc
```
