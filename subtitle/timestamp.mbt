///|
fn split_to_strings(raw : String, separator : String) -> Array[String] {
  let parts : Array[String] = []
  for part in raw.split(separator) {
    parts.push(part.to_owned())
  }
  parts
}

///|
fn parse_int(raw : String) -> Int? {
  Some(@string.parse_int(raw)) catch {
    _ => None
  }
}

///|
pub fn parse_timestamp_ms(raw : String) -> Int? {
  let normalized = if raw.contains(",") {
    split_to_strings(raw, ",")
  } else {
    split_to_strings(raw, ".")
  }
  match normalized {
    [clock, millis] =>
      match split_to_strings(clock, ":") {
        [hour, minute, second] =>
          match
            (
              parse_int(hour),
              parse_int(minute),
              parse_int(second),
              parse_int(millis),
            ) {
            (Some(hour), Some(minute), Some(second), Some(millis)) =>
              if hour >= 0 &&
                minute >= 0 &&
                minute < 60 &&
                second >= 0 &&
                second < 60 &&
                millis >= 0 &&
                millis < 1000 {
                Some(((hour * 60 + minute) * 60 + second) * 1000 + millis)
              } else {
                None
              }
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
fn pad2(value : Int) -> String {
  if value < 10 {
    "0\{value}"
  } else {
    "\{value}"
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
fn format_timestamp(ms : Int, separator : String) -> String {
  let safe_ms = if ms < 0 { 0 } else { ms }
  let millis = safe_ms % 1000
  let total_seconds = safe_ms / 1000
  let second = total_seconds % 60
  let total_minutes = total_seconds / 60
  let minute = total_minutes % 60
  let hour = total_minutes / 60
  "\{pad2(hour)}:\{pad2(minute)}:\{pad2(second)}\{separator}\{pad3(millis)}"
}

///|
pub fn format_srt_timestamp(ms : Int) -> String {
  format_timestamp(ms, ",")
}

///|
pub fn format_vtt_timestamp(ms : Int) -> String {
  format_timestamp(ms, ".")
}

///|
/// Parse ASS/SSA centisecond timestamp (H:MM:SS.CC) to milliseconds.
/// ASS uses centiseconds (2 digits), not milliseconds.
pub fn parse_ass_timestamp_ms(raw : String) -> Int? {
  let parts = split_to_strings(raw, ".")
  match parts {
    [clock, cs_raw] =>
      match split_to_strings(clock, ":") {
        [hour, minute, second] =>
          match
            (
              parse_int(hour),
              parse_int(minute),
              parse_int(second),
              parse_int(cs_raw),
            ) {
            (Some(hour), Some(minute), Some(second), Some(cs)) =>
              if minute >= 0 &&
                minute < 60 &&
                second >= 0 &&
                second < 60 &&
                cs >= 0 &&
                cs < 100 {
                // centiseconds -> milliseconds: multiply by 10
                Some(((hour * 60 + minute) * 60 + second) * 1000 + cs * 10)
              } else {
                None
              }
            _ => None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// Format milliseconds as ASS/SSA centisecond timestamp (H:MM:SS.CC).
pub fn format_ass_timestamp(ms : Int) -> String {
  let safe_ms = if ms < 0 { 0 } else { ms }
  // Round to nearest centisecond
  let cs = (safe_ms + 5) / 10
  let centis = cs % 100
  let total_seconds = cs / 100
  let second = total_seconds % 60
  let total_minutes = total_seconds / 60
  let minute = total_minutes % 60
  let hour = total_minutes / 60
  "\{hour}:\{pad2(minute)}:\{pad2(second)}.\{pad2(centis)}"
}
