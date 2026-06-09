///|
fn delivery_subtitle_profile_from_options(
  options : @cli.DeliverySubtitleCheckOptions,
) -> Result[@delivery.DeliverySubtitleProfile, String] {
  delivery_subtitle_profile_from_parts(options.profile, options.frame_rate)
}

///|
fn delivery_subtitle_profile_from_parts(
  name : String,
  frame_rate : @timecode.FrameRate?,
) -> Result[@delivery.DeliverySubtitleProfile, String] {
  match @delivery.delivery_subtitle_profile_by_name(name) {
    Some(profile) =>
      match frame_rate {
        Some(rate) =>
          Ok({
            name: profile.name,
            version: profile.version,
            description: profile.description,
            qc_profile: {
              max_cpl: profile.qc_profile.max_cpl,
              max_cps: profile.qc_profile.max_cps,
              max_lines: profile.qc_profile.max_lines,
              min_duration_ms: profile.qc_profile.min_duration_ms,
              max_duration_ms: profile.qc_profile.max_duration_ms,
              min_gap_frames: profile.qc_profile.min_gap_frames,
              frame_rate: Some(rate),
            },
            text_style: profile.text_style,
            srt_policy: profile.srt_policy,
          })
        None => Ok(profile)
      }
    None => Err("unknown delivery subtitle profile: \{name}")
  }
}

///|
fn check_delivery_subtitle_track(
  track : @subtitle.SubtitleTrack,
  profile : @delivery.DeliverySubtitleProfile,
) -> Array[@qc.QcIssue] {
  let issues = @qc.check_cues_with_text_style(
    track.cues,
    profile.qc_profile,
    profile.text_style,
  )
  match profile.srt_policy {
    Some(policy) =>
      for issue in @qc.check_srt_source_track(track, policy) {
        issues.push(issue)
      }
    None => ()
  }
  issues
}

///|
fn delivery_package_profile_from_name(
  name : String,
) -> Result[@delivery.DeliveryProfile, String] {
  match @delivery.delivery_profile_by_name(name) {
    Some(profile) => Ok(profile)
    None => Err("unknown delivery package profile: \{name}")
  }
}

///|
fn push_cli_issue(
  issues : Array[@qc.QcIssue],
  severity : @qc.Severity,
  code : String,
  message : String,
) -> Unit {
  issues.push({ severity, code, cue_index: None, message })
}

///|
fn issue_counts(issues : Array[@qc.QcIssue]) -> (Int, Int) {
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
fn exit_code_for_issues(
  issues : Array[@qc.QcIssue],
  fail_on_error : Bool,
  fail_on_warning : Bool,
) -> Int {
  if (fail_on_error || fail_on_warning) && @qc.has_errors(issues) {
    1
  } else if fail_on_warning && @qc.has_warnings(issues) {
    1
  } else {
    0
  }
}

///|
fn delivery_subtitle_json_report(
  name : String,
  issues : Array[@qc.QcIssue],
  profile : @delivery.DeliverySubtitleProfile?,
  options : @cli.DeliverySubtitleCheckOptions,
  exit_code : Int,
) -> String {
  let context = match profile {
    Some(profile) =>
      @qc.QcReportContext::{
        command: "delivery subtitle-check",
        schema_version: "moonpost.qc.v1",
        profile_name: Some(profile.name),
        profile_version: Some(profile.version),
        profile_description: Some(profile.description),
        fail_on_error: options.fail_on_error,
        fail_on_warning: options.fail_on_warning,
        exit_code,
      }
    None =>
      @qc.QcReportContext::{
        command: "delivery subtitle-check",
        schema_version: "moonpost.qc.v1",
        profile_name: None,
        profile_version: None,
        profile_description: None,
        fail_on_error: options.fail_on_error,
        fail_on_warning: options.fail_on_warning,
        exit_code,
      }
  }
  @qc.format_json_report_with_context(name, issues, context)
}

///|
fn delivery_subtitle_result_for_text(
  name : String,
  input : String,
  options : @cli.DeliverySubtitleCheckOptions,
) -> QcCliResult {
  let delivery_profile = match delivery_subtitle_profile_from_options(options) {
    Ok(profile) => profile
    Err(message) => {
      let issues = [
        @qc.QcIssue::{ severity: Error, code: "E000", cue_index: None, message },
      ]
      return {
        lines: if options.output_json {
          [delivery_subtitle_json_report(name, issues, None, options, 2)]
        } else {
          @qc.format_report(name, issues)
        },
        exit_code: 2,
      }
    }
  }
  match parse_subtitle_text_detailed(input) {
    Ok(track) => {
      let issues = check_delivery_subtitle_track(track, delivery_profile)
      let exit_code = if (options.fail_on_error || options.fail_on_warning) &&
        @qc.has_errors(issues) {
        1
      } else if options.fail_on_warning && @qc.has_warnings(issues) {
        1
      } else {
        0
      }
      let lines = if options.output_json {
        [
          delivery_subtitle_json_report(
            name,
            issues,
            Some(delivery_profile),
            options,
            exit_code,
          ),
        ]
      } else {
        @qc.format_report(name, issues)
      }
      { lines, exit_code }
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
          [
            delivery_subtitle_json_report(
              name,
              issues,
              Some(delivery_profile),
              options,
              2,
            ),
          ]
        } else {
          @qc.format_report(name, issues)
        },
        exit_code: 2,
      }
    }
  }
}

