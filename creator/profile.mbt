///|
pub(all) struct CreatorProfile {
  name : String
  qc_profile : @qc.QcProfile
  text_style : @qc.TextStyleProfile
  punctuation_mode : @qc.TextStyleMode
} derive(Eq, Debug)

///|
pub fn douyin_profile() -> CreatorProfile {
  {
    name: "douyin",
    qc_profile: @qc.social_video_profile(),
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: @qc.TextStyleZh,
  }
}

///|
pub fn bilibili_profile() -> CreatorProfile {
  {
    name: "bilibili",
    qc_profile: @qc.default_profile(),
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: @qc.TextStyleZh,
  }
}

///|
pub fn youtube_profile() -> CreatorProfile {
  {
    name: "youtube",
    qc_profile: @qc.default_profile(),
    text_style: @qc.en_text_style_profile(),
    punctuation_mode: @qc.TextStyleEn,
  }
}

///|
pub fn bilingual_profile() -> CreatorProfile {
  {
    name: "bilingual",
    qc_profile: @qc.streaming_profile(),
    text_style: @qc.bilingual_text_style_profile(),
    punctuation_mode: @qc.TextStyleBilingual,
  }
}

///|
pub fn creator_profile_by_name(name : String) -> CreatorProfile? {
  match name {
    "douyin" | "short-video" => Some(douyin_profile())
    "bilibili" | "bili" => Some(bilibili_profile())
    "youtube" | "yt" => Some(youtube_profile())
    "bilingual" | "zh-en" => Some(bilingual_profile())
    _ => None
  }
}
