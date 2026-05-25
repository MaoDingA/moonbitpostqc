///|
fn frame_rate_label(rate : @timecode.FrameRate) -> String {
  rate.label()
}

///|
fn timecode_command_lines(command : @cli.TimecodeCommand) -> Array[String] {
  match command {
    @cli.ToFrames(options) =>
      match @timecode.parse_timecode(options.value, options.frame_rate) {
        Some(tc) =>
          [
            "\{options.value} @\{frame_rate_label(options.frame_rate)} = \{tc.to_frames()} frames",
          ]
        None => ["invalid timecode: \{options.value}"]
      }
    @cli.FromFrames(options) =>
      [
        "\{options.frames} frames @\{frame_rate_label(options.frame_rate)} = \{options.frame_rate.frames_to_timecode(options.frames).format()}",
      ]
    @cli.ConvertTimecode(options) =>
      match @timecode.parse_timecode(options.value, options.source_rate) {
        Some(tc) =>
          [
            "\{options.value} @\{frame_rate_label(options.source_rate)} = \{@timecode.convert_timecode(tc, options.target_rate).format()} @\{frame_rate_label(options.target_rate)}",
          ]
        None => ["invalid timecode: \{options.value}"]
      }
  }
}

///|

///|
extern "c" fn exit_process(code : Int) = "exit"

///|
struct QcCliResult {
  lines : Array[String]
  exit_code : Int
}

///|
struct PackageSubtitleInput {
  name : String
  text : String
}

///|
fn first_nonblank_line(input : String) -> String? {
  for raw in input.split("\n") {
    let line = raw.trim().to_owned()
    if !line.is_empty() {
      return Some(line)
    }
  }
  None
}

///|
fn parse_subtitle_text_detailed(
  input : String,
) -> Result[@subtitle.SubtitleTrack, @subtitle.ParseError] {
  match first_nonblank_line(input) {
    Some(line) =>
      if line == "WEBVTT" || line.has_prefix("WEBVTT ") {
        @subtitle.parse_webvtt_detailed(input)
      } else {
        match @subtitle.parse_srt_detailed(input) {
          Ok(track) => Ok(track)
          Err(error) =>
            match @subtitle.parse_webvtt_detailed(input) {
              Ok(track) => Ok(track)
              Err(_) => Err(error)
            }
        }
      }
    None => @subtitle.parse_srt_detailed(input)
  }
}

///|
fn parse_subtitle_text(input : String) -> @subtitle.SubtitleTrack? {
  match parse_subtitle_text_detailed(input) {
    Ok(track) => Some(track)
    Err(_) => None
  }
}

///|
fn subtitle_convert_text(input : String, target : String) -> String? {
  match parse_subtitle_text(input) {
    Some(track) =>
      match target {
        "srt" => Some(@subtitle.write_srt(track))
        "webvtt" | "vtt" => Some(@subtitle.write_webvtt(track))
        _ => None
      }
    None => None
  }
}

///|
fn write_track(track : @subtitle.SubtitleTrack) -> String {
  match track.format {
    @subtitle.Srt => @subtitle.write_srt(track)
    @subtitle.WebVtt => @subtitle.write_webvtt(track)
  }
}

///|
fn punctuation_mode_from_name(name : String) -> @qc.TextStyleMode? {
  match name {
    "bilingual" => Some(@qc.TextStyleBilingual)
    "zh" | "chinese" => Some(@qc.TextStyleZh)
    "en" | "english" => Some(@qc.TextStyleEn)
    "none" => Some(@qc.TextStyleNone)
    _ => None
  }
}

///|
fn normalize_subtitle_text(
  input : String,
  options : @cli.SubtitleNormalizeOptions,
) -> String? {
  match
    (
      parse_subtitle_text(input),
      punctuation_mode_from_name(options.punctuation),
    ) {
    (Some(track), Some(mode)) => {
      let cues : Array[@subtitle.Cue] = []
      for cue in track.cues {
        let text : Array[String] = []
        for line in cue.text {
          text.push(@qc.normalize_punctuation(line, mode~))
        }
        cues.push({
          index: cue.index,
          identifier: cue.identifier,
          start_ms: cue.start_ms,
          end_ms: cue.end_ms,
          text,
          settings: cue.settings,
        })
      }
      Some(write_track({ format: track.format, cues }))
    }
    _ => None
  }
}

///|
fn retime_text(input : String, options : @cli.RetimeOptions) -> String? {
  match parse_subtitle_text(input) {
    Some(track) => {
      let mut cues = track.cues
      if options.offset_ms != 0 {
        cues = @retime.offset_cues(cues, options.offset_ms)
      }
      match (options.source_rate, options.target_rate) {
        (Some(source_rate), Some(target_rate)) =>
          cues = @retime.convert_fps_cues(cues, source_rate, target_rate)
        _ => ()
      }
      match options.snap_rate {
        Some(rate) => cues = @retime.snap_cues_to_frames(cues, rate)
        None => ()
      }
      Some(write_track({ format: track.format, cues }))
    }
    None => None
  }
}

