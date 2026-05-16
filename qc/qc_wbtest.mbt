///|
fn cue(
  index : Int,
  start_ms : Int,
  end_ms : Int,
  text : Array[String],
) -> @subtitle.Cue {
  { index: Some(index), identifier: None, start_ms, end_ms, text, settings: "" }
}

///|
test "qc reports overlaps duration line and speed issues" {
  let cues = [
    cue(1, 1000, 1500, [
      "This line is intentionally far too long for a conservative subtitle delivery profile.",
    ]),
    cue(2, 1400, 9000, ["Fast text fast text fast text fast text fast text"]),
    cue(3, 9100, 9100, [""]),
  ]
  let profile = streaming_profile()
  let issues = check_cues(cues, profile)
  assert_true(issues.any(issue => issue.code == "E101"))
  assert_true(issues.any(issue => issue.code == "E102"))
  assert_true(issues.any(issue => issue.code == "W203"))
  assert_true(issues.any(issue => issue.code == "W310"))
}

///|
test "qc catches frame alignment at 25fps" {
  let cues = [cue(1, 1123, 2000, ["Hello"])]
  let profile = QcProfile::{
    max_cpl: 42,
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(@timecode.Fps25),
  }
  let issues = check_cues(cues, profile)
  assert_true(issues.any(issue => issue.code == "W401"))
}

///|
test "human report includes filename and issue details" {
  let issues = [
    QcIssue::{
      severity: Error,
      code: "E101",
      cue_index: Some(42),
      message: "overlaps cue#43 by 160ms",
    },
  ]
  let report = format_report("movie.zh.srt", issues)
  assert_eq(report[0], "movie.zh.srt")
  assert_eq(report[1], "summary: 1 error, 0 warnings")
  assert_true(
    report[3].contains("ERROR E101 cue#42 | overlaps cue#43 by 160ms"),
  )
}

///|
test "json report includes summary and issue payload" {
  let issues = [
    QcIssue::{
      severity: Error,
      code: "E101",
      cue_index: Some(42),
      message: "overlaps cue#43 by 160ms",
    },
  ]
  let report = format_json_report("movie.zh.srt", issues)
  assert_true(report.contains("\"name\":\"movie.zh.srt\""))
  assert_true(report.contains("\"errors\":1"))
  assert_true(report.contains("\"severity\":\"error\""))
  assert_true(report.contains("\"cue_index\":42"))
}

///|
test "qc can detect whether issues contain errors" {
  assert_true(
    has_errors([
      QcIssue::{
        severity: Error,
        code: "E101",
        cue_index: Some(1),
        message: "overlap",
      },
    ]),
  )
  assert_false(
    has_errors([
      QcIssue::{
        severity: Warning,
        code: "W203",
        cue_index: Some(1),
        message: "line too long",
      },
    ]),
  )
}

///|
test "qc exposes named delivery profiles" {
  match profile_by_name("cinema") {
    Some(profile) => {
      assert_eq(profile.max_cpl, 32)
      assert_eq(profile.max_cps, 17)
      assert_true(profile.frame_rate == Some(@timecode.Fps24))
    }
    None => fail("expected cinema profile")
  }
  match profile_by_name("social-video") {
    Some(profile) => {
      assert_eq(profile.max_cpl, 30)
      assert_eq(profile.min_duration_ms, 500)
      assert_true(profile.frame_rate == Some(@timecode.Fps30))
    }
    None => fail("expected social-video profile")
  }
  assert_true(profile_by_name("unknown") is None)
}

///|
test "qc reports line count and small gap issues" {
  let profile = QcProfile::{
    max_cpl: 42,
    max_cps: 20,
    max_lines: 2,
    min_duration_ms: 800,
    max_duration_ms: 7000,
    min_gap_frames: 2,
    frame_rate: Some(@timecode.Fps25),
  }
  let issues = check_cues(
    [cue(1, 1000, 2000, ["one", "two", "three"]), cue(2, 2040, 3000, ["next"])],
    profile,
  )
  assert_true(issues.any(issue => issue.code == "W204"))
  assert_true(issues.any(issue => issue.code == "W402"))
}

///|
test "qc ok report has zero summary" {
  let report = format_report("clean.srt", [])
  assert_eq(report[1], "summary: 0 errors, 0 warnings")
  assert_true(report.any(line => line.contains("OK no issues found")))
}

///|
test "qc text style warnings are opt in" {
  let cues = [cue(1, 1000, 2500, ["你好, world！！"])]
  let issues = check_cues(cues, default_profile())
  assert_false(issues.any(issue => issue.code == "W501"))
  assert_false(issues.any(issue => issue.code == "W502"))
}

///|
test "qc bilingual text style reports focused warning codes" {
  let cues = [
    cue(1, 1000, 2500, ["你好, world！！"]),
    cue(2, 3000, 4500, ["Hello（world)"]),
    cue(3, 5000, 6500, ["SupercalifragilisticexpialidociousNoBreakText"]),
    cue(4, 7000, 8500, ["你"]),
    cue(5, 9000, 10500, ["请先登陆 MoonPost"]),
  ]
  let issues = check_cues_with_text_style(
    cues,
    default_profile(),
    bilingual_text_style_profile(),
  )
  assert_true(issues.any(issue => issue.code == "W501"))
  assert_true(issues.any(issue => issue.code == "W502"))
  assert_true(issues.any(issue => issue.code == "W503"))
  assert_true(issues.any(issue => issue.code == "W510"))
  assert_true(issues.any(issue => issue.code == "W511"))
  assert_true(issues.any(issue => issue.code == "W520"))
}

///|
test "json report includes text style warning codes" {
  let issues = [
    QcIssue::{
      severity: Warning,
      code: "W501",
      cue_index: Some(1),
      message: "mixed punctuation style",
    },
  ]
  let report = format_json_report("mixed.srt", issues)
  assert_true(report.contains("\"code\":\"W501\""))
  assert_true(report.contains("\"severity\":\"warning\""))
}

///|
test "punctuation normalization supports zh en and bilingual modes" {
  assert_eq(
    normalize_punctuation("你好, world!", mode=TextStyleBilingual),
    "你好， world!",
  )
  assert_eq(
    normalize_punctuation("Hello，world！", mode=TextStyleEn),
    "Hello,world!",
  )
  assert_eq(
    normalize_punctuation("你好,世界!", mode=TextStyleZh),
    "你好，世界！",
  )
}
