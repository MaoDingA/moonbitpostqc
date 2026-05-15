///|
pub(all) struct QcOptions {
  input : String
  profile : String
  frame_rate : @timecode.FrameRate?
} derive(Eq, Debug)

///|
pub(all) struct TimecodeValueOptions {
  value : String
  frame_rate : @timecode.FrameRate
} derive(Eq, Debug)

///|
pub(all) struct FrameCountOptions {
  frames : Int
  frame_rate : @timecode.FrameRate
} derive(Eq, Debug)

///|
pub(all) struct TimecodeConvertOptions {
  value : String
  source_rate : @timecode.FrameRate
  target_rate : @timecode.FrameRate
} derive(Eq, Debug)

///|
pub(all) struct SubtitleConvertOptions {
  input : String
  target : String
  output : String?
} derive(Eq, Debug)

///|
pub(all) struct RetimeOptions {
  input : String
  output : String?
  offset_ms : Int
  source_rate : @timecode.FrameRate?
  target_rate : @timecode.FrameRate?
  snap_rate : @timecode.FrameRate?
} derive(Eq, Debug)

///|
pub(all) enum TimecodeCommand {
  ToFrames(TimecodeValueOptions)
  FromFrames(FrameCountOptions)
  ConvertTimecode(TimecodeConvertOptions)
} derive(Eq, Debug)

///|
pub(all) enum SubtitleCommand {
  Convert(SubtitleConvertOptions)
} derive(Eq, Debug)

///|
pub(all) enum HelpTopic {
  RootHelp
  QcHelp
  TimecodeHelp
  SubtitleHelp
} derive(Eq, Debug)

///|
pub(all) enum Command {
  Qc(QcOptions)
  Timecode(TimecodeCommand)
  Subtitle(SubtitleCommand)
  Retime(RetimeOptions)
  Help(HelpTopic)
} derive(Eq, Debug)

///|
fn option_value(
  args : Array[String],
  flag : String,
  default : String,
) -> String {
  let mut value = default
  for index in 0..<args.length() {
    if args[index] == flag {
      match args.get(index + 1) {
        Some(next) => value = next
        None => ()
      }
    }
  }
  value
}

///|
fn option_string(args : Array[String], flag : String) -> String? {
  let raw = option_value(args, flag, "")
  if raw.is_empty() {
    None
  } else {
    Some(raw)
  }
}

///|
fn has_help(args : Array[String]) -> Bool {
  args.contains("--help") || args.contains("-h")
}

///|
fn parse_int(raw : String) -> Int? {
  Some(@string.parse_int(raw)) catch {
    _ => None
  }
}

///|
fn split_to_strings(raw : String, separator : String) -> Array[String] {
  let parts : Array[String] = []
  for part in raw.split(separator) {
    parts.push(part.to_owned())
  }
  parts
}

///|
fn parse_offset_ms(raw : String) -> Int {
  let value = match split_to_strings(raw, "ms") {
    [number, ""] => number
    _ => raw
  }
  match parse_int(value) {
    Some(ms) => ms
    None => 0
  }
}

///|
pub fn parse_frame_rate(raw : String) -> @timecode.FrameRate? {
  match raw {
    "23.976" | "23976" => Some(@timecode.Fps23976)
    "24" => Some(@timecode.Fps24)
    "25" => Some(@timecode.Fps25)
    "29.97df" | "29.97DF" | "29.97-drop" | "2997df" =>
      Some(@timecode.Fps2997Drop)
    "29.97" | "2997" => Some(@timecode.Fps2997NonDrop)
    "30" => Some(@timecode.Fps30)
    "50" => Some(@timecode.Fps50)
    "59.94df" | "59.94DF" | "59.94-drop" | "5994df" =>
      Some(@timecode.Fps5994Drop)
    "59.94" | "5994" => Some(@timecode.Fps5994NonDrop)
    _ => None
  }
}

///|
fn option_frame_rate(
  args : Array[String],
  flag : String,
  default : @timecode.FrameRate,
) -> @timecode.FrameRate {
  match parse_frame_rate(option_value(args, flag, "")) {
    Some(rate) => rate
    None => default
  }
}

