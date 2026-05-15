///|
test "timecode command formats frame conversion output" {
  let lines = timecode_command_lines(
    @cli.ToFrames({ value: "01:00:00:00", frame_rate: @timecode.Fps25 }),
  )
  assert_eq(lines[0], "01:00:00:00 @25fps = 90000 frames")
}

///|
test "subtitle convert text writes webvtt from srt" {
  let input = "1\n00:00:01,000 --> 00:00:02,000\nHello\n"
  match subtitle_convert_text(input, "webvtt") {
    Some(output) =>
      assert_true(output.has_prefix("WEBVTT\n\n00:00:01.000 --> 00:00:02.000"))
    None => fail("expected converted subtitle")
  }
}

///|
test "qc report for text includes detected issues" {
  let input = "1\n00:00:01,123 --> 00:00:01,500\nThis line is intentionally far too long for a conservative subtitle delivery profile.\n\n2\n00:00:01,400 --> 00:00:09,000\nFast text fast text fast text fast text fast text\n"
  let lines = qc_report_for_text(
    "bad.srt",
    input,
    "streaming",
    Some(@timecode.Fps25),
  )
  let report = lines.join("\n")
  assert_true(report.contains("bad.srt"))
  assert_true(report.contains("E101"))
  assert_true(report.contains("W203"))
  assert_true(report.contains("summary:"))
}

///|
test "qc report uses named cinema profile" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n1234567890123456789012345678901234567890\n"
  let lines = qc_report_for_text("cinema.srt", input, "cinema", None)
  let report = lines.join("\n")
  assert_true(report.contains("summary: 0 errors, 3 warnings"))
  assert_true(report.contains("W203"))
}

///|
test "retime text offsets srt cues" {
  let input = "1\n00:00:01,000 --> 00:00:02,000\nHello\n"
  match
    retime_text(input, @cli.RetimeOptions::{
      input: "demo.srt",
      output: None,
      offset_ms: 1200,
      source_rate: None,
      target_rate: None,
      snap_rate: None,
    }) {
    Some(output) =>
      assert_true(output.contains("00:00:02,200 --> 00:00:03,200"))
    None => fail("expected retimed output")
  }
}

///|
test "subtitle convert rejects unknown target" {
  assert_true(
    subtitle_convert_text("1\n00:00:01,000 --> 00:00:02,000\nHello\n", "ass")
    is None,
  )
}
