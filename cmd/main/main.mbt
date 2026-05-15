///|
fn frame_rate_label(rate : @timecode.FrameRate) -> String {
  match rate {
    @timecode.Fps23976 => "23.976fps"
    @timecode.Fps24 => "24fps"
    @timecode.Fps25 => "25fps"
    @timecode.Fps2997Drop => "29.97df"
    @timecode.Fps2997NonDrop => "29.97fps"
    @timecode.Fps30 => "30fps"
    @timecode.Fps50 => "50fps"
    @timecode.Fps5994Drop => "59.94df"
    @timecode.Fps5994NonDrop => "59.94fps"
  }
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
fn parse_subtitle_text(input : String) -> @subtitle.SubtitleTrack? {
  match @subtitle.parse_srt(input) {
    Some(track) => Some(track)
    None => @subtitle.parse_webvtt(input)
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
fn qc_report_for_text(
  name : String,
  input : String,
  profile_name : String,
  fps : @timecode.FrameRate?,
) -> Array[String] {
  match parse_subtitle_text(input) {
    Some(track) => {
      let profile = profile_from_name(profile_name, fps)
      @qc.format_report(name, @qc.check_cues(track.cues, profile))
    }
    None => [name, "", "ERROR E000 could not parse subtitle file"]
  }
}

///|
fn print_lines(lines : Array[String]) -> Unit {
  for line in lines {
    println(line)
  }
}

///|
async fn read_text_file(path : String) -> String? {
  Some(@fs.read_file(path).text()) catch {
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
async fn run_qc(options : @cli.QcOptions) -> Unit {
  match read_text_file(options.input) {
    Some(text) =>
      print_lines(
        qc_report_for_text(
          options.input,
          text,
          options.profile,
          options.frame_rate,
        ),
      )
    None => println("could not read file: \{options.input}")
  }
}

///|
async fn run_subtitle_convert(options : @cli.SubtitleConvertOptions) -> Unit {
  match read_text_file(options.input) {
    Some(text) =>
      match subtitle_convert_text(text, options.target) {
        Some(output) =>
          match options.output {
            Some(path) =>
              if !write_text_file(path, output) {
                println("could not write file: \{path}")
              }
            None => println(output)
          }
        None => println("could not convert subtitle to \{options.target}")
      }
    None => println("could not read file: \{options.input}")
  }
}

///|
async fn run_retime(options : @cli.RetimeOptions) -> Unit {
  match read_text_file(options.input) {
    Some(text) =>
      match retime_text(text, options) {
        Some(output) =>
          match options.output {
            Some(path) =>
              if !write_text_file(path, output) {
                println("could not write file: \{path}")
              }
            None => println(output)
          }
        None => println("could not retime subtitle: \{options.input}")
      }
    None => println("could not read file: \{options.input}")
  }
}

///|
async fn main {
  match @cli.parse_command(@env.args()) {
    @cli.Qc(options) => run_qc(options)
    @cli.Timecode(command) => print_lines(timecode_command_lines(command))
    @cli.Subtitle(@cli.Convert(options)) => run_subtitle_convert(options)
    @cli.Retime(options) => run_retime(options)
    @cli.Help(topic) => print_lines(@cli.help_lines(topic))
  }
}
