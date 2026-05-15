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
