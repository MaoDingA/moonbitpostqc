///|
fn parse_subtitle_text(input : String) -> @subtitle.SubtitleTrack? {
  match @subtitle.parse_srt(input) {
    Some(track) => Some(track)
    None => @subtitle.parse_webvtt(input)
  }
}

///|
fn profile_from_name(name : String) -> @qc.QcProfile {
  match @qc.profile_by_name(name) {
    Some(profile) => profile
    None => @qc.default_profile()
  }
}

///|
pub fn qc_subtitle(input : String, profile_name : String) -> String {
  match parse_subtitle_text(input) {
    Some(track) => {
      let profile = profile_from_name(profile_name)
      @qc.format_report(
        "uploaded subtitle",
        @qc.check_cues(track.cues, profile),
      ).join("\n")
    }
    None =>
      [
        "uploaded subtitle", "summary: 1 error, 0 warnings", "", "ERROR E000 | could not parse subtitle text",
      ].join("\n")
  }
}

///|
pub fn creator_check(input : String, profile_name : String) -> String {
  match parse_subtitle_text(input) {
    Some(track) =>
      match @creator.creator_profile_by_name(profile_name) {
        Some(profile) =>
          @qc.format_report(
            "uploaded subtitle",
            @creator.check_creator_cues(track.cues, profile, None),
          ).join("\n")
        None =>
          [
            "uploaded subtitle",
            "summary: 1 error, 0 warnings",
            "",
            "ERROR E000 | unknown creator profile: \{profile_name}",
          ].join("\n")
      }
    None =>
      [
        "uploaded subtitle", "summary: 1 error, 0 warnings", "", "ERROR E000 | could not parse subtitle text",
      ].join("\n")
  }
}

///|
pub fn creator_clean(input : String, profile_name : String) -> String {
  match parse_subtitle_text(input) {
    Some(track) =>
      match @creator.creator_profile_by_name(profile_name) {
        Some(profile) => {
          let result = @creator.clean_creator_cues(track.cues, profile, None)
          let lines : Array[String] = []
          lines.push("Clean summary:")
          if result.actions.length() == 0 {
            lines.push("  No changes applied.")
          } else {
            for action in result.actions {
              lines.push("  \{action.describe()}")
            }
            lines.push("\{result.actions.length()} action(s) applied.")
          }
          lines.push("---")
          // Write cleaned subtitle
          match track.format {
            @subtitle.Srt =>
              lines.push(
                @subtitle.write_srt({ format: track.format, cues: result.cues }),
              )
            @subtitle.WebVtt =>
              lines.push(
                @subtitle.write_webvtt({
                  format: track.format,
                  cues: result.cues,
                }),
              )
          }
          lines.join("\n")
        }
        None => "ERROR: unknown creator profile: \{profile_name}"
      }
    None => "ERROR: could not parse subtitle text"
  }
}

///|
fn make_profile_with_fps(
  profile : @qc.QcProfile,
  fps_str : String,
) -> @qc.QcProfile {
  match @timecode.FrameRate::parse(fps_str) {
    Some(rate) =>
      {
        max_cpl: profile.max_cpl,
        max_cps: profile.max_cps,
        max_lines: profile.max_lines,
        min_duration_ms: profile.min_duration_ms,
        max_duration_ms: profile.max_duration_ms,
        min_gap_frames: profile.min_gap_frames,
        frame_rate: Some(rate),
      }
    None => profile
  }
}

///|
pub fn delivery_check(
  input : String,
  profile_name : String,
  fps_str : String,
) -> String {
  match parse_subtitle_text(input) {
    Some(track) =>
      match @delivery.delivery_subtitle_profile_by_name(profile_name) {
        Some(sub_profile) => {
          let effective = make_profile_with_fps(sub_profile.qc_profile, fps_str)
          @qc.format_report(
            "uploaded subtitle",
            @qc.check_cues(track.cues, effective),
          ).join("\n")
        }
        None =>
          [
            "uploaded subtitle",
            "summary: 1 error, 0 warnings",
            "",
            "ERROR E000 | unknown delivery profile: \{profile_name}",
          ].join("\n")
      }
    None =>
      [
        "uploaded subtitle", "summary: 1 error, 0 warnings", "", "ERROR E000 | could not parse subtitle text",
      ].join("\n")
  }
}
