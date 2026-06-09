///|
fn cue_no_index(
  start_ms : Int,
  end_ms : Int,
  text : Array[String],
) -> @subtitle.Cue {
  { index: None, identifier: None, start_ms, end_ms, text, settings: "" }
}

// ── cue_label ──

///|
test "cue_label returns Some(index) when index is present" {
  let c = cue(7, 0, 1000, ["hi"])
  let label = cue_label(c, 0)
  assert_true(label == Some(7))
}

///|
test "cue_label returns Some(fallback+1) when index is None" {
  let c = cue_no_index(0, 1000, ["hi"])
  let label = cue_label(c, 3)
  assert_true(label == Some(4))
}

// ── text_char_count ──

///|
test "text_char_count sums all characters across lines" {
  assert_eq(text_char_count(["ab", "cde"]), 5)
}

///|
test "text_char_count returns 0 for empty array" {
  assert_eq(text_char_count([]), 0)
}

// ── is_empty_text ──

///|
test "is_empty_text returns true for empty array" {
  assert_true(is_empty_text([]))
}

///|
test "is_empty_text returns true for whitespace-only lines" {
  assert_true(is_empty_text(["  ", "\t", " "]))
}

///|
test "is_empty_text returns false for text with content" {
  assert_false(is_empty_text(["hello"]))
}

///|
test "is_empty_text returns false when only one line has content" {
  assert_false(is_empty_text(["  ", "hi", "  "]))
}

// ── check_cues: edge cases ──

///|
test "check_cues returns empty issues for valid single cue" {
  let cues = [cue(1, 1000, 2000, ["Hello world"])]
  let issues = check_cues(cues, default_profile())
  assert_eq(issues.length(), 0)
}

///|
test "check_cues handles zero-duration cue" {
  let cues = [cue(1, 1000, 1000, ["Hello"])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "E102" }))
}

///|
test "check_cues handles negative-duration cue (end < start)" {
  let cues = [cue(1, 2000, 1000, ["Hello"])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "E102" }))
}

///|
test "check_cues detects duration below minimum" {
  let cues = [cue(1, 1000, 1500, ["Hi"])]
  // default min_duration_ms is 800, so 500ms < 800ms triggers W201
  let profile = QcProfile::{
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: None,
  }
  let issues = check_cues(cues, profile)
  assert_true(issues.any(fn(i) { i.code == "W201" }))
}

///|
test "check_cues detects duration above maximum" {
  let cues = [cue(1, 0, 8000, ["Hello"])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "W202" }))
}

///|
test "check_cues detects high CPS" {
  let cues = [
    cue(1, 0, 500, ["A very long subtitle line with many characters in it"]),
  ]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "W310" }))
}

///|
test "check_cues detects empty cue text" {
  let cues = [cue(1, 1000, 2000, [""])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "E201" }))
}

///|
test "check_cues detects empty cue text with only whitespace" {
  let cues = [cue(1, 1000, 2000, ["   "])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "E201" }))
}

///|
test "check_cues detects too many lines" {
  let cues = [cue(1, 1000, 3000, ["one", "two", "three"])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "W204" }))
}

///|
test "check_cues detects CPL exceeding limit" {
  let cues = [
    cue(1, 1000, 3000, [
      "This is a very long line that exceeds 42 characters by quite a margin",
    ]),
  ]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "W203" }))
}

///|
test "check_cues skips CPL check when max_cpl is None" {
  let cues = [
    cue(1, 1000, 3000, [
      "This is a very long line that would normally exceed 42 characters",
    ]),
  ]
  let profile = QcProfile::{
    max_cpl: None,
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: None,
  }
  let issues = check_cues(cues, profile)
  assert_false(issues.any(fn(i) { i.code == "W203" }))
}

// ── check_cues: overlaps and gaps (no frame rate) ──

///|
test "check_cues detects overlap without frame rate" {
  let cues = [cue(1, 1000, 2500, ["first"]), cue(2, 2000, 3500, ["second"])]
  let issues = check_cues(cues, default_profile())
  assert_true(issues.any(fn(i) { i.code == "E101" }))
}

