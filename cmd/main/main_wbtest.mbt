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
test "subtitle auto parser accepts webvtt input" {
  let input = "WEBVTT\n\n00:00:01.000 --> 00:00:02.000\nHello\n"
  match parse_subtitle_text(input) {
    Some(track) => assert_true(track.format == @subtitle.WebVtt)
    None => fail("expected WebVTT track")
  }
}

///|
test "qc report for text includes detected issues" {
  let input = "1\n00:00:01,123 --> 00:00:01,500\nThis line is intentionally far too long for a conservative subtitle delivery profile.\n\n2\n00:00:01,400 --> 00:00:09,000\nFast text fast text fast text fast text fast text\n"
  let result = qc_result_for_text("bad.srt", input, @cli.QcOptions::{
    input: "bad.srt",
    profile: "streaming",
    frame_rate: Some(@timecode.Fps25),
    output_json: false,
    fail_on_error: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("bad.srt"))
  assert_true(report.contains("E101"))
  assert_true(report.contains("W203"))
  assert_true(report.contains("summary:"))
  assert_eq(result.exit_code, 1)
}

///|
test "qc report uses named cinema profile" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n1234567890123456789012345678901234567890\n"
  let result = qc_result_for_text("cinema.srt", input, @cli.QcOptions::{
    input: "cinema.srt",
    profile: "cinema",
    frame_rate: None,
    output_json: false,
    fail_on_error: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("summary: 0 errors, 3 warnings"))
  assert_true(report.contains("W203"))
  assert_eq(result.exit_code, 0)
}

///|
test "qc result can emit json" {
  let input = "1\n00:00:01,000 --> 00:00:01,100\nToo short\n"
  let result = qc_result_for_text("short.srt", input, @cli.QcOptions::{
    input: "short.srt",
    profile: "default",
    frame_rate: None,
    output_json: true,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("\"name\":\"short.srt\""))
  assert_true(report.contains("\"warnings\":2"))
  assert_eq(result.exit_code, 0)
}

///|
test "qc parse failure includes line information" {
  let result = qc_result_for_text("bad.srt", "1\nbad timing\nBroken\n", @cli.QcOptions::{
    input: "bad.srt",
    profile: "default",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("line 2"))
  assert_eq(result.exit_code, 2)
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

///|
test "merge bilingual text combines matching cues" {
  let primary = "1\n00:00:01,000 --> 00:00:02,000\n你好\n"
  let secondary = "1\n00:00:01,100 --> 00:00:02,050\nHello\n"
  match
    merge_bilingual_text(primary, secondary, @cli.MergeOptions::{
      primary: "zh.srt",
      secondary: "en.srt",
      output: None,
      tolerance_ms: 150,
    }) {
    Some(output) => {
      assert_true(output.contains("你好\nHello"))
      assert_true(output.contains("00:00:01,000 --> 00:00:02,050"))
    }
    None => fail("expected merged subtitles")
  }
}

///|
test "split bilingual text returns two subtitle tracks" {
  let input = "1\n00:00:01,000 --> 00:00:02,000\n你好\nHello\n"
  match split_bilingual_text(input) {
    Some((primary, secondary)) => {
      assert_true(primary.contains("你好"))
      assert_false(primary.contains("Hello"))
      assert_true(secondary.contains("Hello"))
    }
    None => fail("expected split subtitles")
  }
}