///|
fn profile_from_name(
  name : String,
  fps : @timecode.FrameRate?,
) -> @qc.QcProfile {
  let base = match @qc.profile_by_name(name) {
    Some(profile) => profile
    None => @qc.default_profile()
  }
  {
    max_cpl: base.max_cpl,
    max_cps: base.max_cps,
    max_lines: base.max_lines,
    min_duration_ms: base.min_duration_ms,
    max_duration_ms: base.max_duration_ms,
    min_gap_frames: base.min_gap_frames,
    frame_rate: match fps {
      Some(rate) => Some(rate)
      None => base.frame_rate
    },
  }
}

///|
fn text_style_profile_from_options(
  options : @cli.QcOptions,
) -> Result[@qc.TextStyleProfile, String] {
  match options.text_style {
    Some(name) =>
      match @qc.text_style_profile_by_name(name) {
        Some(profile) => Ok(profile)
        None => Err("unknown text style: \{name}")
      }
    None => Ok(@qc.no_text_style_profile())
  }
}

///|
fn qc_result_for_text(
  name : String,
  input : String,
  options : @cli.QcOptions,
) -> QcCliResult {
  let text_style = match text_style_profile_from_options(options) {
    Ok(profile) => profile
    Err(message) => {
      let issues = [
        @qc.QcIssue::{
          severity: @qc.Error,
          code: "E000",
          cue_index: None,
          message,
        },
      ]
      return {
        lines: if options.output_json {
          [@qc.format_json_report(name, issues)]
        } else {
          @qc.format_report(name, issues)
        },
        exit_code: 2,
      }
    }
  }
  match parse_subtitle_text_detailed(input) {
    Ok(track) => {
      let profile = profile_from_name(options.profile, options.frame_rate)
      let issues = @qc.check_cues_with_text_style(
        track.cues,
        profile,
        text_style,
      )
      let lines = if options.output_json {
        [@qc.format_json_report(name, issues)]
      } else {
        @qc.format_report(name, issues)
      }
      {
        lines,
        exit_code: if options.fail_on_error && @qc.has_errors(issues) {
          1
        } else {
          0
        },
      }
    }
    Err(error) => {
      let issues = [
        @qc.QcIssue::{
          severity: @qc.Error,
          code: "E000",
          cue_index: None,
          message: "could not parse subtitle file: \{error.format_message()}",
        },
      ]
      {
        lines: if options.output_json {
          [@qc.format_json_report(name, issues)]
        } else {
          @qc.format_report(name, issues)
        },
        exit_code: 2,
      }
    }
  }
}

///|
fn merge_bilingual_text(
  primary_text : String,
  secondary_text : String,
  options : @cli.MergeOptions,
) -> String? {
  match
    (parse_subtitle_text(primary_text), parse_subtitle_text(secondary_text)) {
    (Some(primary), Some(secondary)) =>
      Some(
        write_track({
          format: primary.format,
          cues: @align.merge_bilingual(
            primary.cues,
            secondary.cues,
            tolerance_ms=options.tolerance_ms,
          ),
        }),
      )
    _ => None
  }
}

///|
fn split_bilingual_text(input : String) -> (String, String)? {
  match parse_subtitle_text(input) {
    Some(track) => {
      let split = @align.split_bilingual(track.cues)
      Some(
        (
          write_track({ format: track.format, cues: split.primary }),
          write_track({ format: track.format, cues: split.secondary }),
        ),
      )
    }
    None => None
  }
}

///|
fn print_lines(lines : Array[String]) -> Unit {
  for line in lines {
    println(line)
  }
}

///|
fn join_path(parent : String, child : String) -> String {
  if parent.has_suffix("/") {
    "\{parent}\{child}"
  } else {
    "\{parent}/\{child}"
  }
}

///|
async fn read_text_file(path : String) -> String? {
  Some(@fs.read_file(path).text()) catch {
    _ => None
  }
}

///|
async fn read_directory_entries(path : String) -> Array[String]? {
  Some(@fs.readdir(path, sort=true)) catch {
    _ => None
  }
}

///|
async fn write_text_file(path : String, content : String) -> Bool {
  try {
    @fs.write_file(path, content, create_mode=CreateOrTruncate)
    true
  } catch {
    _ => false
  }
}

///|
async fn run_qc(options : @cli.QcOptions) -> Int {
  match text_style_profile_from_options(options) {
    Ok(_) => ()
    Err(message) => {
      println(message)
      return 2
    }
  }
  match read_text_file(options.input) {
    Some(text) => {
      let result = qc_result_for_text(options.input, text, options)
      print_lines(result.lines)
      result.exit_code
    }
    None => {
      println("could not read file: \{options.input}")
      2
    }
  }
}

