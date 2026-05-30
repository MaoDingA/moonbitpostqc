///|
test "detect confusion pair 的/地/得" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["认真的做好了每一件事"],
      settings: "",
    },
  ]
  let issues = check_terminology_cues(
    cues,
    default_confusion_pairs_list(),
    default_consistency_terms_list(),
    [],
  )
  let mut saw_c401 = false
  for issue in issues {
    if issue.code == "C401" {
      saw_c401 = true
    }
  }
  assert_true(saw_c401)
}

///|
test "detect confusion pair 在/再" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["我们再一起吃饭"],
      settings: "",
    },
  ]
  let issues = check_terminology_cues(
    cues,
    default_confusion_pairs_list(),
    default_consistency_terms_list(),
    [],
  )
  let mut saw_c401 = false
  for issue in issues {
    if issue.code == "C401" {
      saw_c401 = true
    }
  }
  assert_true(saw_c401)
}

///|
test "detect term consistency across cues" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["MoonPost is great"],
      settings: "",
    },
    @subtitle.Cue::{
      index: Some(2),
      identifier: None,
      start_ms: 3000,
      end_ms: 5000,
      text: ["I love moonpost"],
      settings: "",
    },
  ]
  let issues = check_terminology_cues(
    cues,
    [],
    default_consistency_terms_list(),
    [],
  )
  let mut saw_c402 = false
  for issue in issues {
    if issue.code == "C402" {
      saw_c402 = true
    }
  }
  assert_true(saw_c402)
}

///|
test "user term check with warning" {
  let user_terms = [
    {
      pattern: "github",
      preferred: "GitHub",
      reason: "brand capitalization",
      forbidden: false,
    },
  ]
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["check out our github repo"],
      settings: "",
    },
  ]
  let issues = check_terminology_cues(cues, [], [], user_terms)
  let mut saw_c403 = false
  for issue in issues {
    if issue.code == "C403" {
      saw_c403 = true
      assert_true(issue.severity == Warning)
    }
  }
  assert_true(saw_c403)
}

///|
test "user term check with forbidden = Error" {
  let user_terms = [
    {
      pattern: "TODO",
      preferred: "remove before delivery",
      reason: "undone work",
      forbidden: true,
    },
  ]
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["TODO fix this later"],
      settings: "",
    },
  ]
  let issues = check_terminology_cues(cues, [], [], user_terms)
  let mut saw_c403_error = false
  for issue in issues {
    if issue.code == "C403" && issue.severity == Error {
      saw_c403_error = true
    }
  }
  assert_true(saw_c403_error)
}

///|
test "no false positive for clean terminology" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["认真地完成了所有任务"],
      settings: "",
    },
  ]
  let issues = check_terminology_cues(
    cues,
    default_confusion_pairs_list(),
    [],
    [],
  )
  assert_eq(issues.length(), 0)
}
