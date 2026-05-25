///|
/// A frame span at one explicit frame rate.
///
/// `Duration` is not a SMPTE position label. It represents elapsed frames and
/// may be negative.
pub(all) struct Duration {
  frames : Int
  rate : FrameRate
} derive(Eq, Debug)

///|
/// Creates a duration from an exact frame span.
pub fn Duration::from_frames(frames : Int, rate : FrameRate) -> Duration {
  { frames, rate }
}

///|
/// Creates a duration by converting milliseconds to frames with
/// nearest-integer rounding.
pub fn Duration::from_ms(ms : Int, rate : FrameRate) -> Duration {
  { frames: rate.ms_to_frames(ms), rate }
}

///|
/// Returns the stored frame span.
pub fn Duration::to_frames(self : Duration) -> Int {
  self.frames
}

///|
/// Converts this duration to milliseconds with nearest-integer rounding.
pub fn Duration::to_ms(self : Duration) -> Int {
  self.rate.frames_to_ms(self.frames)
}

///|
/// Formats this duration as `HH:MM:SS:FF` or `HH:MM:SS;FF`.
///
/// Negative durations use a leading `-` before the formatted absolute span.
pub fn Duration::format(self : Duration) -> String {
  let formatted = self.rate.frames_to_timecode(abs_int(self.frames)).format()
  if self.frames < 0 {
    "-\{formatted}"
  } else {
    formatted
  }
}

///|
/// Adds another duration when both use the same frame rate.
pub fn Duration::add(self : Duration, other : Duration) -> Duration? {
  if self.rate == other.rate {
    Some({ frames: self.frames + other.frames, rate: self.rate })
  } else {
    None
  }
}

///|
/// Subtracts another duration when both use the same frame rate.
pub fn Duration::sub(self : Duration, other : Duration) -> Duration? {
  if self.rate == other.rate {
    Some({ frames: self.frames - other.frames, rate: self.rate })
  } else {
    None
  }
}

///|
/// Multiplies the frame span by an integer while preserving the frame rate.
pub fn Duration::scale(self : Duration, factor : Int) -> Duration {
  { frames: self.frames * factor, rate: self.rate }
}
