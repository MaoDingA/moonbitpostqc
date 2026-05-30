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
priv struct SubtitleBlock {
  line : Int
  lines : Array[String]
}

///|
fn split_blocks_with_lines(input : String) -> Array[SubtitleBlock] {
  let blocks : Array[SubtitleBlock] = []
  let mut current : Array[String] = []
  let mut current_line = 1
  let mut line_number = 1
  for raw in input.split("\n") {
    let line = clean_line(raw.to_owned())
    if is_blank(line) {
      if current.length() > 0 {
        blocks.push({ line: current_line, lines: current })
        current = []
      }
    } else {
      if current.length() == 0 {
        current_line = line_number
      }
      current.push(line)
    }
    line_number += 1
  }
  if current.length() > 0 {
    blocks.push({ line: current_line, lines: current })
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
fn parse_error(
  format : SubtitleFormat,
  block : Int,
  line : Int,
  message : String,
) -> ParseError {
  { format: Some(format), block, line, message }
}

///|
fn parse_srt_block_detailed(
  block : SubtitleBlock,
  block_index : Int,
) -> Result[Cue, ParseError] {
  match block.lines {
    [first, second, .. rest] =>
      match parse_int(first) {
        Some(index) =>
          match parse_timing(second) {
            Some((start_ms, end_ms, settings)) =>
              Ok({
                index: Some(index),
                identifier: None,
                start_ms,
                end_ms,
                text: rest.to_owned(),
                settings,
              })
            None =>
              Err(
                parse_error(
                  Srt,
                  block_index,
                  block.line + 1,
                  "invalid SRT timing line",
                ),
              )
          }
        None =>
          match parse_timing(first) {
            Some((start_ms, end_ms, settings)) =>
              Ok({
                index: None,
                identifier: None,
                start_ms,
                end_ms,
                text: [second] + rest.to_owned(),
                settings,
              })
            None =>
              Err(
                parse_error(
                  Srt,
                  block_index,
                  block.line,
                  "expected SRT timing line",
                ),
              )
          }
      }
    [only] =>
      match parse_timing(only) {
        Some((start_ms, end_ms, settings)) =>
          Ok({
            index: None,
            identifier: None,
            start_ms,
            end_ms,
            text: [],
            settings,
          })
        None =>
          Err(
            parse_error(
              Srt,
              block_index,
              block.line,
              "expected SRT timing line",
            ),
          )
      }
    _ =>
      Err(
        parse_error(Srt, block_index, block.line, "expected non-empty SRT cue"),
      )
  }
}

///|
pub fn parse_srt_detailed(input : String) -> Result[SubtitleTrack, ParseError] {
  let cues : Array[Cue] = []
  let blocks = split_blocks_with_lines(input)
  for index in 0..<blocks.length() {
    match parse_srt_block_detailed(blocks[index], index + 1) {
      Ok(cue) => cues.push(cue)
      Err(error) => return Err(error)
    }
  }
  Ok({ format: Srt, cues })
}

///|
pub fn parse_srt(input : String) -> SubtitleTrack? {
  match parse_srt_detailed(input) {
    Ok(track) => Some(track)
    Err(_) => None
  }
}

///|
pub fn parse_srt_with_recovery(input : String) -> ParseResult {
  let cues : Array[Cue] = []
  let errors : Array[ParseError] = []
  let blocks = split_blocks_with_lines(input)
  for index in 0..<blocks.length() {
    match parse_srt_block_detailed(blocks[index], index + 1) {
      Ok(cue) => cues.push(cue)
      Err(error) => errors.push(error)
    }
  }
  { track: { format: Srt, cues }, errors }
}

///|
fn parse_webvtt_block_detailed(
  block : SubtitleBlock,
  block_index : Int,
) -> Result[Cue, ParseError] {
  match block.lines {
    [first, .. rest] =>
      match parse_timing(first) {
        Some((start_ms, end_ms, settings)) =>
          Ok({
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
                  Ok({
                    index: None,
                    identifier: Some(first),
                    start_ms,
                    end_ms,
                    text: text.to_owned(),
                    settings,
                  })
                None =>
                  Err(
                    parse_error(
                      WebVtt,
                      block_index,
                      block.line + 1,
                      "invalid WebVTT timing line",
                    ),
                  )
              }
            _ =>
              Err(
                parse_error(
                  WebVtt,
                  block_index,
                  block.line,
                  "expected WebVTT timing line",
                ),
              )
          }
      }
    _ =>
      Err(
        parse_error(
          WebVtt,
          block_index,
          block.line,
          "expected non-empty WebVTT cue",
        ),
      )
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
pub fn parse_webvtt_detailed(
  input : String,
) -> Result[SubtitleTrack, ParseError] {
  let blocks = split_blocks_with_lines(input)
  let cues : Array[Cue] = []
  let mut saw_header = false
  for block in blocks {
    match block.lines.get(0) {
      Some(first) =>
        if first == "WEBVTT" || first.has_prefix("WEBVTT ") {
          saw_header = true
        }
      None => ()
    }
  }
  if !saw_header {
    return Err(parse_error(WebVtt, 1, 1, "missing WEBVTT header"))
  }
  let mut cue_block = 0
  for block in blocks {
    match block.lines.get(0) {
      Some(first) =>
        if first == "WEBVTT" || first.has_prefix("WEBVTT ") {
          ()
        } else if is_webvtt_metadata_block(first) {
          ()
        } else {
          cue_block += 1
          match parse_webvtt_block_detailed(block, cue_block) {
            Ok(cue) => cues.push(cue)
            Err(error) => return Err(error)
          }
        }
      None => ()
    }
  }
  Ok({ format: WebVtt, cues })
}

///|
pub fn parse_webvtt(input : String) -> SubtitleTrack? {
  match parse_webvtt_detailed(input) {
    Ok(track) => Some(track)
    Err(_) => None
  }
}

///|
pub fn parse_webvtt_with_recovery(input : String) -> ParseResult {
  let blocks = split_blocks_with_lines(input)
  let cues : Array[Cue] = []
  let errors : Array[ParseError] = []
  let mut saw_header = false
  for block in blocks {
    match block.lines.get(0) {
      Some(first) =>
        if first == "WEBVTT" || first.has_prefix("WEBVTT ") {
          saw_header = true
        }
      None => ()
    }
  }
  if !saw_header {
    errors.push(parse_error(WebVtt, 1, 1, "missing WEBVTT header"))
    return { track: { format: WebVtt, cues: [] }, errors }
  }
  let mut cue_block = 0
  for block in blocks {
    match block.lines.get(0) {
      Some(first) =>
        if first == "WEBVTT" || first.has_prefix("WEBVTT ") {
          ()
        } else if is_webvtt_metadata_block(first) {
          ()
        } else {
          cue_block += 1
          match parse_webvtt_block_detailed(block, cue_block) {
            Ok(cue) => cues.push(cue)
            Err(error) => errors.push(error)
          }
        }
      None => ()
    }
  }
  { track: { format: WebVtt, cues }, errors }
}
