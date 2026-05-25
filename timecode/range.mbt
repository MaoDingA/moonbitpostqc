///|
/// A half-open interval `[start, end)` on a single frame-rate timeline.
pub(all) struct TimecodeRange {
  start : Timecode
  end : Timecode
} derive(Eq, Debug)

///|
fn TimecodeRange::is_valid(self : TimecodeRange) -> Bool {
  self.start.rate == self.end.rate &&
  self.end.to_frames() >= self.start.to_frames()
}

///|
/// Creates a half-open timecode range when both endpoints share a frame rate
/// and `end` is not before `start`.
pub fn TimecodeRange::new(start : Timecode, end : Timecode) -> TimecodeRange? {
  let range = { start, end }
  if range.is_valid() {
    Some(range)
  } else {
    None
  }
}

///|
/// Returns the frame span of this range, or `None` if the range was manually
/// constructed with incompatible endpoints.
pub fn TimecodeRange::duration(self : TimecodeRange) -> Duration? {
  if self.is_valid() {
    Some(
      Duration::from_frames(
        self.end.to_frames() - self.start.to_frames(),
        self.start.rate,
      ),
    )
  } else {
    None
  }
}

///|
/// Tests whether `value` is inside this half-open range.
pub fn TimecodeRange::contains(self : TimecodeRange, value : Timecode) -> Bool? {
  if !self.is_valid() || value.rate != self.start.rate {
    None
  } else {
    let frame = value.to_frames()
    Some(frame >= self.start.to_frames() && frame < self.end.to_frames())
  }
}

///|
/// Tests whether two half-open ranges overlap on the same frame-rate timeline.
pub fn TimecodeRange::overlaps(
  self : TimecodeRange,
  other : TimecodeRange,
) -> Bool? {
  if !self.is_valid() ||
    !other.is_valid() ||
    self.start.rate != other.start.rate {
    None
  } else {
    Some(
      self.start.to_frames() < other.end.to_frames() &&
      other.start.to_frames() < self.end.to_frames(),
    )
  }
}

///|
/// Shifts both endpoints by a duration at the same frame rate.
pub fn TimecodeRange::shift(
  self : TimecodeRange,
  duration : Duration,
) -> TimecodeRange? {
  if !self.is_valid() || duration.rate != self.start.rate {
    None
  } else {
    TimecodeRange::new(
      self.start.add_frames(duration.frames),
      self.end.add_frames(duration.frames),
    )
  }
}
