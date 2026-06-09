///|
test "timecode command formats frame conversion output" {
  let lines = timecode_command_lines(
    @cli.ToFrames({ value: "01:00:00:00", frame_rate: @timecode.Fps25 }),
  )
  assert_eq(lines[0], "01:00:00:00 @25fps = 90000 frames")
}

///|
test "timecode command formats IMF composition and EDL event output" {
  let imf_lines = timecode_command_lines(
    @cli.ImfFrom({ value: "01:00:00;00", frame_rate: @timecode.Fps2997Drop }),
  )
  assert_eq(
    imf_lines[0],
    "01:00:00;00 @29.97df = editRate 30000/1001 timecodeRate 30 dropFrame true startAddress 01:00:00:00",
  )

  let edl_lines = timecode_command_lines(
    @cli.EdlEvent({
      line: "001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00",
      frame_rate: @timecode.Fps25,
    }),
  )
  assert_eq(
    edl_lines[0],
    "001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00",
  )
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
test "subtitle normalize text preserves timing and changes punctuation" {
  let input = "1\n00:00:01,000 --> 00:00:02,000\n你好,世界!\n"
  match
    normalize_subtitle_text(input, @cli.SubtitleNormalizeOptions::{
      input: "demo.srt",
      punctuation: "zh",
      output: None,
    }) {
    Some(output) => {
      assert_true(output.contains("00:00:01,000 --> 00:00:02,000"))
      assert_true(output.contains("你好，世界！"))
    }
    None => fail("expected normalized subtitle")
  }
}

///|
test "subtitle normalize rejects unknown punctuation mode" {
  let input = "1\n00:00:01,000 --> 00:00:02,000\n你好,世界!\n"
  assert_true(
    normalize_subtitle_text(input, @cli.SubtitleNormalizeOptions::{
      input: "demo.srt",
      punctuation: "typo",
      output: None,
    })
    is None,
  )
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
    text_style: None,
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
    text_style: None,
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
    text_style: None,
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
    text_style: None,
    output_json: false,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("line 2"))
  assert_eq(result.exit_code, 2)
}

