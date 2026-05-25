///|
/// Common frame-rate assumptions used by SMPTE-style timecode labels.
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
/// A SMPTE-style timecode label at a specific frame rate.
///
/// `Timecode` is a position label, not a duration. Use `Duration` for spans.
pub(all) struct Timecode {
  hour : Int
  minute : Int
  second : Int
  frame : Int
  rate : FrameRate
} derive(Eq, Debug)

///|
/// Returns the integer frame count used by labels for this rate.
///
/// NTSC fractional rates such as 23.976 return their nominal integer base
/// (`24`) because SMPTE labels still count frames within a nominal second.
pub fn FrameRate::nominal_fps(self : FrameRate) -> Int {
  match self {
    Fps23976 | Fps24 => 24
    Fps25 => 25
    Fps2997Drop | Fps2997NonDrop | Fps30 => 30
    Fps50 => 50
    Fps5994Drop | Fps5994NonDrop => 60
  }
}

///|
/// Returns a stable display label for the frame rate.
pub fn FrameRate::label(self : FrameRate) -> String {
  match self {
    Fps23976 => "23.976fps"
    Fps24 => "24fps"
    Fps25 => "25fps"
    Fps2997Drop => "29.97df"
    Fps2997NonDrop => "29.97fps"
    Fps30 => "30fps"
    Fps50 => "50fps"
    Fps5994Drop => "59.94df"
    Fps5994NonDrop => "59.94fps"
  }
}

///|
fn normalize_frame_rate_label(raw : String) -> String {
  raw
  .trim()
  .to_owned()
  .to_lower()
  .replace_all(old=" ", new="")
  .replace_all(old="_", new="")
  .replace_all(old="-", new="")
  .replace_all(old="fps", new="")
}

