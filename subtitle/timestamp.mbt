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