///|
test "check_cues no gap issue when no frame rate set" {
  let cues = [cue(1, 1000, 2000, ["first"]), cue(2, 2001, 3000, ["second"])]
  let issues = check_cues(cues, default_profile())
  assert_false(issues.any(fn(i) { i.code == "W402" }))
}

// ── check_cues: frame alignment ──

///|
test "check_cues detects misaligned start time" {
  // Fps25 => frame_duration = 40ms, 1111 % 40 != 0
  let cues = [cue(1, 1111, 2000, ["Hello"])]
  let profile = QcProfile::{
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(Fps25),
  }
  let issues = check_cues(cues, profile)
  assert_true(issues.any(fn(i) { i.code == "W401" }))
}

///|
test "check_cues accepts aligned cue timing" {
  // Fps25 => frame_duration = 40ms, 1000 % 40 == 0, 2000 % 40 == 0
  let cues = [cue(1, 1000, 2000, ["Hello"])]
  let profile = QcProfile::{
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(Fps25),
  }
  let issues = check_cues(cues, profile)
  assert_false(issues.any(fn(i) { i.code == "W401" }))
}

// ── check_cues: gap between cues at frame rate ──

///|
test "check_cues detects small gap at frame rate" {
  // Fps25 => frame=40ms, min_gap_frames=2 => min_gap=80ms
  // gap = 2080 - 2000 = 80ms, which is exactly 2 frames, should be OK
  // but gap = 2060 - 2000 = 60ms < 80ms, should trigger W402
  let cues = [cue(1, 1000, 2000, ["first"]), cue(2, 2060, 3000, ["second"])]
  let profile = QcProfile::{
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(Fps25),
  }
  let issues = check_cues(cues, profile)
  assert_true(issues.any(fn(i) { i.code == "W402" }))
}

///|
test "check_cues accepts sufficient gap at frame rate" {
  // gap = 2100 - 2000 = 100ms > 80ms => OK
  let cues = [cue(1, 1000, 2000, ["first"]), cue(2, 2100, 3000, ["second"])]
  let profile = QcProfile::{
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(Fps25),
  }
  let issues = check_cues(cues, profile)
  assert_false(issues.any(fn(i) { i.code == "W402" }))
}

// ── check_cues: multiple cues, multiple issues ──

///|
test "check_cues detects issues across multiple cues" {
  let cues = [
    cue(1, 1000, 2000, [""]), // E201 empty text
    cue(2, 2000, 2300, ["Hi"]), // W201 too short (300ms)
    cue(3, 2300, 10000, [ // W202 too long (7700ms)
      "a", "b", "c", // W204 too many lines
    ]),
  ]
  let profile = QcProfile::{
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: None,
  }
  let issues = check_cues(cues, profile)
  assert_true(issues.any(fn(i) { i.code == "E201" }))
  assert_true(issues.any(fn(i) { i.code == "W201" }))
  assert_true(issues.any(fn(i) { i.code == "W202" }))
  assert_true(issues.any(fn(i) { i.code == "W204" }))
}

// ── check_cues_with_text_style ──

///|
test "check_cues_with_text_style combines both checkers" {
  let cues = [cue(1, 1000, 2500, ["你好, world！！"])]
  let issues = check_cues_with_text_style(
    cues,
    default_profile(),
    bilingual_text_style_profile(),
  )
  assert_true(issues.any(fn(i) { i.code == "W501" }))
  assert_true(issues.any(fn(i) { i.code == "W502" }))
}

// ── profile_by_name edge cases ──

///|
test "profile_by_name returns social for social alias" {
  match profile_by_name("social") {
    Some(profile) => assert_eq(profile.max_cps, 24)
    None => fail("expected social profile")
  }
}

///|
test "profile_by_name returns None for unknown profile" {
  assert_true(profile_by_name("nonexistent") is None)
}

///|
test "default profile has no frame rate" {
  let profile = default_profile()
  assert_true(profile.frame_rate is None)
}

///|
test "streaming profile has 25fps" {
  let profile = streaming_profile()
  assert_true(profile.frame_rate == Some(Fps25))
}