///|
/// Parses common frame-rate labels used by command lines and media metadata.
///
/// Drop-frame labels require an explicit `df` or `drop` suffix; plain
/// `29.97` and `59.94` parse as non-drop-frame rates.
pub fn FrameRate::parse(raw : String) -> FrameRate? {
  match normalize_frame_rate_label(raw) {
    "23.976" | "23.98" | "23976" | "2398" => Some(Fps23976)
    "24" => Some(Fps24)
    "25" => Some(Fps25)
    "29.97df" | "29.97drop" | "2997df" | "2997drop" => Some(Fps2997Drop)
    "29.97" | "29.97ndf" | "2997" | "2997ndf" => Some(Fps2997NonDrop)
    "30" => Some(Fps30)
    "50" => Some(Fps50)
    "59.94df" | "59.94drop" | "5994df" | "5994drop" => Some(Fps5994Drop)
    "59.94" | "59.94ndf" | "5994" | "5994ndf" => Some(Fps5994NonDrop)
    _ => None
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
/// Returns the exact frames-per-second numerator.
pub fn FrameRate::fps_numerator(self : FrameRate) -> Int {
  self.numerator()
}

///|
/// Returns the exact frames-per-second denominator.
pub fn FrameRate::fps_denominator(self : FrameRate) -> Int {
  self.denominator()
}

///|
/// Returns true for rates whose labels skip frame numbers each minute except
/// every tenth minute.
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
/// Returns the rounded duration of one frame in milliseconds.
pub fn FrameRate::frame_duration_ms(self : FrameRate) -> Int {
  (self.denominator() * 1000 + self.numerator() / 2) / self.numerator()
}

///|
/// Converts a frame span to milliseconds using the exact rate ratio and
/// nearest-integer rounding.
pub fn FrameRate::frames_to_ms(self : FrameRate, frames : Int) -> Int {
  scale_rounded(frames, self.denominator() * 1000, self.numerator())
}

///|
/// Converts milliseconds to frames using the exact rate ratio and
/// nearest-integer rounding.
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
fn timecode_validation_error(
  hour : Int,
  minute : Int,
  second : Int,
  frame : Int,
  rate : FrameRate,
  uses_semicolon : Bool,
) -> TimecodeParseError? {
  if hour < 0 {
    Some(OutOfRange("hour"))
  } else if minute < 0 || minute >= 60 {
    Some(OutOfRange("minute"))
  } else if second < 0 || second >= 60 {
    Some(OutOfRange("second"))
  } else if frame < 0 || frame >= rate.nominal_fps() {
    Some(OutOfRange("frame"))
  } else if uses_semicolon != rate.is_drop_frame() {
    Some(InvalidSeparator)
  } else if rate.is_drop_frame() &&
    second == 0 &&
    minute % 10 != 0 &&
    frame < rate.drop_frames_per_minute() {
    Some(InvalidDropFrameLabel)
  } else {
    None
  }
}

///|
fn parsed_timecode_or_error(
  hour : String,
  minute : String,
  second : String,
  frame : String,
  rate : FrameRate,
  uses_semicolon : Bool,
) -> Result[Timecode, TimecodeParseError] {
  match
    (parse_int(hour), parse_int(minute), parse_int(second), parse_int(frame)) {
    (Some(hour), Some(minute), Some(second), Some(frame)) =>
      match
        timecode_validation_error(
          hour, minute, second, frame, rate, uses_semicolon,
        ) {
        Some(error) => Err(error)
        None => Ok({ hour, minute, second, frame, rate })
      }
    _ => Err(InvalidNumber)
  }
}

///|
/// Parses a SMPTE-style timecode string and returns a structured error on
/// failure.
///
/// Non-drop-frame rates use `HH:MM:SS:FF`; drop-frame rates use
/// `HH:MM:SS;FF`. Drop-frame labels reject skipped frame numbers such as
/// `00:01:00;00` at 29.97df.
pub fn parse_timecode_result(
  raw : String,
  rate : FrameRate,
) -> Result[Timecode, TimecodeParseError] {
  let semicolon_parts = split_to_strings(raw, ";")
  if semicolon_parts.length() == 2 {
    let left = split_to_strings(semicolon_parts[0], ":")
    match left {
      [hour, minute, second] =>
        parsed_timecode_or_error(
          hour,
          minute,
          second,
          semicolon_parts[1],
          rate,
          true,
        )
      _ => Err(InvalidFormat)
    }
  } else if semicolon_parts.length() == 1 {
    let parts = split_to_strings(raw, ":")
    match parts {
      [hour, minute, second, frame] =>
        parsed_timecode_or_error(hour, minute, second, frame, rate, false)
      _ => Err(InvalidFormat)
    }
  } else {
    Err(InvalidFormat)
  }
}

///|
/// Parses a SMPTE-style timecode string, returning `None` on any error.
///
/// Use `parse_timecode_result` when callers need to distinguish formatting,
/// numeric range, separator, and drop-frame label errors.
pub fn parse_timecode(raw : String, rate : FrameRate) -> Timecode? {
  match parse_timecode_result(raw, rate) {
    Ok(tc) => Some(tc)
    Err(_) => None
  }
}

///|
/// Converts a timecode label to an absolute frame count at its own rate.
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
/// Converts an absolute frame count to a timecode label at this rate.
///
/// Negative frame counts saturate to `00:00:00:00`.
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
/// Formats the label as `HH:MM:SS:FF` or `HH:MM:SS;FF`.
pub fn Timecode::format(self : Timecode) -> String {
  let separator = if self.rate.is_drop_frame() { ";" } else { ":" }
  "\{pad2(self.hour)}:\{pad2(self.minute)}:\{pad2(self.second)}\{separator}\{pad2(self.frame)}"
}

///|
/// Adds frames to this position. Negative results saturate at zero.
pub fn Timecode::add_frames(self : Timecode, frames : Int) -> Timecode {
  self.rate.frames_to_timecode(self.to_frames() + frames)
}

///|
/// Subtracts frames from this position. Negative results saturate at zero.
pub fn Timecode::sub_frames(self : Timecode, frames : Int) -> Timecode {
  self.add_frames(-frames)
}

///|
/// Adds a duration at the same frame rate.
pub fn Timecode::add_duration(
  self : Timecode,
  duration : Duration,
) -> Timecode? {
  if self.rate == duration.rate {
    Some(self.add_frames(duration.frames))
  } else {
    None
  }
}

///|
/// Subtracts a duration at the same frame rate.
pub fn Timecode::sub_duration(
  self : Timecode,
  duration : Duration,
) -> Timecode? {
  if self.rate == duration.rate {
    Some(self.sub_frames(duration.frames))
  } else {
    None
  }
}

///|
/// Returns `other - self` in frames when both labels use the same frame rate.
pub fn Timecode::frame_distance(self : Timecode, other : Timecode) -> Int? {
  if self.rate == other.rate {
    Some(other.to_frames() - self.to_frames())
  } else {
    None
  }
}

///|
/// Compares two labels by frame count when both use the same frame rate.
pub fn Timecode::is_before(self : Timecode, other : Timecode) -> Bool? {
  match self.frame_distance(other) {
    Some(distance) => Some(distance > 0)
    None => None
  }
}

///|
/// Compares two labels by frame count when both use the same frame rate.
pub fn Timecode::is_after(self : Timecode, other : Timecode) -> Bool? {
  match self.frame_distance(other) {
    Some(distance) => Some(distance < 0)
    None => None
  }
}

///|
/// Converts a timecode label to another frame-rate assumption using exact
/// frame-rate ratios and nearest-integer rounding.
pub fn convert_timecode(source : Timecode, target_rate : FrameRate) -> Timecode {
  target_rate.frames_to_timecode(
    scale_rounded(
      source.to_frames(),
      source.rate.denominator() * target_rate.numerator(),
      source.rate.numerator() * target_rate.denominator(),
    ),
  )
}

///|
/// Rescales a millisecond value between frame-rate assumptions using exact
/// frame-rate ratios and nearest-integer rounding.
pub fn rescale_ms_between_rates(
  ms : Int,
  source_rate : FrameRate,
  target_rate : FrameRate,
) -> Int {
  let numerator = source_rate.numerator() * target_rate.denominator()
  let denominator = source_rate.denominator() * target_rate.numerator()
  scale_rounded(ms, numerator, denominator)
}
