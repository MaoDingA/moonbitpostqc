///|
fn creator_profile_from_name(
  name : String,
) -> Result[@creator.CreatorProfile, String] {
  match @creator.creator_profile_by_name(name) {
    Some(profile) => Ok(profile)
    None => Err("unknown creator profile: \{name}")
  }
}

///|
fn creator_check_result_for_text(
  name : String,
  input : String,
  options : @cli.CreatorCheckOptions,
) -> QcCliResult {
  let creator_profile = match creator_profile_from_name(options.profile) {
    Ok(profile) => profile
    Err(message) => {
      let issues = [
        @qc.QcIssue::{ severity: Error, code: "E000", cue_index: None, message },
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
      let issues = @creator.check_creator_cues(track.cues, creator_profile)
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
          severity: Error,
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
struct CleanTextResult {
  output : String
  actions : Array[@qc.CleanAction]
} derive(Eq, Debug)

///|
fn creator_clean_text(
  input : String,
  options : @cli.CreatorCleanOptions,
) -> CleanTextResult? {
  match
    (parse_subtitle_text(input), creator_profile_from_name(options.profile)) {
    (Some(track), Ok(profile)) => {
      let result = @creator.clean_creator_cues(track.cues, profile)
      Some({
        output: write_track({ format: track.format, cues: result.cues }),
        actions: result.actions,
      })
    }
    _ => None
  }
}

///|
fn format_clean_summary(
  name : String,
  actions : Array[@qc.CleanAction],
) -> Array[String] {
  let lines : Array[String] = []
  if actions.length() == 0 {
    lines.push("Clean summary for \{name}:")
    lines.push("  No changes applied.")
    return lines
  }
  lines.push("Clean summary for \{name}:")
  for action in actions {
    lines.push("  \{action.describe()}")
  }
  lines.push("\{actions.length()} action(s) applied.")
  lines
}

///|
async fn run_creator_check(options : @cli.CreatorCheckOptions) -> Int {
  match read_text_file(options.input) {
    Some(text) => {
      let result = creator_check_result_for_text(options.input, text, options)
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
async fn run_creator_clean(options : @cli.CreatorCleanOptions) -> Int {
  match creator_profile_from_name(options.profile) {
    Ok(_) => ()
    Err(message) => {
      println(message)
      return 2
    }
  }
  match read_text_file(options.input) {
    Some(text) =>
      match creator_clean_text(text, options) {
        Some(result) =>
          match options.output {
            Some(path) => {
              if options.verbose {
                print_lines(format_clean_summary(options.input, result.actions))
              }
              if !write_text_file(path, result.output) {
                println("could not write file: \{path}")
                2
              } else {
                0
              }
            }
            None => {
              if options.verbose {
                print_lines(format_clean_summary(options.input, result.actions))
                println("---")
              }
              println(result.output)
              0
            }
          }
        None => {
          println("could not clean creator subtitle: \{options.input}")
          2
        }
      }
    None => {
      println("could not read file: \{options.input}")
      2
    }
  }
}
