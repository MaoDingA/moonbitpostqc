///|
pub(all) enum Severity {
  Error
  Warning
} derive(Eq, Debug)

///|
pub(all) struct QcProfile {
  max_cpl : Int?
  max_cps : Int
  max_lines : Int
  min_duration_ms : Int
  max_duration_ms : Int
  min_gap_frames : Int
  frame_rate : @timecode.FrameRate?
  /// Maximum Words Per Second (for Latin-script text). None disables WPS check.
  max_wps : Int?
  /// Maximum allowed ratio between the longest and shortest line in a cue.
  /// None disables the line imbalance check (W208).
  max_line_imbalance : Int?
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
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: None,
    max_wps: None,
    max_line_imbalance: Some(2),
  }
}

///|
pub fn streaming_profile() -> QcProfile {
  {
    max_cpl: Some(42),
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(Fps25),
    max_wps: Some(3),
    max_line_imbalance: Some(2),
  }
}

///|
pub fn cinema_profile() -> QcProfile {
  {
    max_cpl: Some(32),
    max_cps: 17,
    max_lines: 2,
    min_duration_ms: 1000,
    max_duration_ms: 6000,
    min_gap_frames: 2,
    frame_rate: Some(Fps24),
    max_wps: Some(3),
    max_line_imbalance: Some(2),
  }
}

///|
pub fn social_video_profile() -> QcProfile {
  {
    max_cpl: Some(30),
    max_cps: 24,
    max_lines: 2,
    min_duration_ms: 500,
    max_duration_ms: 5000,
    min_gap_frames: 1,
    frame_rate: Some(Fps30),
    max_wps: Some(4),
    max_line_imbalance: None,
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