///|
fn delivery_asset_kind_label(kind : @delivery.AssetKind) -> String {
  match kind {
    VideoAsset => "video"
    SubtitleAsset => "subtitle"
    PosterAsset => "poster"
    MetadataAsset => "metadata"
    ChecksumAsset => "checksum"
    ManifestAsset => "manifest"
    OtherAsset => "other"
  }
}

///|
fn severity_json_label(severity : @qc.Severity) -> String {
  match severity {
    @qc.Error => "error"
    @qc.Warning => "warning"
  }
}

///|
fn int_json(value : Int) -> Json {
  Json::number(Double::from_int(value), repr="\{value}")
}

///|
fn bool_json(value : Bool) -> Json {
  Json::boolean(value)
}

///|
fn optional_int_json(value : Int?) -> Json {
  match value {
    Some(value) => int_json(value)
    None => Json::null()
  }
}

///|
fn optional_string_json(value : String?) -> Json {
  match value {
    Some(value) => Json::string(value)
    None => Json::null()
  }
}

///|
fn issue_json_value(issue : @qc.QcIssue) -> Json {
  Json::object(
    Map([
      ("severity", Json::string(severity_json_label(issue.severity))),
      ("code", Json::string(issue.code)),
      ("cue_index", optional_int_json(issue.cue_index)),
      ("message", Json::string(issue.message)),
    ]),
  )
}

///|
fn asset_json_value(asset : @delivery.DeliveryAsset) -> Json {
  Json::object(
    Map([
      ("name", Json::string(asset.name)),
      ("kind", Json::string(delivery_asset_kind_label(asset.kind))),
      ("language", optional_string_json(asset.language)),
    ]),
  )
}

///|
fn format_delivery_package_json(
  name : String,
  pkg : @delivery.DeliveryPackage,
  issues : Array[@qc.QcIssue],
  options : @cli.DeliveryCheckOptions,
  exit_code : Int,
) -> String {
  let (errors, warnings) = issue_counts(issues)
  let issue_values : Array[Json] = []
  for issue in issues {
    issue_values.push(issue_json_value(issue))
  }
  let asset_values : Array[Json] = []
  for asset in pkg.assets {
    asset_values.push(asset_json_value(asset))
  }
  Json::object(
    Map([
      ("schema_version", Json::string("moonpost.delivery.v1")),
      ("command", Json::string("delivery check")),
      ("name", Json::string(name)),
      ("package_profile", Json::string(options.profile)),
      ("subtitle_profile", Json::string(options.subtitle_profile)),
      ("assets", Json::array(asset_values)),
      ("manifest_present", bool_json(pkg.manifest is Some(_))),
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
            ("fail_on_error", bool_json(options.fail_on_error)),
            ("fail_on_warning", bool_json(options.fail_on_warning)),
            ("code", int_json(exit_code)),
          ]),
        ),
      ),
      ("issues", Json::array(issue_values)),
    ]),
  ).stringify()
}

///|
fn prefixed_subtitle_issue(
  file_name : String,
  issue : @qc.QcIssue,
) -> @qc.QcIssue {
  {
    severity: issue.severity,
    code: issue.code,
    cue_index: issue.cue_index,
    message: "\{file_name}: \{issue.message}",
  }
}

///|
fn append_subtitle_check_issues(
  issues : Array[@qc.QcIssue],
  subtitle : PackageSubtitleInput,
  profile : @delivery.DeliverySubtitleProfile,
) -> Unit {
  match parse_subtitle_text_detailed(subtitle.text) {
    Ok(track) => {
      let subtitle_issues = check_delivery_subtitle_track(track, profile)
      if subtitle_issues.length() > 0 {
        let (errors, warnings) = issue_counts(subtitle_issues)
        push_cli_issue(
          issues,
          if @qc.has_errors(subtitle_issues) {
            Error
          } else {
            Warning
          },
          "D302",
          "\{subtitle.name}: subtitle QC reported \{errors} errors, \{warnings} warnings",
        )
        for issue in subtitle_issues {
          issues.push(prefixed_subtitle_issue(subtitle.name, issue))
        }
      }
    }
    Err(error) =>
      push_cli_issue(
        issues,
        @qc.Error,
        "D301",
        "\{subtitle.name}: could not parse subtitle file: \{error.format_message()}",
      )
  }
}

