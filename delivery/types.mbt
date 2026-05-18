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

///|
pub(all) struct DeliverySubtitleProfile {
  name : String
  version : String
  description : String
  qc_profile : @qc.QcProfile
  text_style : @qc.TextStyleProfile
} derive(Eq, Debug)

///|
pub fn ott_zh_subtitle_profile() -> DeliverySubtitleProfile {
  {
    name: "ott-zh",
    version: "v1",
    description: "OTT Chinese subtitle delivery profile",
    qc_profile: @qc.streaming_profile(),
    text_style: @qc.no_text_style_profile(),
  }
}

///|
pub fn cinema_zh_subtitle_profile() -> DeliverySubtitleProfile {
  {
    name: "cinema-zh",
    version: "v1",
    description: "Cinema Chinese subtitle delivery profile",
    qc_profile: @qc.cinema_profile(),
    text_style: @qc.no_text_style_profile(),
  }
}

///|
pub fn broadcast_subtitle_profile() -> DeliverySubtitleProfile {
  {
    name: "broadcast",
    version: "v1",
    description: "Broadcast subtitle delivery profile",
    qc_profile: @qc.streaming_profile(),
    text_style: @qc.no_text_style_profile(),
  }
}

///|
pub fn delivery_subtitle_profiles() -> Array[DeliverySubtitleProfile] {
  [
    ott_zh_subtitle_profile(),
    cinema_zh_subtitle_profile(),
    broadcast_subtitle_profile(),
  ]
}

///|
pub fn delivery_subtitle_profile_by_name(
  name : String,
) -> DeliverySubtitleProfile? {
  match name {
    "ott-zh" | "ott" => Some(ott_zh_subtitle_profile())
    "cinema-zh" | "cinema" => Some(cinema_zh_subtitle_profile())
    "broadcast" => Some(broadcast_subtitle_profile())
    _ => None
  }
}
