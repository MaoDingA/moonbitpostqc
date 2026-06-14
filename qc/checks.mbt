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
/// Check W205: line has leading or trailing whitespace (excluding the trim itself).
/// Triggers when a line starts or ends with a space/tab but is not entirely blank.
fn has_leading_trailing_space(line : String) -> Bool {
  // Consider only non-empty trimmed lines: leading/trailing space is suspicious.
  let trimmed = line.trim().to_owned()
  if trimmed.is_empty() {
    return false
  }
  // Use prefix/suffix check so it is Unicode-safe across the UTF-16 boundary.
  // Space and tab are single-code-unit ASCII, so has_prefix/has_suffix work
  // correctly even when the first/last visible char is a multi-unit CJK glyph.
  line.has_prefix(" ") ||
  line.has_prefix("\t") ||
  line.has_suffix(" ") ||
  line.has_suffix("\t")
}

///|
/// Check W206: cue text contains consecutive blank lines.
fn has_consecutive_blank_lines(text : Array[String]) -> Bool {
  let mut prev_blank = false
  for line in text {
    let is_blank = line.trim().to_owned().is_empty()
    if is_blank && prev_blank {
      return true
    }
    prev_blank = is_blank
  }
  false
}

///|
/// Check W207: cue has a line that is only whitespace (not empty string but spaces/tabs).
fn has_whitespace_only_line(text : Array[String]) -> Bool {
  for line in text {
    if !line.is_empty() && line.trim().to_owned().is_empty() {
      return true
    }
  }
  false
}

///|
/// Count Latin-script words in a string (rough estimate by whitespace runs).
fn count_words(line : String) -> Int {
  let mut count = 0
  let mut in_word = false
  for ch in line.iter() {
    if ch.is_whitespace() {
      if in_word {
        count += 1
        in_word = false
      }
    } else {
      in_word = true
    }
  }
  if in_word {
    count + 1
  } else {
    count
  }
}

///|
/// Total word count across all cue lines.
fn cue_word_count(text : Array[String]) -> Int {
  let mut total = 0
  for line in text {
    total += count_words(line)
  }
  total
}

///|
/// Check W208: line imbalance — the longest visible line is more than
/// `max_ratio` times longer (by character count) than the shortest visible line.
/// Only compares non-blank lines. Returns the ratio*100 (integer) or 0 if not applicable.
fn line_imbalance_ratio(text : Array[String]) -> Int {
  let mut min_len = -1
  let mut max_len = 0
  for line in text {
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() {
      continue
    }
    let len = trimmed.iter().count()
    if min_len < 0 || len < min_len {
      min_len = len
    }
    if len > max_len {
      max_len = len
    }
  }
  if min_len <= 0 || max_len == 0 || min_len == max_len {
    return 0
  }
  // ratio = max_len / min_len, scaled by 100 to keep it integer
  max_len * 100 / min_len
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
    // W311: Words Per Second (for Latin-script text)
    match profile.max_wps {
      Some(max_wps) => {
        let words = cue_word_count(cue.text)
        if words > 0 {
          let wps = (words * 1000 + duration / 2) / duration
          if wps > max_wps {
            push_issue(
              issues,
              Warning,
              "W311",
              label,
              "\{wps} wps exceeds max \{max_wps}",
            )
          }
        }
      }
      None => ()
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
  // W205/W206/W207: whitespace hygiene
  for line_index in 0..<cue.text.length() {
    let line = cue.text[line_index]
    if has_leading_trailing_space(line) {
      push_issue(
        issues,
        Warning,
        "W205",
        label,
        "line \{line_index + 1}: leading or trailing whitespace",
      )
    }
  }
  if has_whitespace_only_line(cue.text) {
    push_issue(
      issues,
      Warning,
      "W207",
      label,
      "cue contains a whitespace-only line",
    )
  } else if has_consecutive_blank_lines(cue.text) {
    push_issue(
      issues,
      Warning,
      "W206",
      label,
      "cue contains consecutive blank lines",
    )
  }
  // W208: line imbalance
  match profile.max_line_imbalance {
    Some(max_ratio) => {
      let ratio = line_imbalance_ratio(cue.text)
      // ratio is scaled by 100; max_ratio is the integer ratio (e.g. 2 means 2.0x)
      if ratio > max_ratio * 100 {
        push_issue(
          issues,
          Warning,
          "W208",
          label,
          "line length imbalance ratio \{ratio / 100}.\{ratio % 100}x exceeds max \{max_ratio}x",
        )
      }
    }
    None => ()
  }
  match profile.max_cpl {
    Some(max_cpl) =>
      for line_index in 0..<cue.text.length() {
        let line = cue.text[line_index]
        let cpl = line.iter().count()
        if cpl > max_cpl {
          push_issue(
            issues,
            Warning,
            "W203",
            label,
            "line \{line_index + 1}: \{cpl} chars, max \{max_cpl}",
          )
        }
      }
    None => ()
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

///|
pub fn check_cues_with_text_style(
  cues : Array[@subtitle.Cue],
  profile : QcProfile,
  text_style : TextStyleProfile,
) -> Array[QcIssue] {
  let issues = check_cues(cues, profile)
  for issue in check_text_style_cues(cues, text_style) {
    issues.push(issue)
  }
  issues
}
