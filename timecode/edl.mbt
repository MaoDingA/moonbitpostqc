///|
/// A CMX-style EDL event with source and record timecode ranges.
///
/// Optional remark fields (`clip_name`, `comment`, `source_file`) are populated
/// by the full-file parser `parse_edl` from `* FROM CLIP NAME`, `* COMMENT`,
/// and `* SOURCE FILE` remark lines that follow the event line.
pub(all) struct EdlEvent {
  event_number : Int
  reel : String
  track : String
  transition : String
  source : TimecodeRange
  record : TimecodeRange
  clip_name : String?
  comment : String?
  source_file : String?
} derive(Eq, Debug)

///|
fn split_edl_fields(raw : String) -> Array[String] {
  let fields : Array[String] = []
  for part in raw.trim().to_owned().split(" ") {
    let field = part.trim().to_owned()
    if !field.is_empty() {
      fields.push(field)
    }
  }
  fields
}

///|
fn edl_parse_timecode(
  raw : String,
  rate : FrameRate,
) -> Result[Timecode, TimecodeInteropError] {
  match parse_timecode_result(raw, rate) {
    Ok(tc) => Ok(tc)
    Err(error) => Err(InvalidTimecode(error))
  }
}

///|
fn edl_range(
  start : Timecode,
  end : Timecode,
) -> Result[TimecodeRange, TimecodeInteropError] {
  match TimecodeRange::new(start, end) {
    Some(range) => Ok(range)
    None => Err(InvalidEdlEvent)
  }
}

///|
fn pad3(value : Int) -> String {
  if value < 10 {
    "00\{value}"
  } else if value < 100 {
    "0\{value}"
  } else {
    "\{value}"
  }
}

///|
/// Merges a separate transition code and duration token (e.g. "D" + "050")
/// into a single transition string ("D050"). Returns the original if no merge
/// is needed.
fn merge_dissolve_transition(code : String, maybe_duration : String) -> String {
  if (code == "D" || code == "W" || code == "K") &&
    !maybe_duration.is_empty() &&
    parse_int(maybe_duration) is Some(_) {
    code + maybe_duration
  } else {
    code
  }
}

///|
/// Parses a CMX-style event line with four timecode fields.
///
/// Accepts both the standard 8-field format and the 9-field variant where
/// dissolve/wipe transitions are split into a code and frame-count token
/// (e.g. `D 050`).
pub fn EdlEvent::parse(
  raw : String,
  rate : FrameRate,
) -> Result[EdlEvent, TimecodeInteropError] {
  let fields = split_edl_fields(raw)
  // Normalize 9-field dissolve lines into 8 fields.
  let fields : Array[String] = if fields.length() == 9 &&
    (fields[3] == "D" || fields[3] == "W" || fields[3] == "K") {
    let transition = merge_dissolve_transition(fields[3], fields[4])
    [
      fields[0],
      fields[1],
      fields[2],
      transition,
      fields[5],
      fields[6],
      fields[7],
      fields[8],
    ]
  } else {
    fields
  }
  match fields {
    [
      event_number,
      reel,
      track,
      transition,
      source_in,
      source_out,
      record_in,
      record_out,
    ] =>
      match parse_int(event_number) {
        Some(event_number) => {
          let source_start = edl_parse_timecode(source_in, rate)
          let source_end = edl_parse_timecode(source_out, rate)
          let record_start = edl_parse_timecode(record_in, rate)
          let record_end = edl_parse_timecode(record_out, rate)
          match (source_start, source_end, record_start, record_end) {
            (Ok(source_start), Ok(source_end), Ok(record_start), Ok(record_end)) =>
              match
                (
                  edl_range(source_start, source_end),
                  edl_range(record_start, record_end),
                ) {
                (Ok(source), Ok(record)) =>
                  Ok({
                    event_number,
                    reel,
                    track,
                    transition,
                    source,
                    record,
                    clip_name: None,
                    comment: None,
                    source_file: None,
                  })
                (Err(error), _) => Err(error)
                (_, Err(error)) => Err(error)
              }
            (Err(error), _, _, _) => Err(error)
            (_, Err(error), _, _) => Err(error)
            (_, _, Err(error), _) => Err(error)
            (_, _, _, Err(error)) => Err(error)
          }
        }
        None => Err(InvalidEdlEvent)
      }
    _ => Err(InvalidEdlEvent)
  }
}

///|
/// Formats this event as a compact single-line EDL record.
pub fn EdlEvent::format(self : EdlEvent) -> String {
  "\{pad3(self.event_number)} \{self.reel} \{self.track} \{self.transition} \{self.source.start.format()} \{self.source.end.format()} \{self.record.start.format()} \{self.record.end.format()}"
}