///|
async fn run_subtitle_convert(options : @cli.SubtitleConvertOptions) -> Int {
  match read_text_file(options.input) {
    Some(text) =>
      match subtitle_convert_text(text, options.target) {
        Some(output) =>
          match options.output {
            Some(path) =>
              if !write_text_file(path, output) {
                println("could not write file: \{path}")
                2
              } else {
                0
              }
            None => {
              println(output)
              0
            }
          }
        None => {
          println("could not convert subtitle to \{options.target}")
          2
        }
      }
    None => {
      println("could not read file: \{options.input}")
      2
    }
  }
}

///|
async fn run_subtitle_normalize(options : @cli.SubtitleNormalizeOptions) -> Int {
  match punctuation_mode_from_name(options.punctuation) {
    Some(_) => ()
    None => {
      println("unknown punctuation mode: \{options.punctuation}")
      return 2
    }
  }
  match read_text_file(options.input) {
    Some(text) =>
      match normalize_subtitle_text(text, options) {
        Some(output) =>
          match options.output {
            Some(path) =>
              if !write_text_file(path, output) {
                println("could not write file: \{path}")
                2
              } else {
                0
              }
            None => {
              println(output)
              0
            }
          }
        None => {
          println("could not normalize subtitle: \{options.input}")
          2
        }
      }
    None => {
      println("could not read file: \{options.input}")
      2
    }
  }
}

///|
async fn run_retime(options : @cli.RetimeOptions) -> Int {
  match read_text_file(options.input) {
    Some(text) =>
      match retime_text(text, options) {
        Some(output) =>
          match options.output {
            Some(path) =>
              if !write_text_file(path, output) {
                println("could not write file: \{path}")
                2
              } else {
                0
              }
            None => {
              println(output)
              0
            }
          }
        None => {
          println("could not retime subtitle: \{options.input}")
          2
        }
      }
    None => {
      println("could not read file: \{options.input}")
      2
    }
  }
}

///|
async fn run_merge(options : @cli.MergeOptions) -> Int {
  match (read_text_file(options.primary), read_text_file(options.secondary)) {
    (Some(primary), Some(secondary)) =>
      match merge_bilingual_text(primary, secondary, options) {
        Some(output) =>
          match options.output {
            Some(path) =>
              if !write_text_file(path, output) {
                println("could not write file: \{path}")
                2
              } else {
                0
              }
            None => {
              println(output)
              0
            }
          }
        None => {
          println("could not merge subtitle files")
          2
        }
      }
    _ => {
      println("could not read merge input files")
      2
    }
  }
}

///|
async fn run_split_bilingual(options : @cli.SplitBilingualOptions) -> Int {
  match (options.primary_output, options.secondary_output) {
    (Some(primary_path), Some(secondary_path)) =>
      match read_text_file(options.input) {
        Some(text) =>
          match split_bilingual_text(text) {
            Some((primary, secondary)) =>
              if !write_text_file(primary_path, primary) {
                println("could not write file: \{primary_path}")
                2
              } else if !write_text_file(secondary_path, secondary) {
                println("could not write file: \{secondary_path}")
                2
              } else {
                0
              }
            None => {
              println("could not split bilingual subtitle: \{options.input}")
              2
            }
          }
        None => {
          println("could not read file: \{options.input}")
          2
        }
      }
    _ => {
      println("split-bilingual requires --primary and --secondary")
      2
    }
  }
}

///|
async fn run_command(command : @cli.Command) -> Int {
  match command {
    @cli.Qc(options) => run_qc(options)
    @cli.Creator(@cli.CreatorCheck(options)) => run_creator_check(options)
    @cli.Creator(@cli.CreatorClean(options)) => run_creator_clean(options)
    @cli.Delivery(@cli.DeliverySubtitleCheck(options)) =>
      run_delivery_subtitle_check(options)
    @cli.Delivery(@cli.DeliveryCheck(options)) => run_delivery_check(options)
    @cli.Timecode(command) => {
      print_lines(timecode_command_lines(command))
      0
    }
    @cli.Subtitle(@cli.Convert(options)) => run_subtitle_convert(options)
    @cli.Subtitle(@cli.Normalize(options)) => run_subtitle_normalize(options)
    @cli.Retime(options) => run_retime(options)
    @cli.Merge(options) => run_merge(options)
    @cli.SplitBilingual(options) => run_split_bilingual(options)
    @cli.Help(topic) => {
      print_lines(@cli.help_lines(topic))
      0
    }
  }
}

///|
async fn main {
  let code = run_command(@cli.parse_command(@env.args()))
  if code != 0 {
    exit_process(code)
  }
}
