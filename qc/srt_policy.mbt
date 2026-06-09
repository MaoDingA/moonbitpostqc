///|
pub(all) struct SrtSourcePolicy {
  expect_srt : Bool
  require_sequential_indices : Bool
  warn_timing_settings : Bool
  warn_style_markup : Bool
  min_first_cue_start_ms : Int?
} derive(Eq, Debug)

///|
pub fn no_srt_source_policy() -> SrtSourcePolicy {
  {
    expect_srt: false,
    require_sequential_indices: false,
    warn_timing_settings: false,
    warn_style_markup: false,
    min_first_cue_start_ms: None,
  }
}

///|
pub fn srt_basic_source_policy() -> SrtSourcePolicy {
  {
    expect_srt: true,
    require_sequential_indices: true,
    warn_timing_settings: true,
    warn_style_markup: true,
    min_first_cue_start_ms: None,
  }
}

///|
pub fn dcp_source_srt_policy() -> SrtSourcePolicy {
  {
    expect_srt: true,
    require_sequential_indices: true,
    warn_timing_settings: true,
    warn_style_markup: true,
    min_first_cue_start_ms: Some(4000),
  }
}

///|
fn srt_policy_cue_label(cue : @subtitle.Cue, fallback : Int) -> Int? {
  match cue.index {
    Some(value) => Some(value)
    None => Some(fallback + 1)
  }
}

///|
fn push_srt_policy_issue(
  issues : Array[QcIssue],
  code : String,
  cue_index : Int?,
  message : String,
) -> Unit {
  issues.push({ severity: Warning, code, cue_index, message })
}

///|
fn has_font_or_color_markup(line : String) -> Bool {
  let lower = line.to_lower()
  lower.contains("<font") ||
  lower.contains("</font") ||
  lower.contains("color=")
}

///|
fn has_ass_override(line : String) -> Bool {
  line.contains("{\\")
}

///|
fn check_srt_source_cue(
  issues : Array[QcIssue],
  cue : @subtitle.Cue,
  position : Int,
  policy : SrtSourcePolicy,
) -> Unit {
  let label = srt_policy_cue_label(cue, position)
  if policy.require_sequential_indices {
    match cue.index {
      Some(value) =>
        if value != position + 1 {
          push_srt_policy_issue(
            issues,
            "W102",
            Some(value),
            "SRT cue index should be \{position + 1}, found \{value}",
          )
        }
      None =>
        push_srt_policy_issue(issues, "W101", label, "missing SRT cue index")
    }
  }
  if policy.warn_timing_settings && !cue.settings.trim().to_owned().is_empty() {
    push_srt_policy_issue(
      issues,
      "W603",
      label,
      "SRT timing line contains WebVTT-style settings: \{cue.settings}",
    )
  }
  if policy.warn_style_markup {
    for line in cue.text {
      if has_font_or_color_markup(line) {
        push_srt_policy_issue(
          issues, "W601", label, "font or color markup may not survive SRT delivery conversion",
        )
      }
      if has_ass_override(line) {
        push_srt_policy_issue(
          issues, "W602", label, "ASS/SSA style override may not survive SRT delivery conversion",
        )
      }
    }
  }
}

///|
pub fn check_srt_source_track(
  track : @subtitle.SubtitleTrack,
  policy : SrtSourcePolicy,
) -> Array[QcIssue] {
  let issues : Array[QcIssue] = []
  if policy.expect_srt && track.format != Srt {
    push_srt_policy_issue(
      issues,
      "W100",
      None,
      "profile expects SRT sidecar input, got WebVTT",
    )
  }
  for index in 0..<track.cues.length() {
    check_srt_source_cue(issues, track.cues[index], index, policy)
  }
  match policy.min_first_cue_start_ms {
    Some(min_start_ms) =>
      match track.cues.get(0) {
        Some(first) =>
          if first.start_ms < min_start_ms {
            push_srt_policy_issue(
              issues,
              "W701",
              srt_policy_cue_label(first, 0),
              "first cue starts at \{first.start_ms}ms, below DCP-source minimum \{min_start_ms}ms",
            )
          }
        None => ()
      }
    None => ()
  }
  issues
}
