///|
pub(all) struct DeliveryAsset {
  name : String
  kind : AssetKind
  language : String?
} derive(Eq, Debug)

///|
pub(all) struct DeliveryPackage {
  name : String
  assets : Array[DeliveryAsset]
  manifest : DeliveryManifest?
} derive(Eq, Debug)

///|
pub fn package_assets_from_names(names : Array[String]) -> Array[DeliveryAsset] {
  let assets : Array[DeliveryAsset] = []
  for name in names {
    assets.push({
      name,
      kind: classify_asset(name),
      language: language_from_subtitle_name(name),
    })
  }
  assets
}

///|
fn asset_kind_label(kind : AssetKind) -> String {
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
fn has_asset_kind(assets : Array[DeliveryAsset], kind : AssetKind) -> Bool {
  assets.any(asset => asset.kind == kind)
}

///|
fn has_subtitle_language(
  assets : Array[DeliveryAsset],
  language : String,
) -> Bool {
  assets.any(asset => {
    asset.kind == SubtitleAsset && asset.language == Some(language)
  })
}

///|
fn push_package_issue(
  issues : Array[@qc.QcIssue],
  severity : @qc.Severity,
  code : String,
  message : String,
) -> Unit {
  issues.push({ severity, code, cue_index: None, message })
}

///|
fn require_asset_kind(
  issues : Array[@qc.QcIssue],
  assets : Array[DeliveryAsset],
  kind : AssetKind,
) -> Unit {
  let label = asset_kind_label(kind)
  if !has_asset_kind(assets, kind) &&
    !issues.any(issue => issue.code == "D101" && issue.message.contains(label)) {
    push_package_issue(
      issues,
      @qc.Error,
      "D101",
      "missing required asset: \{label}",
    )
  }
}

///|
fn warn_asset_kind(
  issues : Array[@qc.QcIssue],
  assets : Array[DeliveryAsset],
  kind : AssetKind,
) -> Unit {
  if !has_asset_kind(assets, kind) {
    push_package_issue(
      issues,
      @qc.Warning,
      "D102",
      "missing recommended asset: \{asset_kind_label(kind)}",
    )
  }
}

///|
fn check_profile_assets(
  issues : Array[@qc.QcIssue],
  pkg : DeliveryPackage,
  profile : DeliveryProfile,
) -> Unit {
  if profile.require_video {
    require_asset_kind(issues, pkg.assets, VideoAsset)
  }
  if profile.require_subtitle {
    require_asset_kind(issues, pkg.assets, SubtitleAsset)
  }
  if profile.require_metadata {
    require_asset_kind(issues, pkg.assets, MetadataAsset)
  }
  if profile.require_checksum {
    require_asset_kind(issues, pkg.assets, ChecksumAsset)
  }
  if profile.warn_missing_poster {
    warn_asset_kind(issues, pkg.assets, PosterAsset)
  }
}

///|
fn check_manifest_assets(
  issues : Array[@qc.QcIssue],
  pkg : DeliveryPackage,
  manifest : DeliveryManifest,
) -> Unit {
  for kind in manifest.required_assets {
    require_asset_kind(issues, pkg.assets, kind)
  }
}

///|
fn check_manifest_subtitles(
  issues : Array[@qc.QcIssue],
  pkg : DeliveryPackage,
  manifest : DeliveryManifest,
) -> Unit {
  for language in manifest.required_subtitles {
    if !has_subtitle_language(pkg.assets, language) {
      push_package_issue(
        issues,
        @qc.Error,
        "D202",
        "missing required subtitle language: \{language}",
      )
    }
  }
}

///|
pub fn check_package(
  pkg : DeliveryPackage,
  profile : DeliveryProfile,
) -> Array[@qc.QcIssue] {
  let issues : Array[@qc.QcIssue] = []
  check_profile_assets(issues, pkg, profile)
  match pkg.manifest {
    Some(manifest) => {
      check_manifest_assets(issues, pkg, manifest)
      check_manifest_subtitles(issues, pkg, manifest)
    }
    None => ()
  }
  issues
}
