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

///|
test "fix confusion pairs replaces known wrong forms" {
  let result = fix_confusion_pairs_line(
    "认真的做好每一步",
    default_confusion_pairs_list(),
  )
  assert_eq(result.text, "认真地做好每一步")
  assert_true(result.actions.length() > 0)
  assert_true(result.actions[0].code == "C401")
  assert_true(result.actions[0].original == "认真的做")
  assert_true(result.actions[0].replacement == "认真地做")
}

///|
test "fix confusion pairs handles multiple replacements" {
  let result = fix_confusion_pairs_line(
    "认真的做好，偶而按装完成",
    default_confusion_pairs_list(),
  )
  assert_eq(result.text, "认真地做好，偶尔安装完成")
  assert_true(result.actions.length() == 3)
}

///|
test "fix confusion pairs leaves clean text untouched" {
  let result = fix_confusion_pairs_line(
    "今天天气很好",
    default_confusion_pairs_list(),
  )
  assert_true(result.is_clean())
}

///|
test "fix confusion pairs replaces de complement" {
  let result = fix_confusion_pairs_line(
    "跑的快",
    default_confusion_pairs_list(),
  )
  assert_eq(result.text, "跑得快")
}

///|
test "parse user terms file loads confusion pairs" {
  let raw =
    #|{
    #|  "confusion_pairs": [
    #|    { "wrong": "登陆", "correct": "登录", "context": "登录/登陆" },
    #|    { "wrong": "帐号", "correct": "账号", "context": "账号/帐号" }
    #|  ]
    #|}
  match parse_user_terms_file(raw) {
    Ok(terms) => {
      assert_eq(terms.confusion_pairs.length(), 2)
      assert_eq(terms.confusion_pairs[0].wrong, "登陆")
      assert_eq(terms.confusion_pairs[0].correct, "登录")
      assert_eq(terms.confusion_pairs[1].wrong, "帐号")
      assert_eq(terms.consistency_terms.length(), 0)
      assert_eq(terms.user_terms.length(), 0)
    }
    Err(message) => fail("parse failed: \{message}")
  }
}

///|
test "parse user terms file loads consistency terms" {
  let raw =
    #|{
    #|  "consistency_terms": [
    #|    { "canonical": "Vue", "variants": ["vue", "VUE"] },
    #|    { "canonical": "React", "variants": ["react"] }
    #|  ]
    #|}
  match parse_user_terms_file(raw) {
    Ok(terms) => {
      assert_eq(terms.consistency_terms.length(), 2)
      assert_eq(terms.consistency_terms[0].canonical, "Vue")
      assert_eq(terms.consistency_terms[0].variants.length(), 2)
      assert_eq(terms.confusion_pairs.length(), 0)
    }
    Err(message) => fail("parse failed: \{message}")
  }
}

///|
test "parse user terms file loads user terms with forbidden flag" {
  let raw =
    #|{
    #|  "user_terms": [
    #|    { "pattern": "老铁", "preferred": "朋友", "reason": "品牌调性", "forbidden": true },
    #|    { "pattern": "github", "preferred": "GitHub", "reason": "品牌大小写" }
    #|  ]
    #|}
  match parse_user_terms_file(raw) {
    Ok(terms) => {
      assert_eq(terms.user_terms.length(), 2)
      assert_true(terms.user_terms[0].forbidden)
      assert_false(terms.user_terms[1].forbidden)
      assert_eq(terms.user_terms[1].preferred, "GitHub")
    }
    Err(message) => fail("parse failed: \{message}")
  }
}

///|
test "parse user terms file handles empty object" {
  let raw = "{}"
  match parse_user_terms_file(raw) {
    Ok(terms) => {
      assert_eq(terms.confusion_pairs.length(), 0)
      assert_eq(terms.consistency_terms.length(), 0)
      assert_eq(terms.user_terms.length(), 0)
    }
    Err(message) => fail("parse failed: \{message}")
  }
}

///|
test "parse user terms file rejects invalid json" {
  let raw = "not json"
  match parse_user_terms_file(raw) {
    Ok(_) => fail("expected parse error")
    Err(message) => assert_true(message.contains("invalid terms file"))
  }
}

///|
test "parse user terms file skips entries missing required fields" {
  let raw =
    #|{
    #|  "confusion_pairs": [
    #|    { "wrong": "登陆" },
    #|    { "wrong": "帐号", "correct": "账号" }
    #|  ]
    #|}
  match parse_user_terms_file(raw) {
    Ok(terms) => {
      // First entry missing "correct" — skipped
      assert_eq(terms.confusion_pairs.length(), 1)
      assert_eq(terms.confusion_pairs[0].wrong, "帐号")
    }
    Err(message) => fail("parse failed: \{message}")
  }
}
