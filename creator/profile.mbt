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
    qc_profile: {
      max_cpl: None,
      max_cps: 10,
      max_lines: 2,
      min_duration_ms: 500,
      max_duration_ms: 5000,
      min_gap_frames: 1,
      frame_rate: None,
      max_wps: None,
      max_line_imbalance: None,
    },
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: TextStyleZh,
  }
}

///|
pub fn bilibili_profile() -> CreatorProfile {
  {
    name: "bilibili",
    qc_profile: {
      max_cpl: None,
      max_cps: 9,
      max_lines: 2,
      min_duration_ms: 800,
      max_duration_ms: 7000,
      min_gap_frames: 2,
      frame_rate: None,
      max_wps: None,
      max_line_imbalance: None,
    },
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: TextStyleZh,
  }
}

///|
pub fn youtube_profile() -> CreatorProfile {
  {
    name: "youtube",
    qc_profile: {
      max_cpl: None,
      max_cps: 20,
      max_lines: 2,
      min_duration_ms: 1000,
      max_duration_ms: 7000,
      min_gap_frames: 2,
      frame_rate: None,
      max_wps: Some(3),
      max_line_imbalance: None,
    },
    text_style: @qc.en_text_style_profile(),
    punctuation_mode: TextStyleEn,
  }
}

///|
pub fn bilingual_profile() -> CreatorProfile {
  {
    name: "bilingual",
    qc_profile: {
      max_cpl: None,
      max_cps: 12,
      max_lines: 2,
      min_duration_ms: 1000,
      max_duration_ms: 7000,
      min_gap_frames: 2,
      frame_rate: None,
      max_wps: None,
      max_line_imbalance: Some(2),
    },
    text_style: @qc.bilingual_text_style_profile(),
    punctuation_mode: TextStyleBilingual,
  }
}

///|
pub fn xiaohongshu_profile() -> CreatorProfile {
  {
    name: "xiaohongshu",
    qc_profile: {
      max_cpl: None,
      max_cps: 8,
      max_lines: 2,
      min_duration_ms: 800,
      max_duration_ms: 5000,
      min_gap_frames: 1,
      frame_rate: None,
      max_wps: None,
      max_line_imbalance: None,
    },
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: TextStyleZh,
  }
}

///|
pub fn kuaishou_profile() -> CreatorProfile {
  {
    name: "kuaishou",
    qc_profile: {
      max_cpl: None,
      max_cps: 10,
      max_lines: 2,
      min_duration_ms: 500,
      max_duration_ms: 5000,
      min_gap_frames: 1,
      frame_rate: None,
      max_wps: None,
      max_line_imbalance: None,
    },
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: TextStyleZh,
  }
}

///|
pub fn wechat_profile() -> CreatorProfile {
  {
    name: "wechat",
    qc_profile: {
      max_cpl: None,
      max_cps: 10,
      max_lines: 2,
      min_duration_ms: 800,
      max_duration_ms: 6000,
      min_gap_frames: 2,
      frame_rate: None,
      max_wps: None,
      max_line_imbalance: None,
    },
    text_style: @qc.zh_text_style_profile(),
    punctuation_mode: TextStyleZh,
  }
}

///|
pub fn tiktok_profile() -> CreatorProfile {
  {
    name: "tiktok",
    qc_profile: {
      max_cpl: None,
      max_cps: 20,
      max_lines: 2,
      min_duration_ms: 500,
      max_duration_ms: 5000,
      min_gap_frames: 1,
      frame_rate: None,
      max_wps: Some(3),
      max_line_imbalance: None,
    },
    text_style: @qc.en_text_style_profile(),
    punctuation_mode: TextStyleEn,
  }
}

///|
pub fn creator_profile_by_name(name : String) -> CreatorProfile? {
  match name {
    "douyin" | "short-video" => Some(douyin_profile())
    "bilibili" | "bili" => Some(bilibili_profile())
    "youtube" | "yt" => Some(youtube_profile())
    "bilingual" | "zh-en" => Some(bilingual_profile())
    "xiaohongshu" | "xhs" | "rednote" => Some(xiaohongshu_profile())
    "kuaishou" | "ks" => Some(kuaishou_profile())
    "wechat" | "wechat-video" | "channels" => Some(wechat_profile())
    "tiktok" => Some(tiktok_profile())
    _ => None
  }
}
