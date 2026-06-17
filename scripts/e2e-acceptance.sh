#!/usr/bin/env bash
#
# MoonPost E2E acceptance script — runs all 8 judge-facing scenarios.
#
# Usage:
#   ./scripts/e2e-acceptance.sh
#
# Prerequisites: moon CLI on PATH, or pass a prebuilt binary via $EXE.
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# ── Locate the CLI binary ────────────────────────────────────────────
EXE="${EXE:-}"
if [ -z "$EXE" ]; then
  if [ -x "$ROOT/_build/native/debug/build/cmd/main/main.exe" ]; then
    EXE="$ROOT/_build/native/debug/build/cmd/main/main.exe"
  else
    echo "→ Building native CLI (moon build cmd/main --target native) ..."
    moon build cmd/main --target native
    EXE="$ROOT/_build/native/debug/build/cmd/main/main.exe"
  fi
fi

if [ ! -x "$EXE" ]; then
  echo "✗ CLI binary not found: $EXE" >&2
  exit 2
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

# check <name> <expected-substring> <file>
check() {
  local name="$1" needle="$2" file="$3"
  if grep -q -- "$needle" "$file"; then
    printf "  ✓ %s\n" "$name"
    PASS=$((PASS + 1))
  else
    printf "  ✗ %s (expected: %q in %s)\n" "$name" "$needle" "$file"
    FAIL=$((FAIL + 1))
  fi
}

# check_status <name> <want-status> <got-status>
check_status() {
  local name="$1" want="$2" got="$3"
  if [ "$got" -eq "$want" ]; then
    printf "  ✓ %s (exit %s)\n" "$name" "$got"
    PASS=$((PASS + 1))
  else
    printf "  ✗ %s (expected exit %s, got %s)\n" "$name" "$want" "$got"
    FAIL=$((FAIL + 1))
  fi
}

echo "MoonPost E2E Acceptance"
echo "Binary: $EXE"
echo ""

# ── Scenario 1: Format conversion matrix ────────────────────────────
echo "Scenario 1: Format conversion"
"$EXE" subtitle convert examples/good.srt --to webvtt > "$TMP/srt2vtt.vtt"
check "SRT → WebVTT"          "^WEBVTT\$"                 "$TMP/srt2vtt.vtt"
check "SRT → WebVTT content"  "Hello, welcome to MoonBit." "$TMP/srt2vtt.vtt"

"$EXE" subtitle convert examples/good.srt --to ass > "$TMP/srt2ass.ass"
check "SRT → ASS header"      "^\[Script Info\]\$"        "$TMP/srt2ass.ass"
check "SRT → ASS events"      "^\[Events\]\$"             "$TMP/srt2ass.ass"
check "SRT → ASS dialogue"    "Dialogue: 0,0:00:01.00,0:00:03.20,Default" "$TMP/srt2ass.ass"

"$EXE" subtitle convert examples/good.ass --to srt > "$TMP/ass2srt.srt"
check "ASS → SRT timing"      "00:00:01,000 --> 00:00:03,200" "$TMP/ass2srt.srt"
check "ASS → SRT content"     "Hello, welcome to MoonBit."    "$TMP/ass2srt.srt"

"$EXE" subtitle convert examples/good.vtt --to ass > "$TMP/vtt2ass.ass"
check "WebVTT → ASS header"   "^\[Script Info\]\$"        "$TMP/vtt2ass.ass"
echo ""

# ── Scenario 2: QC across all profiles ──────────────────────────────
echo "Scenario 2: QC profiles"
for profile in default streaming cinema; do
  "$EXE" qc examples/bad.srt --profile "$profile" > "$TMP/qc-$profile.txt"
  check "QC $profile E101" "ERROR E101" "$TMP/qc-$profile.txt"
  check "QC $profile E102" "ERROR E102" "$TMP/qc-$profile.txt"
done
for profile in ott-zh iqiyi youku tencent nrta; do
  "$EXE" delivery subtitle-check examples/bad.srt --profile "$profile" > "$TMP/delivery-$profile.txt"
  check "Delivery $profile E101" "ERROR E101" "$TMP/delivery-$profile.txt"
done
echo ""

