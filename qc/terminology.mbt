///|
pub(all) struct ConfusionPair {
  wrong : String
  correct : String
  context : String
} derive(Eq, Debug)

///|
pub(all) struct ConsistencyTerm {
  canonical : String
  variants : Array[String]
} derive(Eq, Debug)

///|
pub(all) struct UserTerm {
  pattern : String
  preferred : String
  reason : String
  forbidden : Bool
} derive(Eq, Debug)

///|
fn default_confusion_pairs() -> Array[ConfusionPair] {
  [
    // 的/地/得
    {
      wrong: "认真的做",
      correct: "认真地做",
      context: "的/地: '做' is verb, use '地'",
    },
    {
      wrong: "快的跑",
      correct: "快地跑",
      context: "的/地: '跑' is verb, use '地'",
    },
    {
      wrong: "跑的快",
      correct: "跑得快",
      context: "的/得: complement of degree uses '得'",
    },
    {
      wrong: "做的好",
      correct: "做得好",
      context: "的/得: complement of degree uses '得'",
    },
    {
      wrong: "说的对",
      correct: "说得对",
      context: "的/得: complement of degree uses '得'",
    },
    // 在/再
    {
      wrong: "我在去",
      correct: "我再去",
      context: "在/再: '再' for repetition, not '在'",
    },
    {
      wrong: "再家",
      correct: "在家",
      context: "在/再: location uses '在', not '再'",
    },
    {
      wrong: "再一起",
      correct: "在一起",
      context: "在/再: location uses '在', not '再'",
    },
    // 做/作
    {
      wrong: "作事情",
      correct: "做事情",
      context: "做/作: '做' for concrete action, not '作'",
    },
    {
      wrong: "做贡献",
      correct: "作贡献",
      context: "做/作: '作' for abstract contribution",
    },
    {
      wrong: "做准备",
      correct: "作准备",
      context: "做/作: '作' for abstract preparation",
    },
    // 截止/截至
    {
      wrong: "截至日期",
      correct: "截止日期",
      context: "截止/截至: '截止日期' is the standard form",
    },
    {
      wrong: "报名截止到",
      correct: "报名截至",
      context: "截止/截至: '截至' + time point",
    },
    // 其他常见混淆
    {
      wrong: "既使",
      correct: "即使",
      context: "即使/既使: '即使' (even if) is correct",
    },
    {
      wrong: "必须的",
      correct: "必需的",
      context: "必须/必需: '必需的' (necessary) vs '必须' (must)",
    },
    {
      wrong: "必需去",
      correct: "必须去",
      context: "必须/必需: '必须' (must) for actions",
    },
    {
      wrong: "偶而",
      correct: "偶尔",
      context: "偶尔/偶而: '偶尔' is the standard form",
    },
    {
      wrong: "按装",
      correct: "安装",
      context: "安装/按装: '安装' is the standard form",
    },
    {
      wrong: "发扬广大",
      correct: "发扬光大",
      context: "光大/广大: '发扬光大' is the idiom",
    },
    {
      wrong: "一愁莫展",
      correct: "一筹莫展",
      context: "筹/愁: '一筹莫展' is the idiom",
    },
  ]
}

///|
fn default_consistency_terms() -> Array[ConsistencyTerm] {
  [
    // 品牌/产品名一致性
    {
      canonical: "MoonBit",
      variants: ["Moonbit", "moonbit", "MOONBIT", "Moon bit", "moon bit"],
    },
    {
      canonical: "MoonPost",
      variants: ["Moonpost", "moonpost", "MOONPOST", "Moon post"],
    },
    // 技术术语一致性
    { canonical: "SRT", variants: ["srt", "Srt"] },
    { canonical: "WebVTT", variants: ["webvtt", "WEBVTT", "Webvtt"] },
    { canonical: "ffmpeg", variants: ["FFmpeg", "FFMPEG", "Ffmpeg"] },
    // 中文常见不一致
    { canonical: "账号", variants: ["帐号"] },
    { canonical: "登录", variants: ["登陆"] },
    { canonical: "其他", variants: ["其它"] },
    { canonical: "部分", variants: ["部份"] },
  ]
}

///|
pub fn default_confusion_pairs_list() -> Array[ConfusionPair] {
  default_confusion_pairs()
}

///|
pub fn default_consistency_terms_list() -> Array[ConsistencyTerm] {
  default_consistency_terms()
}

///|
fn check_confusion_pairs(
  issues : Array[QcIssue],
  label : Int?,
  text : Array[String],
  pairs : Array[ConfusionPair],
) -> Unit {
  for line in text {
    for pair in pairs {
      if line.contains(pair.wrong) {
        push_issue(
          issues,
          Warning,
          "C401",
          label,
          "possible confusion: '\{pair.wrong}' should be '\{pair.correct}' (\{pair.context})",
        )
      }
    }
  }
}

///|
fn check_consistency(
  issues : Array[QcIssue],
  cues : Array[@subtitle.Cue],
  terms : Array[ConsistencyTerm],
) -> Unit {
  for term in terms {
    let mut variant_seen : String? = None
    for cue in cues {
      let full_text = cue.text.join(" ")
      for variant in term.variants {
        if full_text.contains(variant) {
          variant_seen = Some(variant)
        }
      }
    }
    match variant_seen {
      Some(v) => {
        let label : Int? = None
        push_issue(
          issues,
          Warning,
          "C402",
          label,
          "inconsistent term: '\{v}' vs canonical '\{term.canonical}'",
        )
      }
      None => ()
    }
  }
}

///|
fn check_user_terms(
  issues : Array[QcIssue],
  label : Int?,
  text : Array[String],
  terms : Array[UserTerm],
) -> Unit {
  for line in text {
    for term in terms {
      if line.contains(term.pattern) {
        let severity = if term.forbidden { Error } else { Warning }
        push_issue(
          issues,
          severity,
          "C403",
          label,
          "\{term.reason}: '\{term.pattern}' → '\{term.preferred}'",
        )
      }
    }
  }
}

///|
pub fn check_terminology_cues(
  cues : Array[@subtitle.Cue],
  confusion_pairs : Array[ConfusionPair],
  consistency_terms : Array[ConsistencyTerm],
  user_terms : Array[UserTerm],
) -> Array[QcIssue] {
  let issues : Array[QcIssue] = []
  // L1: 固定混淆词（逐 cue 检查）
  for cue_index in 0..<cues.length() {
    let cue = cues[cue_index]
    let label = cue_label(cue, cue_index)
    check_confusion_pairs(issues, label, cue.text, confusion_pairs)
    check_user_terms(issues, label, cue.text, user_terms)
  }
  // L2: 文件内一致性（跨 cue 检查）
  check_consistency(issues, cues, consistency_terms)
  issues
}

///|
pub fn fix_confusion_pairs_line(
  line : String,
  pairs : Array[ConfusionPair],
) -> LineCleanResult {
  let actions : Array[CleanAction] = []
  let mut result = line
  for pair in pairs {
    if result.contains(pair.wrong) {
      actions.push({
        code: "C401",
        original: pair.wrong,
        replacement: pair.correct,
      })
      result = result.replace_all(old=pair.wrong, new=pair.correct)
    }
  }
  { text: result, actions }
}
