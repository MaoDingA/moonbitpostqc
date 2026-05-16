# Bilingual Text Style QC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add opt-in bilingual subtitle text style QC and explicit punctuation normalization.

**Architecture:** Keep the first implementation inside the existing `qc` package, using focused `text_style` and `text_normalize` files. Extend CLI options so default QC output stays unchanged unless `--text-style` is provided, and wire `subtitle normalize` through the existing subtitle parser/writer path.

**Tech Stack:** MoonBit packages, existing `subtitle`, `qc`, `cli`, and `cmd/main` packages, `moon test`, `moon check`, `moon fmt`, `moon info`.

---

### Task 1: Text Style QC Model And Core Rules

**Files:**
- Create: `qc/text_style.mbt`
- Modify: `qc/rule.mbt`
- Modify: `qc/checks.mbt`
- Modify: `qc/qc_wbtest.mbt`

- [ ] Write failing tests in `qc/qc_wbtest.mbt` for:
  - default `check_cues` does not emit text-style warnings.
  - explicit bilingual profile emits `W501`, `W502`, `W503`, `W510`, `W511`, and `W520`.
  - JSON report can include a text-style warning through existing `format_json_report`.

- [ ] Run `moon test qc --target native` and verify the new tests fail because `check_cues_with_text_style` and text-style profiles do not exist yet.

- [ ] Add `TextStyleMode`, `TextStyleProfile`, `no_text_style_profile`, `bilingual_text_style_profile`, `zh_text_style_profile`, `en_text_style_profile`, `text_style_profile_by_name`, and `check_text_style_cues` to `qc/text_style.mbt`.

- [ ] Add a package-local text issue helper that emits:
  - `W501` for punctuation that conflicts with the dominant line language.
  - `W502` for repeated punctuation runs.
  - `W503` for simple bracket and quote pairing problems.
  - `W510` for long unbroken visible text blocks.
  - `W511` for isolated single CJK character lines.
  - `W520` for deterministic dictionary matches.

- [ ] Keep `check_cues(cues, profile)` unchanged by default and add `check_cues_with_text_style(cues, profile, text_profile)` for opt-in behavior.

- [ ] Run `moon test qc --target native` and verify the new tests pass.

### Task 2: CLI Parser For Opt-In Text Style

**Files:**
- Modify: `cli/command.mbt`
- Modify: `cli/cli_wbtest.mbt`
- Modify: `cmd/main/main.mbt`
- Modify: `cmd/main/main_wbtest.mbt`

- [ ] Write failing CLI parser tests for:
  - `moonpost qc input.srt --text-style bilingual`.
  - unknown `--text-style typo` produces an invalid QC command state.

- [ ] Write failing main-level tests showing:
  - `qc_result_for_text` without text style keeps existing summary.
  - `qc_result_for_text` with `--text-style bilingual` includes `W501` or another text-style warning.
  - unknown text style returns non-zero without reading input when possible.

- [ ] Run `moon test cli cmd/main --target native` and verify failures are from missing fields or missing behavior.

- [ ] Extend `QcOptions` with `text_style : String?` and parsed validity state if needed.

- [ ] Update `profile_from_name` or QC call wiring so text style options are converted through `@qc.text_style_profile_by_name`.

- [ ] Update root and QC help lines to document `--text-style bilingual|zh|en`.

- [ ] Run `moon test cli cmd/main --target native` and verify the new tests pass.

### Task 3: Punctuation Normalization API

**Files:**
- Create: `qc/text_normalize.mbt`
- Modify: `qc/qc_wbtest.mbt`

- [ ] Write failing tests for:
  - `normalize_punctuation("你好, world!", mode=bilingual)` returns conservative mixed punctuation.
  - `normalize_punctuation("Hello，world！", mode=en)` returns ASCII punctuation.
  - `normalize_punctuation("你好,世界!", mode=zh)` returns Chinese punctuation.

- [ ] Run `moon test qc --target native` and verify failures are from the missing API.

- [ ] Implement `normalize_punctuation(text, mode~)` using small deterministic mappings for comma, period, colon, semicolon, question mark, exclamation mark, parentheses, and quotes.

- [ ] Run `moon test qc --target native` and verify tests pass.

### Task 4: Subtitle Normalize CLI Command

**Files:**
- Modify: `cli/command.mbt`
- Modify: `cli/cli_wbtest.mbt`
- Modify: `cmd/main/main.mbt`
- Modify: `cmd/main/main_wbtest.mbt`

- [ ] Write failing parser tests for `moonpost subtitle normalize input.srt --punctuation bilingual -o fixed.srt`.

- [ ] Write failing main tests proving normalize preserves timing and changes only cue text punctuation.

- [ ] Run `moon test cli cmd/main --target native` and verify failures are from missing command support.

- [ ] Add `SubtitleNormalizeOptions` and `SubtitleCommand::Normalize`.

- [ ] Add `normalize_subtitle_text` and `run_subtitle_normalize` in `cmd/main/main.mbt`.

- [ ] Unknown `--punctuation` should print help-oriented output, return non-zero, and avoid writing output.

- [ ] Run `moon test cli cmd/main --target native` and verify tests pass.

### Task 5: Docs, Interfaces, And Full Validation

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`
- Modify: `qc/pkg.generated.mbti`
- Modify: `cli/pkg.generated.mbti`
- Modify if public CLI/main surfaces require it: other `pkg.generated.mbti` files generated by `moon info`.

- [ ] Update Chinese and English README with opt-in text-style QC and subtitle normalize examples.

- [ ] Run `moon fmt`.

- [ ] Run `moon info` and inspect generated interface changes for intended public API additions.

- [ ] Run:
  - `moon check --target native`
  - `moon check --target wasm-gc`
  - `moon test --target native`
  - `moon test --target wasm-gc`

- [ ] Check `git status --short` and summarize changed files.
