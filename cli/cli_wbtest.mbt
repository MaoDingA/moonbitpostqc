///|
test "cli parses qc command with fps profile and output" {
  let command = parse_command([
    "moonpost", "qc", "movie.zh.srt", "--fps", "25", "--profile", "streaming", "--json",
    "--fail-on-error",
  ])
  match command {
    Qc(options) => {
      assert_eq(options.input, "movie.zh.srt")
      assert_eq(options.profile, "streaming")
      assert_true(options.frame_rate == Some(@timecode.Fps25))
      assert_true(options.output_json)
      assert_true(options.fail_on_error)
    }
    _ => fail("expected qc command")
  }
}

///|
test "cli parses timecode conversion" {
  let command = parse_command([
    "moonpost", "timecode", "to-frames", "01:00:00:00", "--fps", "25",
  ])
  match command {
    Timecode(ToFrames(options)) => {
      assert_eq(options.value, "01:00:00:00")
      assert_true(options.frame_rate == @timecode.Fps25)
    }
    _ => fail("expected timecode to-frames")
  }
}

///|
test "cli parses subtitle convert target and output" {
  let command = parse_command([
    "moonpost", "subtitle", "convert", "demo.srt", "--to", "webvtt", "-o", "demo.vtt",
  ])
  match command {
    Subtitle(Convert(options)) => {
      assert_eq(options.input, "demo.srt")
      assert_eq(options.target, "webvtt")
      assert_true(options.output == Some("demo.vtt"))
    }
    _ => fail("expected subtitle convert")
  }
}

///|
test "cli parses retime offset and output" {
  let command = parse_command([
    "moonpost", "retime", "input.srt", "--offset", "+1200ms", "-o", "output.srt",
  ])
  match command {
    Retime(options) => {
      assert_eq(options.input, "input.srt")
      assert_eq(options.offset_ms, 1200)
      assert_true(options.output == Some("output.srt"))
    }
    _ => fail("expected retime command")
  }
}

///|
test "cli parses bilingual merge command" {
  let command = parse_command([
    "moonpost", "merge", "zh.srt", "en.srt", "--tolerance", "750ms", "-o", "zh_en.srt",
  ])
  match command {
    Merge(options) => {
      assert_eq(options.primary, "zh.srt")
      assert_eq(options.secondary, "en.srt")
      assert_eq(options.tolerance_ms, 750)
      assert_true(options.output == Some("zh_en.srt"))
    }
    _ => fail("expected merge command")
  }
}

///|
test "cli parses bilingual split command" {
  let command = parse_command([
    "moonpost", "split-bilingual", "zh_en.srt", "--primary", "zh.srt", "--secondary",
    "en.srt",
  ])
  match command {
    SplitBilingual(options) => {
      assert_eq(options.input, "zh_en.srt")
      assert_true(options.primary_output == Some("zh.srt"))
      assert_true(options.secondary_output == Some("en.srt"))
    }
    _ => fail("expected split-bilingual command")
  }
}

///|
test "help lines describe core commands" {
  let lines = help_lines(RootHelp)
  let text = lines.join("\n")
  assert_true(text.contains("qc"))
  assert_true(text.contains("timecode"))
  assert_true(text.contains("subtitle"))
  assert_true(text.contains("retime"))
  assert_true(text.contains("merge"))
  assert_true(text.contains("split-bilingual"))
}

///|
test "cli parses frame rate aliases" {
  assert_true(parse_frame_rate("29.97df") == Some(@timecode.Fps2997Drop))
  assert_true(parse_frame_rate("59.94") == Some(@timecode.Fps5994NonDrop))
  assert_true(parse_frame_rate("bad") is None)
}

///|
test "timecode command falls back to 25fps on unknown fps" {
  let command = parse_command([
    "moonpost", "timecode", "to-frames", "00:00:01:00", "--fps", "bad",
  ])
  match command {
    Timecode(ToFrames(options)) =>
      assert_true(options.frame_rate == @timecode.Fps25)
    _ => fail("expected timecode to-frames")
  }
}
