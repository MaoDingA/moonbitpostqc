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
      assert_true(options.frame_rate == Some(Fps25))
      assert_true(options.text_style is None)
      assert_true(options.output_json)
      assert_true(options.fail_on_error)
    }
    _ => fail("expected qc command")
  }
}

///|
test "cli parses opt in qc text style" {
  let command = parse_command([
    "moonpost", "qc", "movie.zh_en.srt", "--text-style", "bilingual",
  ])
  match command {
    Qc(options) => {
      assert_eq(options.input, "movie.zh_en.srt")
      assert_true(options.text_style == Some("bilingual"))
    }
    _ => fail("expected qc command")
  }
}

///|
test "cli parses creator check command" {
  let command = parse_command([
    "moonpost", "creator", "check", "video.srt", "--profile", "douyin", "--json",
    "--fail-on-error",
  ])
  match command {
    Creator(CreatorCheck(options)) => {
      assert_eq(options.input, "video.srt")
      assert_eq(options.profile, "douyin")
      assert_true(options.output_json)
      assert_true(options.fail_on_error)
    }
    _ => fail("expected creator check command")
  }
}

///|
test "cli parses creator check default profile" {
  let command = parse_command(["moonpost", "creator", "check", "file.srt"])
  match command {
    Creator(CreatorCheck(options)) => {
      assert_eq(options.input, "file.srt")
      assert_eq(options.profile, "douyin")
      assert_false(options.output_json)
      assert_false(options.fail_on_error)
    }
    _ => fail("expected creator check command")
  }
}

///|
test "cli parses creator clean command" {
  let command = parse_command([
    "moonpost", "creator", "clean", "video.srt", "--profile", "douyin", "-o", "fixed.srt",
  ])
  match command {
    Creator(CreatorClean(options)) => {
      assert_eq(options.input, "video.srt")
      assert_eq(options.profile, "douyin")
      assert_true(options.output == Some("fixed.srt"))
    }
    _ => fail("expected creator clean command")
  }
}

///|
test "cli parses creator clean defaults and long output flag" {
  let command = parse_command([
    "moonpost", "creator", "clean", "video.srt", "--output", "fixed.srt",
  ])
  match command {
    Creator(CreatorClean(options)) => {
      assert_eq(options.input, "video.srt")
      assert_eq(options.profile, "douyin")
      assert_true(options.output == Some("fixed.srt"))
    }
    _ => fail("expected creator clean command")
  }
  let default_output = parse_command([
    "moonpost", "creator", "clean", "video.srt",
  ])
  match default_output {
    Creator(CreatorClean(options)) => {
      assert_eq(options.input, "video.srt")
      assert_eq(options.profile, "douyin")
      assert_true(options.output is None)
    }
    _ => fail("expected creator clean command")
  }
}

///|
test "cli parses delivery subtitle check command" {
  let command = parse_command([
    "moonpost", "delivery", "subtitle-check", "episode.zh.srt", "--profile", "ott-zh",
    "--fps", "25", "--json", "--fail-on-error", "--fail-on-warning",
  ])
  match command {
    Delivery(DeliverySubtitleCheck(options)) => {
      assert_eq(options.input, "episode.zh.srt")
      assert_eq(options.profile, "ott-zh")
      assert_true(options.frame_rate == Some(Fps25))
      assert_true(options.output_json)
      assert_true(options.fail_on_error)
      assert_true(options.fail_on_warning)
    }
    _ => fail("expected delivery subtitle-check command")
  }
}

///|
test "cli parses delivery subtitle check default profile" {
  let command = parse_command([
    "moonpost", "delivery", "subtitle-check", "file.srt",
  ])
  match command {
    Delivery(DeliverySubtitleCheck(options)) => {
      assert_eq(options.input, "file.srt")
      assert_eq(options.profile, "ott-zh")
      assert_true(options.frame_rate is None)
      assert_false(options.output_json)
      assert_false(options.fail_on_error)
      assert_false(options.fail_on_warning)
    }
    _ => fail("expected delivery subtitle-check command")
  }
}

///|
test "cli parses delivery package check command" {
  let command = parse_command([
    "moonpost", "delivery", "check", "deliveries/E01", "--profile", "distribution",
    "--subtitle-profile", "cinema-zh", "--fps", "24", "--json", "--fail-on-error",
    "--fail-on-warning",
  ])
  match command {
    Delivery(DeliveryCheck(options)) => {
      assert_eq(options.input, "deliveries/E01")
      assert_eq(options.profile, "distribution")
      assert_eq(options.subtitle_profile, "cinema-zh")
      assert_true(options.frame_rate == Some(Fps24))
      assert_true(options.output_json)
      assert_true(options.fail_on_error)
      assert_true(options.fail_on_warning)
    }
    _ => fail("expected delivery package check command")
  }
}

