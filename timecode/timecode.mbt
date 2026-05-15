///|
pub(all) enum FrameRate {
  Fps23976
  Fps24
  Fps25
  Fps2997Drop
  Fps2997NonDrop
  Fps30
  Fps50
  Fps5994Drop
  Fps5994NonDrop
} derive(Eq, Debug)

///|
pub(all) struct Timecode {
  hour : Int
  minute : Int
  second : Int
  frame : Int
  rate : FrameRate
} derive(Eq, Debug)

///|
fn FrameRate::nominal_fps(self : FrameRate) -> Int {
  match self {
    Fps23976 | Fps24 => 24
    Fps25 => 25
    Fps2997Drop | Fps2997NonDrop | Fps30 => 30
    Fps50 => 50
    Fps5994Drop | Fps5994NonDrop => 60
  }
}

///|
fn FrameRate::numerator(self : FrameRate) -> Int {
  match self {
    Fps23976 => 24000
    Fps2997Drop | Fps2997NonDrop => 30000
    Fps5994Drop | Fps5994NonDrop => 60000
    Fps24 => 24
    Fps25 => 25
    Fps30 => 30
    Fps50 => 50
  }
}

///|
fn FrameRate::denominator(self : FrameRate) -> Int {
  match self {
    Fps23976 | Fps2997Drop | Fps2997NonDrop | Fps5994Drop | Fps5994NonDrop =>
      1001
    _ => 1
  }
}

///|
pub fn FrameRate::is_drop_frame(self : FrameRate) -> Bool {
  match self {
    Fps2997Drop | Fps5994Drop => true
    _ => false
  }
}

///|
fn FrameRate::drop_frames_per_minute(self : FrameRate) -> Int {
  match self {
    Fps2997Drop => 2
    Fps5994Drop => 4
    _ => 0
  }
}

///|
pub fn FrameRate::frame_duration_ms(self : FrameRate) -> Int {
  (self.denominator() * 1000 + self.numerator() / 2) / self.numerator()
}

///|
fn scale_rounded(value : Int, numerator : Int, denominator : Int) -> Int {
  if value < 0 {
    -scale_rounded(-value, numerator, denominator)
  } else {
    let scaled = Int64::from_int(value) * Int64::from_int(numerator)
    let divisor = Int64::from_int(denominator)
    ((scaled + divisor / Int64::from_int(2)) / divisor).to_int()
  }
}

///|
pub fn FrameRate::frames_to_ms(self : FrameRate, frames : Int) -> Int {
  scale_rounded(frames, self.denominator() * 1000, self.numerator())
}

///|
pub fn FrameRate::ms_to_frames(self : FrameRate, ms : Int) -> Int {
  scale_rounded(ms, self.numerator(), self.denominator() * 1000)
}

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
fn validate_timecode(
  hour : Int,
  minute : Int,
  second : Int,
  frame : Int,
  rate : FrameRate,
  uses_semicolon : Bool,
) -> Bool {
  if hour < 0 ||
    minute < 0 ||
    minute >= 60 ||
    second < 0 ||
    second >= 60 ||
    frame < 0 ||
    frame >= rate.nominal_fps() {
    false
  } else if uses_semicolon != rate.is_drop_frame() {
    false
  } else if rate.is_drop_frame() &&
    second == 0 &&
    minute % 10 != 0 &&
    frame < rate.drop_frames_per_minute() {
    false
  } else {
    true
  }
}

///|
pub fn parse_timecode(raw : String, rate : FrameRate) -> Timecode? {
  let semicolon_parts = split_to_strings(raw, ";")
  if semicolon_parts.length() == 2 {
    let left = split_to_strings(semicolon_parts[0], ":")
    match (left, parse_int(semicolon_parts[1])) {
      ([hour, minute, second], Some(frame)) =>
        match (parse_int(hour), parse_int(minute), parse_int(second)) {
          (Some(hour), Some(minute), Some(second)) =>
            if validate_timecode(hour, minute, second, frame, rate, true) {
              Some({ hour, minute, second, frame, rate })
            } else {
              None
            }
          _ => None
        }
      _ => None
    }
  } else if semicolon_parts.length() == 1 {
    let parts = split_to_strings(raw, ":")
    match parts {
      [hour, minute, second, frame] =>
        match
          (
            parse_int(hour),
            parse_int(minute),
            parse_int(second),
            parse_int(frame),
          ) {
          (Some(hour), Some(minute), Some(second), Some(frame)) =>
            if validate_timecode(hour, minute, second, frame, rate, false) {
              Some({ hour, minute, second, frame, rate })
            } else {
              None
            }
          _ => None
        }
      _ => None
    }
  } else {
    None
  }
}

///|
pub fn Timecode::to_frames(self : Timecode) -> Int {
  let nominal = self.rate.nominal_fps()
  let label_frames = (self.hour * 3600 + self.minute * 60 + self.second) *
    nominal +
    self.frame
  if self.rate.is_drop_frame() {
    let total_minutes = self.hour * 60 + self.minute
    let dropped = self.rate.drop_frames_per_minute() *
      (total_minutes - total_minutes / 10)
    label_frames - dropped
  } else {
    label_frames
  }
}

///|
pub fn FrameRate::frames_to_timecode(
  self : FrameRate,
  frames : Int,
) -> Timecode {
  let normalized = if frames < 0 { 0 } else { frames }
  let nominal = self.nominal_fps()
  let label_frames = if self.is_drop_frame() {
    let drop = self.drop_frames_per_minute()
    let frames_per_10_minutes = nominal * 60 * 10 - drop * 9
    let frames_per_first_minute = nominal * 60
    let frames_per_drop_minute = nominal * 60 - drop
    let ten_minute_blocks = normalized / frames_per_10_minutes
    let within_block = normalized % frames_per_10_minutes
    let extra_minutes = if within_block < frames_per_first_minute {
      0
    } else {
      1 + (within_block - frames_per_first_minute) / frames_per_drop_minute
    }
    let total_minutes = ten_minute_blocks * 10 + extra_minutes
    normalized + drop * (total_minutes - total_minutes / 10)
  } else {
    normalized
  }
  let frames_per_hour = nominal * 3600
  let frames_per_minute = nominal * 60
  let hour = label_frames / frames_per_hour
  let after_hour = label_frames % frames_per_hour
  let minute = after_hour / frames_per_minute
  let after_minute = after_hour % frames_per_minute
  let second = after_minute / nominal
  let frame = after_minute % nominal
  { hour, minute, second, frame, rate: self }
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
pub fn Timecode::format(self : Timecode) -> String {
  let separator = if self.rate.is_drop_frame() { ";" } else { ":" }
  "\{pad2(self.hour)}:\{pad2(self.minute)}:\{pad2(self.second)}\{separator}\{pad2(self.frame)}"
}

///|
pub fn convert_timecode(source : Timecode, target_rate : FrameRate) -> Timecode {
  let ms = source.rate.frames_to_ms(source.to_frames())
  target_rate.frames_to_timecode(target_rate.ms_to_frames(ms))
}

///|
pub fn rescale_ms_between_rates(
  ms : Int,
  source_rate : FrameRate,
  target_rate : FrameRate,
) -> Int {
  let numerator = source_rate.numerator() * target_rate.denominator()
  let denominator = source_rate.denominator() * target_rate.numerator()
  scale_rounded(ms, numerator, denominator)
}
