///|
fn Severity::label(self : Severity) -> String {
  match self {
    Error => "ERROR"
    Warning => "WARN"
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