///|
fn delivery_package_result_for_inputs_with_checksums(
  name : String,
  asset_names : Array[String],
  manifest_raw : String?,
  checksum_raw : String?,
  actual_sha256_by_name : Map[String, String],
  subtitles : Array[PackageSubtitleInput],
  options : @cli.DeliveryCheckOptions,
) -> QcCliResult {
  let package_profile = match
    delivery_package_profile_from_name(options.profile) {
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
  let subtitle_profile = match
    delivery_subtitle_profile_from_parts(
      options.subtitle_profile,
      options.frame_rate,
    ) {
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
  let issues : Array[@qc.QcIssue] = []
  let manifest = match manifest_raw {
    Some(raw) =>
      match @delivery.parse_manifest(raw) {
        Ok(value) => Some(value)
        Err(message) => {
          push_cli_issue(
            issues,
            Error,
            "D201",
            "could not parse delivery manifest: \{message}",
          )
          None
        }
      }
    None => None
  }
  let pkg = @delivery.DeliveryPackage::{
    name,
    assets: @delivery.package_assets_from_names(asset_names),
    manifest,
  }
  for issue in @delivery.check_package(pkg, package_profile) {
    issues.push(issue)
  }
  match checksum_raw {
    Some(raw) => {
      let checksum_manifest = @delivery.parse_checksum_manifest(raw)
      for issue in checksum_manifest.issues {
        issues.push(issue)
      }
      for
        issue in @delivery.check_checksum_entries(
          checksum_manifest.entries,
          asset_names,
          actual_sha256_by_name,
        ) {
        issues.push(issue)
      }
    }
    None => ()
  }
  for subtitle in subtitles {
    append_subtitle_check_issues(issues, subtitle, subtitle_profile)
  }
  let exit_code = exit_code_for_issues(
    issues,
    options.fail_on_error,
    options.fail_on_warning,
  )
  {
    lines: if options.output_json {
      [format_delivery_package_json(name, pkg, issues, options, exit_code)]
    } else {
      @qc.format_report(name, issues)
    },
    exit_code,
  }
}

///|
fn first_checksum_file(entries : Array[String]) -> String? {
  for name in entries {
    if @delivery.classify_asset(name) == ChecksumAsset {
      return Some(name)
    }
  }
  None
}

///|
async fn checksum_hashes_for_manifest(
  folder : String,
  checksum_raw : String,
) -> Map[String, String] {
  let hashes : Map[String, String] = Map([])
  let manifest = @delivery.parse_checksum_manifest(checksum_raw)
  for entry in manifest.entries {
    match sha256_file_hex(join_path(folder, entry.target)) {
      Some(hash) => hashes[entry.target] = hash
      None => ()
    }
  }
  hashes
}

///|
async fn sha256_file_hex(path : String) -> String? {
  try {
    let file = @fs.open(path, mode=ReadOnly)
    defer file.close()
    let state = @delivery.Sha256State::new()
    while file.read_some(max_len=65536) is Some(chunk) {
      state.update(chunk)
    }
    Some(state.final_hex())
  } catch {
    _ => None
  }
}

///|
async fn run_delivery_subtitle_check(
  options : @cli.DeliverySubtitleCheckOptions,
) -> Int {
  match read_text_file(options.input) {
    Some(text) => {
      let result = delivery_subtitle_result_for_text(
        options.input,
        text,
        options,
      )
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
async fn run_delivery_check(options : @cli.DeliveryCheckOptions) -> Int {
  match read_directory_entries(options.input) {
    Some(entries) => {
      let manifest_raw = if entries.contains("moonpost.delivery.json") {
        read_text_file(join_path(options.input, "moonpost.delivery.json"))
      } else {
        None
      }
      let checksum_raw = match first_checksum_file(entries) {
        Some(name) => read_text_file(join_path(options.input, name))
        None => None
      }
      let checksum_hashes = match checksum_raw {
        Some(raw) => checksum_hashes_for_manifest(options.input, raw)
        None => Map([])
      }
      let subtitles : Array[PackageSubtitleInput] = []
      for name in entries {
        if @delivery.classify_asset(name) == SubtitleAsset {
          match read_text_file(join_path(options.input, name)) {
            Some(text) => subtitles.push({ name, text })
            None => subtitles.push({ name, text: "" })
          }
        }
      }
      let result = delivery_package_result_for_inputs_with_checksums(
        options.input,
        entries,
        manifest_raw,
        checksum_raw,
        checksum_hashes,
        subtitles,
        options,
      )
      print_lines(result.lines)
      result.exit_code
    }
    None => {
      println("could not read delivery folder: \{options.input}")
      2
    }
  }
}
