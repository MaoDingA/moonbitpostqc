///|
/// Split a string by comma, but stop after max_parts fields.
/// The last field contains the remainder of the string.
fn split_csv_fields(raw : String, max_parts : Int) -> Array[String] {
  let parts : Array[String] = []
  let mut start = 0
  let mut i = 0
  let len = raw.length()
  let mut remaining = max_parts
  while i < len && remaining > 1 {
    let c = raw[i]
    if c == ',' {
      parts.push(raw[start:i].to_owned())
      start = i + 1
      remaining -= 1
    }
    i += 1
  }
  parts.push(raw[start:].to_owned())
  parts
}

///|
/// Split ASS text (using \N and \n as line breaks) into separate lines.
/// Also strips override tags ({...}).
fn ass_text_to_lines(text : String) -> Array[String] {
  let lines : Array[String] = []
  let mut current : Array[String] = []
  let mut i = 0
  let len = text.length()
  let mut in_tag = false
  while i < len {
    let c = text[i]
    // Handle override tags: skip content between { and }
    if c == '{' {
      in_tag = true
      i += 1
      continue
    }
    if c == '}' {
      in_tag = false
      i += 1
      continue
    }
    if in_tag {
      i += 1
      continue
    }
    // Handle \N (hard break) and \n (soft break)
    if c == '\\' && i + 1 < len {
      let next = text[i + 1]
      if next == 'N' || next == 'n' {
        lines.push(current.join(""))
        current = []
        i += 2
        continue
      }
    }
    current.push(text[i:i + 1].to_owned())
    i += 1
  }
  lines.push(current.join(""))
  lines
}

///|
/// Detect whether the input uses ASS (v4.00+) or SSA (v4.00) format.
fn detect_ass_version(lines : Array[String]) -> SubtitleFormat {
  for line in lines {
    let trimmed = line.trim().to_owned()
    if trimmed.has_prefix("ScriptType:") {
      let value = trimmed[11:].trim().to_owned()
      if value.has_prefix("v4.00+") || value.has_prefix("V4.00+") {
        return Ass
      }
      if value.has_prefix("v4.00") && !value.has_prefix("v4.00+") {
        return Ssa
      }
    }
  }
  Ass
}

///|
/// Find the index of ": " in a string, or -1 if not found.
fn find_colon_space(text : String) -> Int {
  let len = text.length()
  let mut i = 0
  while i + 1 < len {
    if text[i] == ':' && text[i + 1] == ' ' {
      return i
    }
    i += 1
  }
  -1
}

///|
/// Parse a single ASS/SSA Dialogue or Comment line into a Cue.
fn parse_ass_event_line(
  line : String,
  line_number : Int,
  fmt : SubtitleFormat,
) -> Result[Cue, ParseError] {
  // Split "Dialogue: " or "Comment: " prefix from the rest
  let colon_idx = find_colon_space(line)
  if colon_idx < 0 {
    return Err({
      format: Some(fmt),
      block: 0,
      line: line_number,
      message: "expected 'Type: ...' format in ASS event line",
    })
  }
  let rest = line[colon_idx + 2:].to_owned()
  // Split into 10 fields: Layer,Start,End,Style,Name,MarginL,MarginR,MarginV,Effect,Text
  let fields = split_csv_fields(rest, 10)
  if fields.length() < 10 {
    return Err({
      format: Some(fmt),
      block: 0,
      line: line_number,
      message: "expected 10 fields in ASS event line, got \{fields.length()}",
    })
  }
  let start_str = fields[1].trim().to_owned()
  let end_str = fields[2].trim().to_owned()
  let style_name = fields[3].trim().to_owned()
  let text_field = fields[9]
  let start_opt = parse_ass_timestamp_ms(start_str)
  let end_opt = parse_ass_timestamp_ms(end_str)
  match (start_opt, end_opt) {
    (Some(start_ms), Some(end_ms)) => {
      let text_lines = ass_text_to_lines(text_field)
      Ok({
        index: None,
        identifier: if style_name.is_empty() {
          None
        } else {
          Some(style_name)
        },
        start_ms,
        end_ms,
        text: text_lines,
        settings: "",
      })
    }
    _ =>
      Err({
        format: Some(fmt),
        block: 0,
        line: line_number,
        message: "invalid ASS timing: \{start_str} .. \{end_str}",
      })
  }
}

///|
pub fn parse_ass(input : String) -> SubtitleTrack? {
  match parse_ass_detailed(input) {
    Ok(track) => Some(track)
    Err(_) => None
  }
}

