///|
pub(all) struct ChecksumEntry {
  expected_sha256 : String
  target : String
} derive(Eq, Debug)

///|
pub(all) struct ChecksumManifest {
  entries : Array[ChecksumEntry]
  issues : Array[@qc.QcIssue]
} derive(Eq, Debug)

///|
fn push_checksum_issue(
  issues : Array[@qc.QcIssue],
  code : String,
  message : String,
) -> Unit {
  issues.push({ severity: @qc.Error, code, cue_index: None, message })
}

///|
fn is_checksum_hex_char(ch : Char) -> Bool {
  (ch >= '0' && ch <= '9') ||
  (ch >= 'a' && ch <= 'f') ||
  (ch >= 'A' && ch <= 'F')
}

///|
fn valid_sha256_digest(raw : String) -> Bool {
  raw.length() == 64 && raw.iter().all(is_checksum_hex_char)
}

///|
fn checksum_parts(line : String) -> Array[String] {
  let parts : Array[String] = []
  for part in line.replace_all(old="\t", new=" ").split(" ") {
    let value = part.trim().to_owned()
    if !value.is_empty() {
      parts.push(value)
    }
  }
  parts
}

///|
fn normalize_checksum_target(raw : String) -> String {
  if raw.has_prefix("*") {
    raw[1:].to_owned()
  } else {
    raw
  }
}

///|
fn safe_checksum_target(target : String) -> Bool {
  !target.is_empty() &&
  !target.has_prefix("/") &&
  !target.has_prefix("../") &&
  target != ".." &&
  !target.contains("/../") &&
  !target.has_suffix("/..") &&
  !target.contains("\\")
}

///|
fn parse_checksum_line(
  line : String,
  line_number : Int,
  entries : Array[ChecksumEntry],
  issues : Array[@qc.QcIssue],
) -> Unit {
  let parts = checksum_parts(line)
  if parts.length() < 2 {
    push_checksum_issue(
      issues,
      "D401",
      "checksum line \{line_number}: malformed entry",
    )
    return
  }
  let digest = parts[0].to_lower()
  let target = normalize_checksum_target(parts[1])
  if !valid_sha256_digest(digest) {
    push_checksum_issue(
      issues,
      "D401",
      "checksum line \{line_number}: invalid sha256 digest",
    )
  } else if !safe_checksum_target(target) {
    push_checksum_issue(
      issues,
      "D401",
      "checksum line \{line_number}: unsafe target path: \{target}",
    )
  } else {
    entries.push({ expected_sha256: digest, target })
  }
}

///|
pub fn parse_checksum_manifest(raw : String) -> ChecksumManifest {
  let entries : Array[ChecksumEntry] = []
  let issues : Array[@qc.QcIssue] = []
  let mut line_number = 0
  for raw_line in raw.split("\n") {
    line_number += 1
    let line = raw_line.trim().to_owned()
    if line.is_empty() || line.has_prefix("#") {
      continue
    }
    parse_checksum_line(line, line_number, entries, issues)
  }
  { entries, issues }
}

///|
pub fn check_checksum_entries(
  entries : Array[ChecksumEntry],
  asset_names : Array[String],
  actual_sha256_by_name : Map[String, String],
) -> Array[@qc.QcIssue] {
  let issues : Array[@qc.QcIssue] = []
  for entry in entries {
    if !asset_names.contains(entry.target) {
      push_checksum_issue(
        issues,
        "D402",
        "checksum target missing: \{entry.target}",
      )
    } else {
      match actual_sha256_by_name.get(entry.target) {
        Some(actual) =>
          if actual.to_lower() != entry.expected_sha256 {
            push_checksum_issue(
              issues,
              "D403",
              "checksum mismatch for \{entry.target}: expected \{entry.expected_sha256}, got \{actual}",
            )
          }
        None =>
          push_checksum_issue(
            issues,
            "D404",
            "could not read checksum target: \{entry.target}",
          )
      }
    }
  }
  issues
}
