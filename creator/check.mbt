///|
pub fn check_creator_cues(
  cues : Array[@subtitle.Cue],
  profile : CreatorProfile,
) -> Array[@qc.QcIssue] {
  let issues = @qc.check_cues_with_text_style(
    cues,
    profile.qc_profile,
    profile.text_style,
  )
  // AI 字幕清洗检测
  for
    issue in @qc.check_ai_clean_cues(
      cues,
      profile.text_style.mode,
      @qc.default_asr_markers_list(),
      @qc.default_filler_words_list(profile.text_style.mode),
    ) {
    issues.push(issue)
  }
  // 术语词库检测
  for
    issue in @qc.check_terminology_cues(
      cues,
      @qc.default_confusion_pairs_list(),
      @qc.default_consistency_terms_list(),
      [],
    ) {
    issues.push(issue)
  }
  issues
}

///|
pub fn normalize_creator_line(
  text : String,
  profile : CreatorProfile,
) -> String {
  @qc.normalize_punctuation(text, mode=profile.punctuation_mode)
}
