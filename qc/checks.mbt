///|
fn cue_label(cue : @subtitle.Cue, fallback : Int) -> Int? {
  match cue.index {
    Some(value) => Some(value)
    None => Some(fallback + 1)
  }
}

///|
fn text_char_count(text : Array[String]) -> Int {
  let mut count = 0
  for line in text {
    count += line.iter().count()
  }
  count
}

///|
fn is_empty_text(text : Array[String]) -> Bool {
  if text.length() == 0 {
    true
  } else {
    let mut empty = true
    for line in text {
      if !line.trim().to_owned().is_empty() {
        empty = false
      }
    }
    empty
  }
}

///|
fn push_issue(
  issues : Array[QcIssue],
  severity : Severity,
  code : String,
  cue_index : Int?,
  message : String,
) -> Unit {
  issues.push({ severity, code, cue_index, message })
}

///|
fn check_single_cue(
  issues : Array[QcIssue],
  cue : @subtitle.Cue,
  position : Int,
  profile : QcProfile,
) -> Unit {
  let label = cue_label(cue, position)
  let duration = cue.end_ms - cue.start_ms
  if duration <= 0 {
    push_issue(
      issues,
      Error,
      "E102",
      label,
      "end time must be after start time",
    )
  } else {
    if duration < profile.min_duration_ms {
      push_issue(
        issues,
        Warning,
        "W201",
        label,
        "duration \{duration}ms below minimum \{profile.min_duration_ms}ms",
      )
    }
    if duration > profile.max_duration_ms {
      push_issue(
        issues,
        Warning,
        "W202",
        label,
        "duration \{duration}ms above maximum \{profile.max_duration_ms}ms",
      )
    }
    let chars = text_char_count(cue.text)
    let cps = (chars * 1000 + duration / 2) / duration
    if cps > profile.max_cps {
      push_issue(
        issues,
        Warning,
        "W310",
        label,
        "\{cps} cps exceeds max \{profile.max_cps}",
      )
    }
  }
  if is_empty_text(cue.text) {
    push_issue(issues, Error, "E201", label, "empty cue text")
  }
  if cue.text.length() > profile.max_lines {
    push_issue(
      issues,
      Warning,
      "W204",
      label,
      "\{cue.text.length()} lines exceeds max \{profile.max_lines}",
    )
  }
  for line_index in 0..<cue.text.length() {
    let line = cue.text[line_index]
    let cpl = line.iter().count()
    if cpl > profile.max_cpl {
      push_issue(
        issues,
        Warning,
        "W203",
        label,
        "line \{line_index + 1}: \{cpl} chars, max \{profile.max_cpl}",
      )
    }
  }
  match profile.frame_rate {
    Some(rate) => {
      let frame_ms = rate.frame_duration_ms()
      if cue.start_ms % frame_ms != 0 || cue.end_ms % frame_ms != 0 {
        push_issue(
          issues,
          Warning,
          "W401",
          label,
          "cue timing is not aligned to \{frame_ms}ms frame grid",
        )
      }
    }
    None => ()
  }
}

///|
fn check_neighbors(
  issues : Array[QcIssue],
  cues : Array[@subtitle.Cue],
  profile : QcProfile,
) -> Unit {
  match profile.frame_rate {
    Some(rate) => {
      let min_gap_ms = rate.frames_to_ms(profile.min_gap_frames)
      for index in 0..<(cues.length() - 1) {
        let current = cues[index]
        let next = cues[index + 1]
        if current.end_ms > next.start_ms {
          push_issue(
            issues,
            Error,
            "E101",
            cue_label(current, index),
            "overlaps cue#\{index + 2} by \{current.end_ms - next.start_ms}ms",
          )
        } else if next.start_ms - current.end_ms < min_gap_ms {
          push_issue(
            issues,
            Warning,
            "W402",
            cue_label(current, index),
            "gap to next cue is less than \{profile.min_gap_frames} frames",
          )
        }
      }
    }
    None =>
      for index in 0..<(cues.length() - 1) {
        let current = cues[index]
        let next = cues[index + 1]
        if current.end_ms > next.start_ms {
          push_issue(
            issues,
            Error,
            "E101",
            cue_label(current, index),
            "overlaps cue#\{index + 2} by \{current.end_ms - next.start_ms}ms",
          )
        }
      }
  }
}

///|
pub fn check_cues(
  cues : Array[@subtitle.Cue],
  profile : QcProfile,
) -> Array[QcIssue] {
  let issues : Array[QcIssue] = []
  for index in 0..<cues.length() {
    check_single_cue(issues, cues[index], index, profile)
  }
  if cues.length() > 1 {
    check_neighbors(issues, cues, profile)
  }
  issues
}
