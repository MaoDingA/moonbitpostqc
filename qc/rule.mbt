///|
pub(all) enum Severity {
  Error
  Warning
} derive(Eq, Debug)

///|
pub(all) struct QcProfile {
  max_cpl : Int
  max_cps : Int
  max_lines : Int
  min_duration_ms : Int
  max_duration_ms : Int
  min_gap_frames : Int
  frame_rate : @timecode.FrameRate?
} derive(Eq, Debug)

///|
pub(all) struct QcIssue {
  severity : Severity
  code : String
  cue_index : Int?
  message : String
} derive(Eq, Debug)

///|
pub fn default_profile() -> QcProfile {
  {
    max_cpl: 42,
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: None,
  }
}

///|
pub fn streaming_profile() -> QcProfile {
  {
    max_cpl: 42,
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(@timecode.Fps25),
  }
}

///|
pub fn cinema_profile() -> QcProfile {
  {
    max_cpl: 32,
    max_cps: 17,
    max_lines: 2,
    min_duration_ms: 1000,
    max_duration_ms: 6000,
    min_gap_frames: 2,
    frame_rate: Some(@timecode.Fps24),
  }
}

///|
pub fn social_video_profile() -> QcProfile {
  {
    max_cpl: 30,
    max_cps: 24,
    max_lines: 2,
    min_duration_ms: 500,
    max_duration_ms: 5000,
    min_gap_frames: 1,
    frame_rate: Some(@timecode.Fps30),
  }
}

///|
pub fn profile_by_name(name : String) -> QcProfile? {
  match name {
    "default" => Some(default_profile())
    "streaming" => Some(streaming_profile())
    "cinema" => Some(cinema_profile())
    "social-video" | "social" => Some(social_video_profile())
    _ => None
  }
}
