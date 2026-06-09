///|
test "detect repeated Chinese words" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["然后然后我们就出发了"],
      settings: "",
    },
  ]
  let issues = check_ai_clean_cues(
    cues,
    TextStyleZh,
    default_asr_markers_list(),
    default_filler_words_list(TextStyleZh),
  )
  let mut saw_repeat = false
  for issue in issues {
    if issue.code == "C601" && issue.message.contains("然后") {
      saw_repeat = true
    }
  }
  assert_true(saw_repeat)
}

///|
test "detect repeated English words" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["and and then we went"],
      settings: "",
    },
  ]
  let issues = check_ai_clean_cues(
    cues,
    TextStyleEn,
    default_asr_markers_list(),
    default_filler_words_list(TextStyleEn),
  )
  let mut saw_repeat = false
  for issue in issues {
    if issue.code == "C601" {
      saw_repeat = true
    }
  }
  assert_true(saw_repeat)
}

///|
test "detect ASR markers" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["[Music] Welcome to the show"],
      settings: "",
    },
  ]
  let issues = check_ai_clean_cues(
    cues,
    TextStyleEn,
    default_asr_markers_list(),
    default_filler_words_list(TextStyleEn),
  )
  let mut saw_asr = false
  for issue in issues {
    if issue.code == "C602" {
      saw_asr = true
    }
  }
  assert_true(saw_asr)
}

///|
test "detect filler words above threshold" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 5000,
      text: ["然后然后然后我们终于到了"],
      settings: "",
    },
  ]
  let issues = check_ai_clean_cues(
    cues,
    TextStyleZh,
    default_asr_markers_list(),
    default_filler_words_list(TextStyleZh),
  )
  let mut saw_filler = false
  for issue in issues {
    if issue.code == "C603" {
      saw_filler = true
    }
  }
  assert_true(saw_filler)
}

///|
test "no false positive for normal text" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["这是一句正常的字幕"],
      settings: "",
    },
  ]
  let issues = check_ai_clean_cues(
    cues,
    TextStyleZh,
    default_asr_markers_list(),
    default_filler_words_list(TextStyleZh),
  )
  let mut c_count = 0
  for issue in issues {
    if issue.code.has_prefix("C6") {
      c_count += 1
    }
  }
  assert_eq(c_count, 0)
}
