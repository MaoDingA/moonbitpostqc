///|
fn Severity::label(self : Severity) -> String {
  match self {
    Error => "ERROR"
    Warning => "WARN"
  }
}

///|
fn Severity::json_label(self : Severity) -> String {
  match self {
    Error => "error"
    Warning => "warning"
  }
}

///|
fn QcIssue::line(self : QcIssue) -> String {
  let cue = match self.cue_index {
    Some(index) => " cue#\{index}"
    None => ""
  }
  "\{self.severity.label()} \{self.code}\{cue} | \{self.message}"
}

///|
fn issue_counts(issues : Array[QcIssue]) -> (Int, Int) {
  let mut errors = 0
  let mut warnings = 0
  for issue in issues {
    match issue.severity {
      Error => errors += 1
      Warning => warnings += 1
    }
  }
  (errors, warnings)
}

///|
pub fn has_errors(issues : Array[QcIssue]) -> Bool {
  for issue in issues {
    if issue.severity == Error {
      return true
    }
  }
  false
}

///|
pub fn has_warnings(issues : Array[QcIssue]) -> Bool {
  for issue in issues {
    if issue.severity == Warning {
      return true
    }
  }
  false
}

///|
pub(all) struct QcReportContext {
  command : String
  schema_version : String
  profile_name : String?
  profile_version : String?
  profile_description : String?
  fail_on_error : Bool
  fail_on_warning : Bool
  exit_code : Int
} derive(Eq, Debug)

///|
fn plural(count : Int, singular : String, plural : String) -> String {
  if count == 1 {
    singular
  } else {
    plural
  }
}

///|
pub fn format_report(name : String, issues : Array[QcIssue]) -> Array[String] {
  let (errors, warnings) = issue_counts(issues)
  let error_word = plural(errors, "error", "errors")
  let warning_word = plural(warnings, "warning", "warnings")
  let lines : Array[String] = [
    name,
    "summary: \{errors} \{error_word}, \{warnings} \{warning_word}",
    "",
  ]
  if issues.length() == 0 {
    lines.push("OK no issues found")
  } else {
    for issue in issues {
      lines.push(issue.line())
    }
  }
  lines
}

///|
fn int_json(value : Int) -> Json {
  Json::number(Double::from_int(value), repr="\{value}")
}

///|
fn optional_int_json(value : Int?) -> Json {
  match value {
    Some(value) => int_json(value)
    None => Json::null()
  }
}

///|
fn bool_json(value : Bool) -> Json {
  Json::boolean(value)
}

///|
fn optional_string_json(value : String?) -> Json {
  match value {
    Some(value) => Json::string(value)
    None => Json::null()
  }
}

///|
fn issue_json(issue : QcIssue) -> Json {
  Json::object(
    Map([
      ("severity", Json::string(issue.severity.json_label())),
      ("code", Json::string(issue.code)),
      ("cue_index", optional_int_json(issue.cue_index)),
      ("message", Json::string(issue.message)),
    ]),
  )
}

///|
pub fn format_json_report(name : String, issues : Array[QcIssue]) -> String {
  let (errors, warnings) = issue_counts(issues)
  let issue_values : Array[Json] = []
  for issue in issues {
    issue_values.push(issue_json(issue))
  }
  Json::object(
    Map([
      ("name", Json::string(name)),
      (
        "summary",
        Json::object(
          Map([("errors", int_json(errors)), ("warnings", int_json(warnings))]),
        ),
      ),
      ("issues", Json::array(issue_values)),
    ]),
  ).stringify()
}

///|
pub fn format_json_report_with_context(
  name : String,
  issues : Array[QcIssue],
  context : QcReportContext,
) -> String {
  let (errors, warnings) = issue_counts(issues)
  let issue_values : Array[Json] = []
  for issue in issues {
    issue_values.push(issue_json(issue))
  }
  Json::object(
    Map([
      ("schema_version", Json::string(context.schema_version)),
      ("command", Json::string(context.command)),
      ("name", Json::string(name)),
      (
        "profile",
        Json::object(
          Map([
            ("name", optional_string_json(context.profile_name)),
            ("version", optional_string_json(context.profile_version)),
            ("description", optional_string_json(context.profile_description)),
          ]),
        ),
      ),
      (
        "summary",
        Json::object(
          Map([("errors", int_json(errors)), ("warnings", int_json(warnings))]),
        ),
      ),
      (
        "exit",
        Json::object(
          Map([
            ("fail_on_error", bool_json(context.fail_on_error)),
            ("fail_on_warning", bool_json(context.fail_on_warning)),
            ("code", int_json(context.exit_code)),
          ]),
        ),
      ),
      ("issues", Json::array(issue_values)),
    ]),
  ).stringify()
}