///|
pub fn parse_ass_detailed(input : String) -> Result[SubtitleTrack, ParseError] {
  let lines : Array[String] = []
  for raw in input.split("\n") {
    lines.push(clean_line(raw.to_owned()))
  }
  let fmt = detect_ass_version(lines)
  let cues : Array[Cue] = []
  let mut in_events = false
  let mut line_number = 0
  for line in lines {
    line_number += 1
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() {
      continue
    }
    if trimmed == "[Events]" {
      in_events = true
      continue
    }
    if trimmed.length() > 0 &&
      trimmed[0] == '[' &&
      trimmed[trimmed.length() - 1] == ']' {
      in_events = false
      continue
    }
    if in_events {
      if trimmed.has_prefix("Dialogue:") || trimmed.has_prefix("Comment:") {
        match parse_ass_event_line(trimmed, line_number, fmt) {
          Ok(cue) => cues.push(cue)
          Err(error) => return Err(error)
        }
      }
    }
  }
  Ok({ format: fmt, cues })
}

///|
pub fn parse_ass_with_recovery(input : String) -> ParseResult {
  let lines : Array[String] = []
  for raw in input.split("\n") {
    lines.push(clean_line(raw.to_owned()))
  }
  let fmt = detect_ass_version(lines)
  let cues : Array[Cue] = []
  let errors : Array[ParseError] = []
  let mut in_events = false
  let mut line_number = 0
  for line in lines {
    line_number += 1
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() {
      continue
    }
    if trimmed == "[Events]" {
      in_events = true
      continue
    }
    if trimmed.length() > 0 &&
      trimmed[0] == '[' &&
      trimmed[trimmed.length() - 1] == ']' {
      in_events = false
      continue
    }
    if in_events {
      if trimmed.has_prefix("Dialogue:") || trimmed.has_prefix("Comment:") {
        match parse_ass_event_line(trimmed, line_number, fmt) {
          Ok(cue) => cues.push(cue)
          Err(error) => errors.push(error)
        }
      }
    }
  }
  { track: { format: fmt, cues }, errors }
}

///|
/// Convert newlines in text to ASS hard break (\N).
fn escape_ass_text(text : String) -> String {
  let parts : Array[String] = []
  let mut current : Array[String] = []
  let mut i = 0
  let len = text.length()
  while i < len {
    let c = text[i]
    if c == '\n' {
      parts.push(current.join(""))
      current = []
    } else {
      current.push(text[i:i + 1].to_owned())
    }
    i += 1
  }
  parts.push(current.join(""))
  parts.join("\\N")
}

///|
pub fn write_ass(track : SubtitleTrack) -> String {
  let lines : Array[String] = []
  lines.push("[Script Info]")
  lines.push("Title: MoonPost Export")
  lines.push("ScriptType: v4.00+")
  lines.push("PlayResX: 384")
  lines.push("PlayResY: 288")
  lines.push("")
  lines.push("[V4+ Styles]")
  lines.push(
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding",
  )
  lines.push(
    "Style: Default,Arial,20,&H00FFFFFF,&H0300FFBE,&H00000008,&H00000000,-1,0,0,0,100,100,0,0,1,2,0,2,10,10,10,0",
  )
  lines.push("")
  lines.push("[Events]")
  lines.push(
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text",
  )
  for cue in track.cues {
    let start = format_ass_timestamp(cue.start_ms)
    let end = format_ass_timestamp(cue.end_ms)
    let style = match cue.identifier {
      Some(id) => id
      None => "Default"
    }
    let text = escape_ass_text(cue_text(cue.text))
    lines.push("Dialogue: 0,\{start},\{end},\{style},,0,0,0,,\{text}")
  }
  lines.join("\n") + "\n"
}

///|
pub fn write_ssa(track : SubtitleTrack) -> String {
  let lines : Array[String] = []
  lines.push("[Script Info]")
  lines.push("Title: MoonPost Export")
  lines.push("ScriptType: v4.00")
  lines.push("PlayResX: 384")
  lines.push("PlayResY: 288")
  lines.push("")
  lines.push("[V4 Styles]")
  lines.push(
    "Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, TertiaryColour, BackColour, Bold, Italic, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, AlphaLevel, Encoding",
  )
  lines.push(
    "Style: Default,Arial,20,&H00FFFFFF,&H0300FFBE,&H00000008,&H00000000,-1,0,1,2,0,2,10,10,10,0,0",
  )
  lines.push("")
  lines.push("[Events]")
  lines.push(
    "Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text",
  )
  for cue in track.cues {
    let start = format_ass_timestamp(cue.start_ms)
    let end = format_ass_timestamp(cue.end_ms)
    let style = match cue.identifier {
      Some(id) => id
      None => "Default"
    }
    let text = escape_ass_text(cue_text(cue.text))
    lines.push("Dialogue: 0,\{start},\{end},\{style},,0,0,0,,\{text}")
  }
  lines.join("\n") + "\n"
}
