///|
pub fn check_creator_cues(
  cues : Array[@subtitle.Cue],
  profile : CreatorProfile,
) -> Array[@qc.QcIssue] {
  @qc.check_cues_with_text_style(cues, profile.qc_profile, profile.text_style)
}

///|
pub fn normalize_creator_line(
  text : String,
  profile : CreatorProfile,
) -> String {
  @qc.normalize_punctuation(text, mode=profile.punctuation_mode)
}