# ── Scenario 3: Creator clean pipeline ──────────────────────────────
echo "Scenario 3: Creator clean"
"$EXE" creator clean examples/creator/ai-clean-bad.srt --verbose > "$TMP/creator-clean.txt"
check "Clean C601 然后然后" "C601.*然后然后.*然后" "$TMP/creator-clean.txt"
check "Clean C601 就是就是" "C601.*就是就是.*就是" "$TMP/creator-clean.txt"
check "Clean C602 [Music]"  "C602.*\[Music\]"      "$TMP/creator-clean.txt"
echo ""

# ── Scenario 4: Delivery package acceptance ─────────────────────────
echo "Scenario 4: Delivery package"
"$EXE" delivery check examples/delivery-package/good --profile distribution --subtitle-profile ott-zh > "$TMP/pkg-good.txt"
check "Good package passes" "0 errors, 0 warnings" "$TMP/pkg-good.txt"

set +e
"$EXE" delivery check examples/delivery-package/bad --profile distribution --subtitle-profile ott-zh --fail-on-error > "$TMP/pkg-bad.txt"
status=$?
set -e
check_status "Bad package fails" 1 "$status"
check "Bad package D101"   "D101" "$TMP/pkg-bad.txt"
echo ""

# ── Scenario 5: Timecode toolchain ──────────────────────────────────
echo "Scenario 5: Timecode"
"$EXE" timecode to-frames 01:00:00:00 --fps 25 > "$TMP/tc1.txt"
check "to-frames"       "90000 frames" "$TMP/tc1.txt"
"$EXE" timecode from-frames 90000 --fps 25 > "$TMP/tc2.txt"
check "from-frames"     "01:00:00:00"  "$TMP/tc2.txt"
"$EXE" timecode convert 01:00:00:00 --from 23.976 --to 25 > "$TMP/tc3.txt"
check "convert"         "01:00:03:15 @25fps" "$TMP/tc3.txt"
"$EXE" timecode imf-from 01:00:00:00 --fps 25 > "$TMP/tc4.txt"
check "imf-from"        "editRate"     "$TMP/tc4.txt"
echo ""

# ── Scenario 6: Bilingual merge and split ───────────────────────────
echo "Scenario 6: Bilingual"
"$EXE" merge examples/good.srt examples/bilingual.srt --tolerance 800 > "$TMP/merged.srt"
check "Merge"            "Hello, welcome to MoonBit." "$TMP/merged.srt"
"$EXE" split-bilingual examples/bilingual.srt --primary "$TMP/primary.srt" --secondary "$TMP/secondary.srt"
check "Split secondary"  "MoonBit makes subtitle tooling compact." "$TMP/secondary.srt"
echo ""

# ── Scenario 7: New QC rules ────────────────────────────────────────
echo "Scenario 7: New QC rules"
"$EXE" qc examples/acceptance/all-rules.srt --profile streaming --text-style bilingual > "$TMP/new-rules.txt"
check "W205 whitespace"  "W205" "$TMP/new-rules.txt"
check "W310 CPS"         "W310" "$TMP/new-rules.txt"
check "W208 imbalance"   "W208" "$TMP/new-rules.txt"
echo ""

# ── Scenario 8: Explain all codes ───────────────────────────────────
echo "Scenario 8: Explain codes"
codes="E101 E102 E201 W201 W202 W203 W204 W205 W206 W207 W208 W310 W311 W401 W402 W501 W502 W503 W510 W511 W520 W601 W602 W603 W701 C401 C402 C403 C601 C602 C603 D101 D102 D202 D401 D402 D403 D404"
codes_fail=0
for code in $codes; do
  output=$("$EXE" explain "$code")
  if echo "$output" | grep -q "Unknown"; then
    printf "  ✗ explain %s returned Unknown\n" "$code"
    codes_fail=1
  fi
done
if [ "$codes_fail" -eq 0 ]; then
  printf "  ✓ All 38 explain codes valid\n"
  PASS=$((PASS + 1))
else
  FAIL=$((FAIL + 1))
fi
echo ""

# ── Summary ─────────────────────────────────────────────────────────
echo "──────────────────────────────────────"
if [ "$FAIL" -eq 0 ]; then
  printf "✓ ALL PASSED (%s checks)\n" "$PASS"
  exit 0
else
  printf "✗ %d FAILED, %d passed\n" "$FAIL" "$PASS"
  exit 1
fi
