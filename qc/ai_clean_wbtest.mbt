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

///|
test "clean action describe formats readable diff" {
  let action = CleanAction::{
    code: "C601",
    original: "然后然后",
    replacement: "然后",
  }
  assert_eq(action.describe(), "C601: '然后然后' → '然后'")
}

///|
test "line clean result knows when nothing changed" {
  let clean = LineCleanResult::{ text: "你好世界", actions: [] }
  assert_true(clean.is_clean())
}

///|
test "line clean result detects changes" {
  let dirty = LineCleanResult::{
    text: "你好",
    actions: [
      CleanAction::{ code: "C401", original: "登陆", replacement: "登录" },
    ],
  }
  assert_false(dirty.is_clean())
}

///|
test "fix repeated zh words collapses adjacent duplicates" {
  let result = fix_repeated_words_line(
    "然后然后我们今天来",
    TextStyleZh,
  )
  assert_eq(result.text, "然后我们今天来")
  assert_true(result.actions.length() > 0)
  assert_true(result.actions[0].code == "C601")
}

///|
test "fix repeated en words collapses adjacent duplicates" {
  let result = fix_repeated_words_line(
    "the the quick brown fox fox",
    TextStyleEn,
  )
  assert_false(result.text.contains("the the"))
  assert_false(result.text.contains("fox fox"))
  assert_true(result.actions.length() >= 2)
}

///|
test "fix repeated words leaves clean text untouched" {
  let result = fix_repeated_words_line("今天天气很好", TextStyleZh)
  assert_true(result.is_clean())
  assert_eq(result.text, "今天天气很好")
}

///|
test "fix repeated words bilingual fixes both" {
  let result = fix_repeated_words_line(
    "然后然后 the the quick brown fox",
    TextStyleBilingual,
  )
  assert_false(result.text.contains("然后然后"))
  assert_false(result.text.contains("the the"))
}

///|
test "fix asr markers removes bracket markers" {
  let result = fix_asr_markers_line(
    "[Music] 然后呢我们开始",
    default_asr_markers_list(),
  )
  assert_eq(result.text, "然后呢我们开始")
  assert_true(result.actions.length() > 0)
  assert_true(result.actions[0].code == "C602")
}

///|
test "fix asr markers removes parenthesized markers" {
  let result = fix_asr_markers_line(
    "大家好(applause)继续",
    default_asr_markers_list(),
  )
  assert_eq(result.text, "大家好继续")
}

///|
test "fix asr markers leaves clean text untouched" {
  let result = fix_asr_markers_line(
    "这是一句正常的话",
    default_asr_markers_list(),
  )
  assert_true(result.is_clean())
  assert_eq(result.text, "这是一句正常的话")
}

///|
test "fix asr markers handles multiple markers" {
  let result = fix_asr_markers_line(
    "[Music][applause]继续",
    default_asr_markers_list(),
  )
  assert_eq(result.text, "继续")
  assert_true(result.actions.length() >= 2)
}

///|
test "fix asr markers strips whitespace after removal" {
  let result = fix_asr_markers_line(
    "  [Music]  你好  ",
    default_asr_markers_list(),
  )
  assert_eq(result.text, "你好")
}
