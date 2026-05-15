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
