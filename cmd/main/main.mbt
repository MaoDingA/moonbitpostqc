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

///|
extern "c" fn exit_process(code : Int) = "exit"

///|
priv struct QcCliResult {
  lines : Array[String]
  exit_code : Int
}

///|
priv struct PackageSubtitleInput {
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
fn creator_clean_text(
  input : String,
  options : @cli.CreatorCleanOptions,
) -> String? {
  match
    (parse_subtitle_text(input), creator_profile_from_name(options.profile)) {
    (Some(track), Ok(profile)) => {
      let cues : Array[@subtitle.Cue] = []
      for cue in track.cues {
        let text : Array[String] = []
        for line in cue.text {
          text.push(@creator.normalize_creator_line(line, profile))
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
          })
        None => Ok(profile)
      }
    None => Err("unknown delivery subtitle profile: \{name}")
  }
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
      @qc.Error => errors += 1
      @qc.Warning => warnings += 1
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
        @qc.QcIssue::{
          severity: @qc.Error,
          code: "E000",
          cue_index: None,
          message,
        },
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
      let issues = @qc.check_cues_with_text_style(
        track.cues,
        delivery_profile.qc_profile,
        delivery_profile.text_style,
      )
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
          severity: @qc.Error,
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
    @delivery.VideoAsset => "video"
    @delivery.SubtitleAsset => "subtitle"
    @delivery.PosterAsset => "poster"
    @delivery.MetadataAsset => "metadata"
    @delivery.ChecksumAsset => "checksum"
    @delivery.ManifestAsset => "manifest"
    @delivery.OtherAsset => "other"
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
      let subtitle_issues = @qc.check_cues_with_text_style(
        track.cues,
        profile.qc_profile,
        profile.text_style,
      )
      if subtitle_issues.length() > 0 {
        let (errors, warnings) = issue_counts(subtitle_issues)
        push_cli_issue(
          issues,
          if @qc.has_errors(subtitle_issues) {
            @qc.Error
          } else {
            @qc.Warning
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
  let subtitle_profile = match
    delivery_subtitle_profile_from_parts(
      options.subtitle_profile,
      options.frame_rate,
    ) {
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
  let issues : Array[@qc.QcIssue] = []
  let manifest = match manifest_raw {
    Some(raw) =>
      match @delivery.parse_manifest(raw) {
        Ok(value) => Some(value)
        Err(message) => {
          push_cli_issue(
            issues,
            @qc.Error,
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
async fn read_directory_entries(path : String) -> Array[String]? {
  Some(@fs.readdir(path, sort=true)) catch {
    _ => None
  }
}

///|
fn first_checksum_file(entries : Array[String]) -> String? {
  for name in entries {
    if @delivery.classify_asset(name) == @delivery.ChecksumAsset {
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
        if @delivery.classify_asset(name) == @delivery.SubtitleAsset {
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
