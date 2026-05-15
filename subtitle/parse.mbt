///|
fn clean_line(line : String) -> String {
  let trimmed = line.trim(chars="\r").to_owned()
  if trimmed.has_prefix("\u{FEFF}") {
    trimmed[1:].to_owned()
  } else {
    trimmed
  }
}

///|
fn is_blank(line : String) -> Bool {
  line.trim().to_owned().is_empty()
}

///|
fn split_blocks(input : String) -> Array[Array[String]] {
  let blocks : Array[Array[String]] = []
  let mut current : Array[String] = []
  for raw in input.split("\n") {
    let line = clean_line(raw.to_owned())
    if is_blank(line) {
      if current.length() > 0 {
        blocks.push(current)
        current = []
      }
    } else {
      current.push(line)
    }
  }
  if current.length() > 0 {
    blocks.push(current)
  }
  blocks
}

///|
fn parse_timing(line : String) -> (Int, Int, String)? {
  let parts = split_to_strings(line, "-->")
  match parts {
    [start_raw, end_raw] => {
      let start_text = start_raw.trim().to_owned()
      let end_and_settings = end_raw.trim().to_owned()
      let right_parts = split_to_strings(end_and_settings, " ")
      match right_parts.get(0) {
        Some(end_text) =>
          match (parse_timestamp_ms(start_text), parse_timestamp_ms(end_text)) {
            (Some(start_ms), Some(end_ms)) => {
              let settings : Array[String] = []
              for index in 1..<right_parts.length() {
                let piece = right_parts[index].trim().to_owned()
                if !piece.is_empty() {
                  settings.push(piece)
                }
              }
              Some((start_ms, end_ms, settings.join(" ")))
            }
            _ => None
          }
        None => None
      }
    }
    _ => None
  }
}

///|
fn parse_srt_block(block : Array[String]) -> Cue? {
  match block {
    [first, second, .. rest] =>
      match (parse_int(first), parse_timing(second)) {
        (Some(index), Some((start_ms, end_ms, settings))) =>
          Some({
            index: Some(index),
            identifier: None,
            start_ms,
            end_ms,
            text: rest.to_owned(),
            settings,
          })
        _ =>
          match parse_timing(first) {
            Some((start_ms, end_ms, settings)) =>
              Some({
                index: None,
                identifier: None,
                start_ms,
                end_ms,
                text: [second] + rest.to_owned(),
                settings,
              })
            None => None
          }
      }
    [only] =>
      match parse_timing(only) {
        Some((start_ms, end_ms, settings)) =>
          Some({
            index: None,
            identifier: None,
            start_ms,
            end_ms,
            text: [],
            settings,
          })
        None => None
      }
    _ => None
  }
}

///|
pub fn parse_srt(input : String) -> SubtitleTrack? {
  let cues : Array[Cue] = []
  for block in split_blocks(input) {
    match parse_srt_block(block) {
      Some(cue) => cues.push(cue)
      None => return None
    }
  }
  Some({ format: Srt, cues })
}

///|
fn parse_webvtt_block(block : Array[String]) -> Cue? {
  match block {
    [first, .. rest] =>
      if first == "WEBVTT" || first.has_prefix("WEBVTT ") {
        None
      } else {
        match parse_timing(first) {
          Some((start_ms, end_ms, settings)) =>
            Some({
              index: None,
              identifier: None,
              start_ms,
              end_ms,
              text: rest.to_owned(),
              settings,
            })
          None =>
            match rest {
              [timing, .. text] =>
                match parse_timing(timing) {
                  Some((start_ms, end_ms, settings)) =>
                    Some({
                      index: None,
                      identifier: Some(first),
                      start_ms,
                      end_ms,
                      text: text.to_owned(),
                      settings,
                    })
                  None => None
                }
              _ => None
            }
        }
      }
    _ => None
  }
}

///|
fn is_webvtt_metadata_block(first : String) -> Bool {
  first == "STYLE" ||
  first == "REGION" ||
  first == "NOTE" ||
  first.has_prefix("NOTE ")
}

///|
pub fn parse_webvtt(input : String) -> SubtitleTrack? {
  let blocks = split_blocks(input)
  let cues : Array[Cue] = []
  let mut saw_header = false
  for block in blocks {
    match block.get(0) {
      Some(first) =>
        if first == "WEBVTT" || first.has_prefix("WEBVTT ") {
          saw_header = true
        } else if is_webvtt_metadata_block(first) {
          ()
        } else {
          match parse_webvtt_block(block) {
            Some(cue) => cues.push(cue)
            None => return None
          }
        }
      None => ()
    }
  }
  if saw_header {
    Some({ format: WebVtt, cues })
  } else {
    None
  }
}
