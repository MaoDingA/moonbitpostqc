///|
fn profile_list_lines(scope : String) -> Array[String] {
  let lines : Array[String] = ["MoonPost Profile List", ""]
  if scope == "all" || scope == "creator" {
    lines.push("Creator profiles:")
    lines.push("  douyin        抖音/短视频 (max_cps=10, 500~5000ms)")
    lines.push("  bilibili      B站/知识类 (max_cps=9, 800~7000ms)")
    lines.push("  youtube       YouTube/英文 (max_cps=20, 1000~7000ms)")
    lines.push("  bilingual     中英双语 (max_cps=12, 1000~7000ms)")
    lines.push("  xiaohongshu   小红书/口语化 (max_cps=8, 800~5000ms)")
    lines.push("  kuaishou      快手/短视频 (max_cps=10, 500~5000ms)")
    lines.push("  wechat        视频号 (max_cps=10, 800~6000ms)")
    lines.push("  tiktok        TikTok/英文 (max_cps=20, 500~5000ms)")
    lines.push("")
  }
  if scope == "all" || scope == "delivery" {
    lines.push("Delivery subtitle profiles:")
    lines.push(
      "  ott-zh           OTT 中文字幕 (CPL=42, CPS=20, 800~7000ms)",
    )
    lines.push(
      "  cinema-zh        影院中文字幕 (CPL=32, CPS=17, 1000~6000ms)",
    )
    lines.push(
      "  broadcast        广播电视字幕 (CPL=42, CPS=20, 800~7000ms)",
    )
    lines.push(
      "  srt-basic        SRT 基础预检 (CPL=42, CPS=20, 500~7000ms)",
    )
    lines.push(
      "  dcp-source-srt   DCP 源 SRT 预检 (CPL=32, CPS=17, 500~6000ms)",
    )
    lines.push(
      "  dcp-frame-strict DCP 帧网格严格检查 (24fps, 2帧间隔)",
    )
    lines.push("")
    lines.push("China long-form video platform profiles:")
    lines.push(
      "  iqiyi          爱奇艺 (CPL=18, CPS=14, 1000~7000ms, 25fps)",
    )
    lines.push("  youku          优酷 (CPL=20, CPS=15, 1000~7000ms, 25fps)")
    lines.push(
      "  tencent        腾讯视频 (CPL=18, CPS=14, 1000~7000ms, 25fps)",
    )
    lines.push(
      "  nrta           广电送审 GY/T 357-2024 (CPL=15, CPS=12, 1200~7000ms)",
    )
    lines.push("")
    lines.push("Delivery package profiles:")
    lines.push(
      "  distribution     要求 video + subtitle + metadata + checksum",
    )
    lines.push("  creator          要求 video + subtitle, poster 为 warning")
    lines.push("")
  }
  if scope == "all" || scope == "qc" {
    lines.push("QC profiles (legacy qc command):")
    lines.push("  default          CPL=42, CPS=20, 800~7000ms")
    lines.push("  streaming        CPL=42, CPS=20, 25fps frame grid")
    lines.push("  cinema           CPL=32, CPS=17, 24fps frame grid")
    lines.push("  social-video     CPL=30, CPS=24, 30fps frame grid")
    lines.push("")
  }
  lines
}

///|
fn optional_int_str(v : Int?) -> String {
  match v {
    Some(val) => "\{val}"
    None => "none"
  }
}

///|
fn optional_rate_str(r : @timecode.FrameRate?) -> String {
  match r {
    Some(rate) => rate.label()
    None => "none"
  }
}

///|
fn text_style_mode_str(mode : @qc.TextStyleMode) -> String {
  match mode {
    @qc.TextStyleNone => "none"
    @qc.TextStyleZh => "zh"
    @qc.TextStyleEn => "en"
    @qc.TextStyleBilingual => "bilingual"
  }
}

///|
fn profile_show_creator(name : String) -> Array[String] {
  match @creator.creator_profile_by_name(name) {
    Some(profile) => {
      let p = profile.qc_profile
      [
        "Profile: \{profile.name} (creator)",
        "",
        "QC settings:",
        "  max_cpl:         \{optional_int_str(p.max_cpl)}",
        "  max_cps:         \{p.max_cps}",
        "  max_lines:       \{p.max_lines}",
        "  min_duration_ms: \{p.min_duration_ms}",
        "  max_duration_ms: \{p.max_duration_ms}",
        "  min_gap_frames:  \{p.min_gap_frames}",
        "  frame_rate:      \{optional_rate_str(p.frame_rate)}",
        "",
        "Text style: \{text_style_mode_str(profile.text_style.mode)}",
        "Punctuation mode: \{text_style_mode_str(profile.punctuation_mode)}",
        "",
        "Active checks:",
        "  - Structural QC (duration, overlap, gap)",
        "  - Text style (punctuation, paired symbols, unbroken blocks)",
        "  - Terminology (confusion pairs, consistency, user terms)",
        "  - AI clean (repeated words, ASR markers, filler words)",
      ]
    }
    None => ["Unknown creator profile: \{name}"]
  }
}

///|
fn profile_show_delivery(name : String) -> Array[String] {
  match @delivery.delivery_subtitle_profile_by_name(name) {
    Some(profile) => {
      let p = profile.qc_profile
      [
        "Profile: \{profile.name} (delivery subtitle)",
        "",
        "QC settings:",
        "  max_cpl:         \{optional_int_str(p.max_cpl)}",
        "  max_cps:         \{p.max_cps}",
        "  max_lines:       \{p.max_lines}",
        "  min_duration_ms: \{p.min_duration_ms}",
        "  max_duration_ms: \{p.max_duration_ms}",
        "  min_gap_frames:  \{p.min_gap_frames}",
        "  frame_rate:      \{optional_rate_str(p.frame_rate)}",
      ]
    }
    None => ["Unknown delivery subtitle profile: \{name}"]
  }
}

///|
fn profile_show_lines(scope : String, name : String) -> Array[String] {
  if scope == "creator" {
    profile_show_creator(name)
  } else if scope == "delivery" {
    profile_show_delivery(name)
  } else {
    ["Usage: moonpost profile show <creator|delivery> --name <profile-name>"]
  }
}

///|
fn run_profile_list(scope : String) -> Int {
  print_lines(profile_list_lines(scope))
  0
}

///|
fn run_profile_show(scope : String, name : String) -> Int {
  if name.is_empty() {
    println(
      "Usage: moonpost profile show <creator|delivery> --name <profile-name>",
    )
    return 0
  }
  print_lines(profile_show_lines(scope, name))
  0
}
