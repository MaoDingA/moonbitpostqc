///|
fn user_confusion_pairs(
  user_terms : @qc.UserTermsFile?,
) -> Array[@qc.ConfusionPair] {
  match user_terms {
    Some(t) => t.confusion_pairs
    None => []
  }
}

///|
fn user_consistency_terms(
  user_terms : @qc.UserTermsFile?,
) -> Array[@qc.ConsistencyTerm] {
  match user_terms {
    Some(t) => t.consistency_terms
    None => []
  }
}

///|
fn user_terms_only(user_terms : @qc.UserTermsFile?) -> Array[@qc.UserTerm] {
  match user_terms {
    Some(t) => t.user_terms
    None => []
  }
}

///|
pub fn check_creator_cues(
  cues : Array[@subtitle.Cue],
  profile : CreatorProfile,
  user_terms : @qc.UserTermsFile?,
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
  // 术语词库检测 — 默认 + 用户自定义
  let confusion = @qc.default_confusion_pairs_list() +
    user_confusion_pairs(user_terms)
  let consistency = @qc.default_consistency_terms_list() +
    user_consistency_terms(user_terms)
  let user = user_terms_only(user_terms)
  for issue in @qc.check_terminology_cues(cues, confusion, consistency, user) {
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

///|
pub(all) struct CueCleanResult {
  cues : Array[@subtitle.Cue]
  actions : Array[@qc.CleanAction]
} derive(Eq, Debug)

///|
pub fn CueCleanResult::total_actions(self : CueCleanResult) -> Int {
  self.actions.length()
}

///|
pub fn clean_creator_line(
  text : String,
  profile : CreatorProfile,
  user_terms : @qc.UserTermsFile?,
) -> @qc.LineCleanResult {
  let mode = profile.text_style.mode
  let markers = @qc.default_asr_markers_list()
  let pairs = @qc.default_confusion_pairs_list() +
    user_confusion_pairs(user_terms)

  // Step 1: fix repeated words
  let step1 = @qc.fix_repeated_words_line(text, mode)
  // Step 2: remove ASR markers
  let step2 = @qc.fix_asr_markers_line(step1.text, markers)
  // Step 3: fix confusion pairs (defaults + user)
  let step3 = @qc.fix_confusion_pairs_line(step2.text, pairs)
  // Step 4: normalize punctuation
  let normalized = @qc.normalize_punctuation(step3.text, mode~)

  let all_actions = step1.actions + step2.actions + step3.actions
  { text: normalized, actions: all_actions }
}

///|
pub fn clean_creator_cues(
  cues : Array[@subtitle.Cue],
  profile : CreatorProfile,
  user_terms : @qc.UserTermsFile?,
) -> CueCleanResult {
  let cleaned_cues : Array[@subtitle.Cue] = []
  let all_actions : Array[@qc.CleanAction] = []
  for cue in cues {
    let text : Array[String] = []
    for line in cue.text {
      let result = clean_creator_line(line, profile, user_terms)
      text.push(result.text)
      for action in result.actions {
        all_actions.push(action)
      }
    }
    cleaned_cues.push({
      index: cue.index,
      identifier: cue.identifier,
      start_ms: cue.start_ms,
      end_ms: cue.end_ms,
      text,
      settings: cue.settings,
    })
  }
  { cues: cleaned_cues, actions: all_actions }
}
