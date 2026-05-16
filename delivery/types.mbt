///|
pub(all) enum AssetKind {
  VideoAsset
  SubtitleAsset
  PosterAsset
  MetadataAsset
  ChecksumAsset
  ManifestAsset
  OtherAsset
} derive(Eq, Debug)

///|
pub(all) struct DeliveryProfile {
  name : String
  require_video : Bool
  require_subtitle : Bool
  require_metadata : Bool
  require_checksum : Bool
  warn_missing_poster : Bool
  subtitle_qc : @qc.QcProfile
} derive(Eq, Debug)

///|
fn lower_name(name : String) -> String {
  name.to_lower()
}

///|
pub fn classify_asset(name : String) -> AssetKind {
  let lower = lower_name(name)
  if lower == "moonpost.delivery.json" {
    ManifestAsset
  } else if lower == "checksum.txt" ||
    lower == "checksums.txt" ||
    name == "SHA256SUMS" {
    ChecksumAsset
  } else if lower.has_suffix(".mp4") ||
    lower.has_suffix(".mov") ||
    lower.has_suffix(".mxf") {
    VideoAsset
  } else if lower.has_suffix(".srt") || lower.has_suffix(".vtt") {
    SubtitleAsset
  } else if lower.has_suffix(".jpg") ||
    lower.has_suffix(".jpeg") ||
    lower.has_suffix(".png") ||
    lower.has_suffix(".webp") {
    PosterAsset
  } else if lower.has_suffix(".json") {
    MetadataAsset
  } else {
    OtherAsset
  }
}

///|
fn known_language_token(token : String) -> Bool {
  match token {
    "zh"
    | "zh-Hans"
    | "zh-Hant"
    | "en"
    | "en-US"
    | "en-GB"
    | "ja"
    | "ko"
    | "es"
    | "fr"
    | "de"
    | "pt"
    | "pt-BR"
    | "it" => true
    _ => false
  }
}

///|
pub fn language_from_subtitle_name(name : String) -> String? {
  match classify_asset(name) {
    SubtitleAsset => {
      let parts : Array[String] = []
      for part in name.split(".") {
        parts.push(part.to_owned())
      }
      if parts.length() < 3 {
        None
      } else {
        let token = parts[parts.length() - 2]
        if known_language_token(token) {
          Some(token)
        } else {
          None
        }
      }
    }
    _ => None
  }
}

///|
pub fn creator_profile() -> DeliveryProfile {
  {
    name: "creator",
    require_video: true,
    require_subtitle: true,
    require_metadata: false,
    require_checksum: false,
    warn_missing_poster: true,
    subtitle_qc: @qc.social_video_profile(),
  }
}

///|
pub fn distribution_profile() -> DeliveryProfile {
  {
    name: "distribution",
    require_video: true,
    require_subtitle: true,
    require_metadata: true,
    require_checksum: true,
    warn_missing_poster: true,
    subtitle_qc: @qc.streaming_profile(),
  }
}

///|
pub fn delivery_profile_by_name(name : String) -> DeliveryProfile? {
  match name {
    "creator" => Some(creator_profile())
    "distribution" => Some(distribution_profile())
    _ => None
  }
}