///|
fn parse_qc(args : Array[String]) -> Command {
  if has_help(args) {
    Help(QcHelp)
  } else {
    Qc({
      input: option_value(
        args,
        "__input",
        match args.get(2) {
          Some(value) => value
          None => ""
        },
      ),
      profile: option_value(args, "--profile", "default"),
      frame_rate: parse_frame_rate(option_value(args, "--fps", "")),
    })
  }
}

///|
fn parse_timecode(args : Array[String]) -> Command {
  if has_help(args) {
    Help(TimecodeHelp)
  } else {
    match args.get(2) {
      Some("to-frames") =>
        Timecode(
          ToFrames({
            value: match args.get(3) {
              Some(value) => value
              None => ""
            },
            frame_rate: option_frame_rate(args, "--fps", @timecode.Fps25),
          }),
        )
      Some("from-frames") =>
        Timecode(
          FromFrames({
            frames: match args.get(3) {
              Some(raw) =>
                match parse_int(raw) {
                  Some(value) => value
                  None => 0
                }
              None => 0
            },
            frame_rate: option_frame_rate(args, "--fps", @timecode.Fps25),
          }),
        )
      Some("convert") =>
        Timecode(
          ConvertTimecode({
            value: match args.get(3) {
              Some(value) => value
              None => ""
            },
            source_rate: option_frame_rate(args, "--from", @timecode.Fps23976),
            target_rate: option_frame_rate(args, "--to", @timecode.Fps25),
          }),
        )
      _ => Help(TimecodeHelp)
    }
  }
}

///|
fn parse_subtitle(args : Array[String]) -> Command {
  if has_help(args) {
    Help(SubtitleHelp)
  } else {
    match args.get(2) {
      Some("convert") =>
        Subtitle(
          Convert({
            input: match args.get(3) {
              Some(value) => value
              None => ""
            },
            target: option_value(args, "--to", "webvtt"),
            output: match option_string(args, "-o") {
              Some(value) => Some(value)
              None => option_string(args, "--output")
            },
          }),
        )
      _ => Help(SubtitleHelp)
    }
  }
}

///|
fn parse_retime(args : Array[String]) -> Command {
  if has_help(args) {
    Help(RootHelp)
  } else {
    Retime({
      input: match args.get(2) {
        Some(value) => value
        None => ""
      },
      output: match option_string(args, "-o") {
        Some(value) => Some(value)
        None => option_string(args, "--output")
      },
      offset_ms: parse_offset_ms(option_value(args, "--offset", "0")),
      source_rate: parse_frame_rate(option_value(args, "--from-fps", "")),
      target_rate: parse_frame_rate(option_value(args, "--to-fps", "")),
      snap_rate: parse_frame_rate(option_value(args, "--snap-fps", "")),
    })
  }
}

///|
pub fn parse_command(args : Array[String]) -> Command {
  match args.get(1) {
    Some("qc") => parse_qc(args)
    Some("timecode") => parse_timecode(args)
    Some("subtitle") => parse_subtitle(args)
    Some("retime") => parse_retime(args)
    Some("--help") | Some("-h") => Help(RootHelp)
    _ => Help(RootHelp)
  }
}

///|
pub fn help_lines(topic : HelpTopic) -> Array[String] {
  match topic {
    RootHelp =>
      [
        "MoonPost - subtitle, timecode and post-production QC toolkit", "", "Usage:",
        "  moonpost <command> [options]", "", "Commands:", "  qc          Check subtitle delivery quality",
        "  timecode    Convert SMPTE-style timecode and frame counts", "  subtitle    Convert subtitle formats",
        "  retime      Shift, speed-convert, or snap subtitle timing",
      ]
    QcHelp =>
      ["Usage:", "  moonpost qc <file> [--fps <rate>] [--profile <name>]"]
    TimecodeHelp =>
      [
        "Usage:", "  moonpost timecode to-frames <tc> --fps <rate>", "  moonpost timecode from-frames <frames> --fps <rate>",
        "  moonpost timecode convert <tc> --from <rate> --to <rate>",
      ]
    SubtitleHelp =>
      [
        "Usage:", "  moonpost subtitle convert <file> --to <srt|webvtt> [-o <file>]",
      ]
  }
}
