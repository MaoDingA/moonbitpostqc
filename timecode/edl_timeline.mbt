///|
/// A parsed CMX 3600 EDL timeline containing an ordered sequence of events.
pub(all) struct EdlTimeline {
  title : String
  frame_rate : FrameRate
  events : Array[EdlEvent]
} derive(Eq, Debug)

///|
/// Describes why an EDL file could not be parsed.
pub(all) enum EdlParseError {
  /// The input is empty or contains no valid events.
  EmptyEdl
  /// An event line is malformed; carries the 1-based line number and the
  /// underlying parse error.
  EventError(Int, TimecodeInteropError)
} derive(Eq, Debug)

///|
/// Returns true when the trimmed line looks like an EDL event line (starts
/// with a digit).
fn is_event_line(line : String) -> Bool {
  let trimmed = line.trim().to_owned()
  if trimmed.is_empty() {
    return false
  }
  let c = trimmed[0]
  c == '0' ||
  c == '1' ||
  c == '2' ||
  c == '3' ||
  c == '4' ||
  c == '5' ||
  c == '6' ||
  c == '7' ||
  c == '8' ||
  c == '9'
}

///|
/// Extracts the text after `prefix` in a trimmed line, returning `None` if
/// the prefix is absent or the remaining text is empty.
fn extract_after(line : String, prefix : String) -> String? {
  let trimmed = line.trim().to_owned()
  match trimmed.strip_prefix(prefix) {
    Some(rest) => {
      let value = rest.trim().to_owned()
      if value.is_empty() {
        None
      } else {
        Some(value)
      }
    }
    None => None
  }
}

///|
/// Extracts clip name from a `* FROM CLIP NAME:` remark line.
fn parse_clip_name_remark(line : String) -> String? {
  extract_after(line, "* FROM CLIP NAME:")
}

///|
/// Extracts comment text from a `* COMMENT:` remark line.
fn parse_comment_remark(line : String) -> String? {
  extract_after(line, "* COMMENT:")
}

///|
/// Extracts source file from a `* SOURCE FILE:` remark line.
fn parse_source_file_remark(line : String) -> String? {
  extract_after(line, "* SOURCE FILE:")
}

///|
/// Applies remark lines to an event, producing a new event with the remark
/// fields filled in.
fn apply_remarks(
  event : EdlEvent,
  clip_name : String?,
  comment : String?,
  source_file : String?,
) -> EdlEvent {
  { ..event, clip_name, comment, source_file }
}

///|
/// Parses a complete CMX 3600 EDL file into a structured timeline.
///
/// Recognizes `TITLE:` and `FCM:` header lines, groups event lines with their
/// trailing remark lines (`* FROM CLIP NAME`, `* COMMENT`, `* SOURCE FILE`),
/// and returns an `EdlTimeline` with all events in order.
pub fn parse_edl(
  raw : String,
  rate : FrameRate,
) -> Result[EdlTimeline, EdlParseError] {
  let lines = raw.split("\n")
  let mut title = ""
  let mut header_done = false
  let events : Array[EdlEvent] = []
  let mut current_event : EdlEvent? = None
  let mut clip_name : String? = None
  let mut comment : String? = None
  let mut source_file : String? = None
  let mut line_number : Int = 0
  for line in lines {
    line_number += 1
    let trimmed = line.trim().to_owned()
    if trimmed.is_empty() {
      continue
    }
    // Parse header lines before the first event.
    if !header_done && !is_event_line(trimmed) && current_event is None {
      match trimmed.strip_prefix("TITLE:") {
        Some(rest) => {
          title = rest.trim().to_owned()
          continue
        }
        None => ()
      }
      if trimmed.has_prefix("FCM:") {
        continue
      }
      // Unknown header line; skip.
      continue
    }
    header_done = true
    // Remark lines start with *.
    if trimmed.has_prefix("*") {
      match parse_clip_name_remark(trimmed) {
        Some(name) => {
          clip_name = Some(name)
          continue
        }
        None => ()
      }
      match parse_comment_remark(trimmed) {
        Some(text) => {
          comment = Some(text)
          continue
        }
        None => ()
      }
      match parse_source_file_remark(trimmed) {
        Some(file) => {
          source_file = Some(file)
          continue
        }
        None => ()
      }
      // Unknown remark; skip.
      continue
    }
    // Possible event line.
    if is_event_line(trimmed) {
      // Finalize the previous event with its remarks.
      match current_event {
        Some(prev) =>
          events.push(apply_remarks(prev, clip_name, comment, source_file))
        None => ()
      }
      clip_name = None
      comment = None
      source_file = None
      match EdlEvent::parse(trimmed, rate) {
        Ok(event) => current_event = Some(event)
        Err(error) => return Err(EventError(line_number, error))
      }
    }
  }
  // Finalize the last event.
  match current_event {
    Some(prev) =>
      events.push(apply_remarks(prev, clip_name, comment, source_file))
    None => ()
  }
  if events.length() == 0 {
    return Err(EmptyEdl)
  }
  Ok({ title, frame_rate: rate, events })
}

///|
/// Formats an EDL timeline as a CMX 3600 text representation.
///
/// The output can be round-tripped through `parse_edl` at the same frame rate.
pub fn format_edl(timeline : EdlTimeline) -> String {
  let parts : Array[String] = []
  if !timeline.title.is_empty() {
    parts.push("TITLE: \{timeline.title}")
  }
  for event in timeline.events {
    parts.push(event.format())
    match event.clip_name {
      Some(name) => parts.push("* FROM CLIP NAME: \{name}")
      None => ()
    }
    match event.comment {
      Some(text) => parts.push("* COMMENT: \{text}")
      None => ()
    }
    match event.source_file {
      Some(file) => parts.push("* SOURCE FILE: \{file}")
      None => ()
    }
  }
  parts.join("\n")
}
