///|
pub(all) struct Duration {
  frames : Int
  rate : FrameRate
} derive(Eq, Debug)

///|
pub fn Duration::from_frames(frames : Int, rate : FrameRate) -> Duration {
  { frames, rate }
}

///|
pub fn Duration::from_ms(ms : Int, rate : FrameRate) -> Duration {
  { frames: rate.ms_to_frames(ms), rate }
}

///|
pub fn Duration::to_frames(self : Duration) -> Int {
  self.frames
}

///|
pub fn Duration::to_ms(self : Duration) -> Int {
  self.rate.frames_to_ms(self.frames)
}

///|
pub fn Duration::format(self : Duration) -> String {
  let formatted = self.rate.frames_to_timecode(abs_int(self.frames)).format()
  if self.frames < 0 {
    "-\{formatted}"
  } else {
    formatted
  }
}

///|
pub fn Duration::add(self : Duration, other : Duration) -> Duration? {
  if self.rate == other.rate {
    Some({ frames: self.frames + other.frames, rate: self.rate })
  } else {
    None
  }
}

///|
pub fn Duration::sub(self : Duration, other : Duration) -> Duration? {
  if self.rate == other.rate {
    Some({ frames: self.frames - other.frames, rate: self.rate })
  } else {
    None
  }
}

///|
pub fn Duration::scale(self : Duration, factor : Int) -> Duration {
  { frames: self.frames * factor, rate: self.rate }
}