///|
test "qc result includes opt in text style warnings" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n你好, world！！\n"
  let result = qc_result_for_text("mixed.srt", input, @cli.QcOptions::{
    input: "mixed.srt",
    profile: "default",
    frame_rate: None,
    text_style: Some("bilingual"),
    output_json: false,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W501"))
  assert_true(report.contains("W502"))
  assert_eq(result.exit_code, 0)
}

///|
test "qc result rejects unknown text style before subtitle checking" {
  let result = qc_result_for_text("mixed.srt", "", @cli.QcOptions::{
    input: "mixed.srt",
    profile: "default",
    frame_rate: None,
    text_style: Some("typo"),
    output_json: false,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("unknown text style: typo"))
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

///|
test "creator check reports text style warnings through creator profile" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n你好, world！！\n"
  let result = creator_check_result_for_text("creator.srt", input, @cli.CreatorCheckOptions::{
    input: "creator.srt",
    profile: "bilingual",
    output_json: false,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W501"))
  assert_true(report.contains("W502"))
  assert_eq(result.exit_code, 0)
}

///|
test "creator clean normalizes punctuation through creator profile" {
  let input = "1\n00:00:01,000 --> 00:00:02,000\n你好,世界!\n"
  match
    creator_clean_text(input, @cli.CreatorCleanOptions::{
      input: "creator.srt",
      profile: "douyin",
      output: None,
    }) {
    Some(output) => assert_true(output.contains("你好，世界！"))
    None => fail("expected creator clean output")
  }
}

///|
test "creator clean text fixes repeated words confusion and punctuation" {
  let input = "1\n00:00:01,000 --> 00:00:03,500\n然后然后我们认真的做好每一步\n\n2\n00:00:04,000 --> 00:00:07,000\n[Music] 你好,世界!\n"
  let clean_result = creator_clean_text(input, @cli.CreatorCleanOptions::{
    input: "ai.srt",
    profile: "douyin",
    output: None,
  })
  match clean_result {
    Some(output) => {
      // Repeated word fixed
      assert_false(output.contains("然后然后"))
      assert_true(output.contains("然后我们"))
      // ASR marker removed
      assert_false(output.contains("[Music]"))
      // Confusion pair fixed
      assert_false(output.contains("认真的做"))
      assert_true(output.contains("认真地做"))
      // Punctuation normalized
      assert_true(output.contains("你好，世界！"))
      // Timing unchanged
      assert_true(output.contains("00:00:01,000 --> 00:00:03,500"))
    }
    None => fail("expected cleaned subtitle output")
  }
}

///|
test "creator clean text leaves good subtitle mostly unchanged" {
  let input = "1\n00:00:01,000 --> 00:00:03,500\n今天我们来介绍 MoonPost\n"
  let clean_result = creator_clean_text(input, @cli.CreatorCleanOptions::{
    input: "good.srt",
    profile: "douyin",
    output: None,
  })
  match clean_result {
    Some(output) =>
      assert_true(output.contains("今天我们来介绍 MoonPost"))
    None => fail("expected cleaned subtitle output")
  }
}

///|
test "creator clean text handles bilingual profile" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n然后然后 the the quick brown fox\n"
  let clean_result = creator_clean_text(input, @cli.CreatorCleanOptions::{
    input: "mixed.srt",
    profile: "bilingual",
    output: None,
  })
  match clean_result {
    Some(output) => {
      assert_false(output.contains("然后然后"))
      assert_false(output.contains("the the"))
    }
    None => fail("expected cleaned subtitle output")
  }
}

///|
test "delivery subtitle check uses delivery profile defaults" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n1234567890123456789012345678901234567890\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "cinema-zh",
    frame_rate: None,
    output_json: false,
    fail_on_error: true,
    fail_on_warning: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W203"))
  assert_eq(result.exit_code, 0)
}

///|
test "delivery subtitle check can fail automation on warnings" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n1234567890123456789012345678901234567890\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "cinema-zh",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W203"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery subtitle check applies dcp source srt policy warnings" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\n<font color=\"red\">Opening</font>\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "dcp-source-srt",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W601"))
  assert_true(report.contains("W701"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery srt basic treats 500ms cues as source safe" {
  let input = "1\n00:00:01,000 --> 00:00:01,500\nA\n\n2\n00:00:02,000 --> 00:00:02,499\nB\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "srt-basic",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("summary: 0 errors, 1 warning"))
  assert_false(report.contains("W201 cue#1"))
  assert_true(report.contains("W201 cue#2"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery dcp source srt skips frame grid warnings by default" {
  let input = "1\n00:00:01,123 --> 00:00:03,123\nOpening\n\n2\n00:00:03,163 --> 00:00:05,000\nNext\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "dcp-source-srt",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W701"))
  assert_false(report.contains("W401"))
  assert_false(report.contains("W402"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery dcp frame strict keeps frame grid and gap warnings" {
  let input = "1\n00:00:01,123 --> 00:00:03,123\nOpening\n\n2\n00:00:03,163 --> 00:00:05,000\nNext\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "dcp-frame-strict",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("W401"))
  assert_true(report.contains("W402"))
  assert_true(report.contains("W701"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery subtitle warning failure also blocks error only reports" {
  let input = "1\n00:00:01,000 --> 00:00:01,000\nHello\n"
  let result = delivery_subtitle_result_for_text("episode.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "ott-zh",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: true,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("E102"))
  assert_false(report.contains("WARN"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery subtitle json report includes profile metadata" {
  let input = "1\n00:00:01,000 --> 00:00:03,000\nHello\n"
  let result = delivery_subtitle_result_for_text("episode.zh.srt", input, @cli.DeliverySubtitleCheckOptions::{
    input: "episode.zh.srt",
    profile: "ott-zh",
    frame_rate: None,
    output_json: true,
    fail_on_error: true,
    fail_on_warning: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("\"schema_version\":\"moonpost.qc.v1\""))
  assert_true(report.contains("\"command\":\"delivery subtitle-check\""))
  assert_true(report.contains("\"profile\""))
  assert_true(report.contains("\"name\":\"ott-zh\""))
  assert_true(report.contains("\"version\":\"v1\""))
  assert_true(report.contains("\"fail_on_error\":true"))
  assert_true(report.contains("\"fail_on_warning\":false"))
  assert_true(report.contains("\"code\":0"))
}

///|
test "delivery subtitle json report keeps schema for unknown profile" {
  let result = delivery_subtitle_result_for_text("episode.srt", "", @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "typo",
    frame_rate: None,
    output_json: true,
    fail_on_error: false,
    fail_on_warning: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("\"schema_version\":\"moonpost.qc.v1\""))
  assert_true(report.contains("\"command\":\"delivery subtitle-check\""))
  assert_true(report.contains("\"profile\""))
  assert_true(report.contains("\"name\":null"))
  assert_true(report.contains("\"code\":2"))
  assert_true(report.contains("unknown delivery subtitle profile: typo"))
  assert_eq(result.exit_code, 2)
}

///|
test "delivery subtitle json report keeps schema for parse errors" {
  let result = delivery_subtitle_result_for_text(
    "episode.srt",
    "1\nbad timing\nBroken\n",
    @cli.DeliverySubtitleCheckOptions::{
      input: "episode.srt",
      profile: "ott-zh",
      frame_rate: None,
      output_json: true,
      fail_on_error: false,
      fail_on_warning: false,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("\"schema_version\":\"moonpost.qc.v1\""))
  assert_true(report.contains("\"name\":\"ott-zh\""))
  assert_true(report.contains("\"code\":2"))
  assert_true(report.contains("could not parse subtitle file"))
  assert_eq(result.exit_code, 2)
}

///|
test "creator check rejects unknown profile" {
  let result = creator_check_result_for_text("creator.srt", "", @cli.CreatorCheckOptions::{
    input: "creator.srt",
    profile: "typo",
    output_json: false,
    fail_on_error: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("unknown creator profile: typo"))
  assert_eq(result.exit_code, 2)
}

///|
test "delivery subtitle check rejects unknown profile" {
  let result = delivery_subtitle_result_for_text("episode.srt", "", @cli.DeliverySubtitleCheckOptions::{
    input: "episode.srt",
    profile: "typo",
    frame_rate: None,
    output_json: false,
    fail_on_error: false,
    fail_on_warning: false,
  })
  let report = result.lines.join("\n")
  assert_true(report.contains("unknown delivery subtitle profile: typo"))
  assert_eq(result.exit_code, 2)
}

///|
test "delivery subtitle options can override profile frame rate" {
  match
    delivery_subtitle_profile_from_options(@cli.DeliverySubtitleCheckOptions::{
      input: "episode.srt",
      profile: "cinema-zh",
      frame_rate: Some(Fps25),
      output_json: false,
      fail_on_error: false,
      fail_on_warning: false,
    }) {
    Ok(profile) => {
      assert_true(profile.qc_profile.frame_rate == Some(Fps25))
      assert_true(profile.qc_profile.max_cpl == @qc.cinema_profile().max_cpl)
      assert_true(profile.qc_profile.max_cps == @qc.cinema_profile().max_cps)
    }
    Err(message) => fail(message)
  }
}

///|
test "delivery subtitle options preserve srt policy when overriding frame rate" {
  match
    delivery_subtitle_profile_from_options(@cli.DeliverySubtitleCheckOptions::{
      input: "episode.srt",
      profile: "dcp-source-srt",
      frame_rate: Some(Fps25),
      output_json: false,
      fail_on_error: false,
      fail_on_warning: false,
    }) {
    Ok(profile) => {
      assert_true(profile.qc_profile.frame_rate == Some(Fps25))
      assert_true(profile.srt_policy is Some(_))
    }
    Err(message) => fail(message)
  }
}

///|
test "delivery subtitle options keep source and strict frame defaults distinct" {
  match
    delivery_subtitle_profile_from_options(@cli.DeliverySubtitleCheckOptions::{
      input: "episode.srt",
      profile: "dcp-source-srt",
      frame_rate: None,
      output_json: false,
      fail_on_error: false,
      fail_on_warning: false,
    }) {
    Ok(profile) => assert_true(profile.qc_profile.frame_rate is None)
    Err(message) => fail(message)
  }
  match
    delivery_subtitle_profile_from_options(@cli.DeliverySubtitleCheckOptions::{
      input: "episode.srt",
      profile: "dcp-frame-strict",
      frame_rate: None,
      output_json: false,
      fail_on_error: false,
      fail_on_warning: false,
    }) {
    Ok(profile) =>
      assert_true(profile.qc_profile.frame_rate == Some(@timecode.Fps24))
    Err(message) => fail(message)
  }
}

///|
test "delivery package result combines asset and subtitle checks" {
  let result = delivery_package_result_for_inputs_with_checksums(
    "deliveries/E01",
    ["E01.mp4", "E01.zh.srt"],
    None,
    None,
    Map([]),
    [
      {
        name: "E01.zh.srt",
        text: "1\n00:00:01,000 --> 00:00:01,100\nToo short\n",
      },
    ],
    @cli.DeliveryCheckOptions::{
      input: "deliveries/E01",
      profile: "distribution",
      subtitle_profile: "ott-zh",
      frame_rate: Some(Fps25),
      output_json: false,
      fail_on_error: true,
      fail_on_warning: false,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("D101"))
  assert_true(report.contains("metadata"))
  assert_true(report.contains("checksum"))
  assert_true(report.contains("D102"))
  assert_true(report.contains("poster"))
  assert_true(report.contains("D302"))
  assert_true(report.contains("E01.zh.srt"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery package result prefixes srt source policy subtitle issues" {
  let result = delivery_package_result_for_inputs_with_checksums(
    "deliveries/E01",
    [
      "E01.mp4", "E01.zh.srt", "E01.metadata.json", "checksum.txt", "E01.poster.jpg",
    ],
    None,
    None,
    Map([]),
    [
      {
        name: "E01.zh.srt",
        text: "1\n00:00:01,000 --> 00:00:03,000\n<font color=\"red\">Opening</font>\n",
      },
    ],
    @cli.DeliveryCheckOptions::{
      input: "deliveries/E01",
      profile: "distribution",
      subtitle_profile: "dcp-source-srt",
      frame_rate: Some(@timecode.Fps24),
      output_json: false,
      fail_on_error: false,
      fail_on_warning: true,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("D302"))
  assert_true(report.contains("E01.zh.srt:"))
  assert_true(report.contains("W601"))
  assert_true(report.contains("W701"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery package result prefixes dcp frame strict warnings" {
  let result = delivery_package_result_for_inputs_with_checksums(
    "deliveries/E01",
    [
      "E01.mp4", "E01.zh.srt", "E01.metadata.json", "checksum.txt", "E01.poster.jpg",
    ],
    None,
    None,
    Map([]),
    [
      {
        name: "E01.zh.srt",
        text: "1\n00:00:01,123 --> 00:00:03,123\nOpening\n\n2\n00:00:03,163 --> 00:00:05,000\nNext\n",
      },
    ],
    @cli.DeliveryCheckOptions::{
      input: "deliveries/E01",
      profile: "distribution",
      subtitle_profile: "dcp-frame-strict",
      frame_rate: None,
      output_json: false,
      fail_on_error: false,
      fail_on_warning: true,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("D302"))
  assert_true(report.contains("E01.zh.srt:"))
  assert_true(report.contains("W401"))
  assert_true(report.contains("W402"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery package result uses manifest language requirements" {
  let manifest =
    #|{
    #|  "required_subtitles": ["zh", "en"],
    #|  "required_assets": ["video", "subtitle", "metadata", "checksum"]
    #|}
  let result = delivery_package_result_for_inputs_with_checksums(
    "deliveries/E01",
    [
      "E01.mp4", "E01.zh.srt", "E01.metadata.json", "checksum.txt", "E01.poster.jpg",
    ],
    Some(manifest),
    None,
    Map([]),
    [{ name: "E01.zh.srt", text: "1\n00:00:01,000 --> 00:00:03,000\nReady\n" }],
    @cli.DeliveryCheckOptions::{
      input: "deliveries/E01",
      profile: "distribution",
      subtitle_profile: "ott-zh",
      frame_rate: Some(Fps25),
      output_json: false,
      fail_on_error: true,
      fail_on_warning: false,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("D202"))
  assert_true(report.contains("en"))
  assert_eq(result.exit_code, 1)
}

///|
test "delivery package json includes stable package context" {
  let manifest =
    #|{
    #|  "required_subtitles": ["zh"],
    #|  "required_assets": ["video", "subtitle", "metadata", "checksum"]
    #|}
  let result = delivery_package_result_for_inputs_with_checksums(
    "deliveries/good",
    [
      "E01.mp4", "E01.zh.srt", "E01.metadata.json", "checksum.txt", "E01.poster.jpg",
    ],
    Some(manifest),
    None,
    Map([]),
    [{ name: "E01.zh.srt", text: "1\n00:00:01,000 --> 00:00:03,000\nReady\n" }],
    @cli.DeliveryCheckOptions::{
      input: "deliveries/good",
      profile: "distribution",
      subtitle_profile: "ott-zh",
      frame_rate: Some(Fps25),
      output_json: true,
      fail_on_error: true,
      fail_on_warning: false,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("\"schema_version\":\"moonpost.delivery.v1\""))
  assert_true(report.contains("\"command\":\"delivery check\""))
  assert_true(report.contains("\"package_profile\":\"distribution\""))
  assert_true(report.contains("\"subtitle_profile\":\"ott-zh\""))
  assert_true(report.contains("\"assets\""))
  assert_true(report.contains("\"manifest_present\":true"))
  assert_true(report.contains("\"code\":0"))
  assert_eq(result.exit_code, 0)
}

///|
test "delivery package result includes checksum verification issues" {
  let expected_hash = @delivery.sha256_hex(b"expected-video")
  let actual_hash = @delivery.sha256_hex(b"actual-video")
  let result = delivery_package_result_for_inputs_with_checksums(
    "deliveries/checksum-bad",
    [
      "E01.mp4", "E01.zh.srt", "E01.metadata.json", "checksum.txt", "E01.poster.jpg",
    ],
    None,
    Some("\{expected_hash}  E01.mp4\nbad  E01.poster.jpg\n"),
    Map([("E01.mp4", actual_hash)]),
    [{ name: "E01.zh.srt", text: "1\n00:00:01,000 --> 00:00:03,000\nReady\n" }],
    @cli.DeliveryCheckOptions::{
      input: "deliveries/checksum-bad",
      profile: "distribution",
      subtitle_profile: "ott-zh",
      frame_rate: Some(Fps25),
      output_json: false,
      fail_on_error: true,
      fail_on_warning: false,
    },
  )
  let report = result.lines.join("\n")
  assert_true(report.contains("D401"))
  assert_true(report.contains("D403"))
  assert_true(report.contains("E01.mp4"))
  assert_eq(result.exit_code, 1)
}

///|
async test "delivery file sha256 reads file bytes" {
  let path = "_build/test-delivery-sha256.bin"
  @fs.write_file(path, b"actual-video", create_mode=CreateOrTruncate)
  match sha256_file_hex(path) {
    Some(hash) => assert_eq(hash, @delivery.sha256_hex(b"actual-video"))
    None => fail("expected file hash")
  }
}