///|
test "cli parses delivery package check defaults" {
  let command = parse_command([
    "moonpost", "delivery", "check", "deliveries/E01",
  ])
  match command {
    Delivery(DeliveryCheck(options)) => {
      assert_eq(options.input, "deliveries/E01")
      assert_eq(options.profile, "distribution")
      assert_eq(options.subtitle_profile, "ott-zh")
      assert_true(options.frame_rate is None)
      assert_false(options.output_json)
      assert_false(options.fail_on_error)
      assert_false(options.fail_on_warning)
    }
    _ => fail("expected delivery package check command")
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
      assert_true(options.frame_rate == Fps25)
    }
    _ => fail("expected timecode to-frames")
  }
}

///|
test "cli parses timecode IMF and EDL interop commands" {
  let imf = parse_command([
    "moonpost", "timecode", "imf-from", "01:00:00;00", "--fps", "29.97df",
  ])
  match imf {
    Timecode(ImfFrom(options)) => {
      assert_eq(options.value, "01:00:00;00")
      assert_true(options.frame_rate == Fps2997Drop)
    }
    _ => fail("expected timecode imf-from")
  }

  let edl = parse_command([
    "moonpost", "timecode", "edl-event", "001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00",
    "--fps", "25",
  ])
  match edl {
    Timecode(EdlEvent(options)) => {
      assert_true(options.frame_rate == Fps25)
      assert_true(options.line.contains("001 AX V C"))
    }
    _ => fail("expected timecode edl-event")
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
test "cli parses subtitle normalize punctuation and output" {
  let command = parse_command([
    "moonpost", "subtitle", "normalize", "demo.srt", "--punctuation", "bilingual",
    "-o", "fixed.srt",
  ])
  match command {
    Subtitle(Normalize(options)) => {
      assert_eq(options.input, "demo.srt")
      assert_eq(options.punctuation, "bilingual")
      assert_true(options.output == Some("fixed.srt"))
    }
    _ => fail("expected subtitle normalize")
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
  assert_true(text.contains("creator"))
  assert_true(text.contains("delivery"))
  assert_true(text.contains("qc"))
  assert_true(text.contains("timecode"))
  assert_true(text.contains("subtitle"))
  assert_true(text.contains("retime"))
  assert_true(text.contains("merge"))
  assert_true(text.contains("split-bilingual"))
}

///|
test "creator help describes creator commands" {
  let text = help_lines(CreatorHelp).join("\n")
  assert_true(text.contains("creator check"))
  assert_true(text.contains("creator clean"))
}

///|
test "delivery help describes subtitle check command" {
  let text = help_lines(DeliveryHelp).join("\n")
  assert_true(text.contains("delivery subtitle-check"))
  assert_true(text.contains("delivery check"))
}

///|
test "delivery help describes strict flags and profiles" {
  let text = help_lines(DeliveryHelp).join("\n")
  assert_true(text.contains("--fail-on-error"))
  assert_true(text.contains("--fail-on-warning"))
  assert_true(text.contains("ott-zh"))
  assert_true(text.contains("cinema-zh"))
  assert_true(text.contains("broadcast"))
  assert_true(text.contains("srt-basic"))
  assert_true(text.contains("dcp-source-srt"))
  assert_true(text.contains("dcp-frame-strict"))
}

///|
test "cli parses frame rate aliases" {
  assert_true(parse_frame_rate("23.98") == Some(Fps23976))
  assert_true(parse_frame_rate("29.97df") == Some(Fps2997Drop))
  assert_true(parse_frame_rate("29.97 drop") == Some(Fps2997Drop))
  assert_true(parse_frame_rate("59.94") == Some(Fps5994NonDrop))
  assert_true(parse_frame_rate("59.94ndf") == Some(Fps5994NonDrop))
  assert_true(parse_frame_rate("bad") is None)
}

///|
test "timecode command falls back to 25fps on unknown fps" {
  let command = parse_command([
    "moonpost", "timecode", "to-frames", "00:00:01:00", "--fps", "bad",
  ])
  match command {
    Timecode(ToFrames(options)) => assert_true(options.frame_rate == Fps25)
    _ => fail("expected timecode to-frames")
  }
}
