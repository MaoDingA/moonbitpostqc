///|
pub(all) enum TextStyleMode {
  TextStyleNone
  TextStyleBilingual
  TextStyleZh
  TextStyleEn
} derive(Eq, Debug)

///|
pub(all) struct DictionaryTerm {
  suspicious : String
  replacement : String
  reason : String
} derive(Eq, Debug)

///|
pub(all) struct TextStyleProfile {
  mode : TextStyleMode
  max_unbroken_chars : Int
  warn_single_char_line : Bool
  dictionary_terms : Array[DictionaryTerm]
} derive(Eq, Debug)

///|
pub fn no_text_style_profile() -> TextStyleProfile {
  {
    mode: TextStyleNone,
    max_unbroken_chars: 0,
    warn_single_char_line: false,
    dictionary_terms: [],
  }
}

///|
fn default_dictionary_terms() -> Array[DictionaryTerm] {
  [
    {
      suspicious: "登陆",
      replacement: "登录",
      reason: "common Chinese terminology",
    },
    {
      suspicious: "帐号",
      replacement: "账号",
      reason: "common Chinese terminology",
    },
    {
      suspicious: "Moonpost",
      replacement: "MoonPost",
      reason: "brand capitalization",
    },
  ]
}

///|
pub fn bilingual_text_style_profile() -> TextStyleProfile {
  {
    mode: TextStyleBilingual,
    max_unbroken_chars: 32,
    warn_single_char_line: true,
    dictionary_terms: default_dictionary_terms(),
  }
}

///|
pub fn zh_text_style_profile() -> TextStyleProfile {
  {
    mode: TextStyleZh,
    max_unbroken_chars: 28,
    warn_single_char_line: true,
    dictionary_terms: default_dictionary_terms(),
  }
}

///|
pub fn en_text_style_profile() -> TextStyleProfile {
  {
    mode: TextStyleEn,
    max_unbroken_chars: 32,
    warn_single_char_line: false,
    dictionary_terms: default_dictionary_terms(),
  }
}

///|
pub fn text_style_profile_by_name(name : String) -> TextStyleProfile? {
  match name {
    "none" => Some(no_text_style_profile())
    "bilingual" => Some(bilingual_text_style_profile())
    "zh" | "chinese" => Some(zh_text_style_profile())
    "en" | "english" => Some(en_text_style_profile())
    _ => None
  }
}

///|
fn is_cjk_char(ch : Char) -> Bool {
  let code = ch.to_int()
  (code >= 0x3400 && code <= 0x4DBF) ||
  (code >= 0x4E00 && code <= 0x9FFF) ||
  (code >= 0xF900 && code <= 0xFAFF)
}

///|
fn is_ascii_letter_or_digit(ch : Char) -> Bool {
  ch.is_ascii_alphabetic() || ch.is_ascii_digit()
}

///|
fn is_visible_char(ch : Char) -> Bool {
  !ch.is_whitespace()
}

///|
fn is_break_char(ch : Char) -> Bool {
  ch.is_whitespace() ||
  ch
  is (','
  | '.'
  | '?'
  | '!'
  | ':'
  | ';'
  | '('
  | ')'
  | '['
  | ']'
  | '"'
  | '\''
  | '，'
  | '。'
  | '？'
  | '！'
  | '：'
  | '；'
  | '（'
  | '）'
  | '【'
  | '】'
  | '“'
  | '”'
  | '‘'
  | '’'
  | '、')
}

///|
fn is_ascii_sentence_punctuation(ch : Char) -> Bool {
  ch is (',' | '.' | '?' | '!' | ':' | ';')
}

///|
fn is_fullwidth_sentence_punctuation(ch : Char) -> Bool {
  ch is ('，' | '。' | '？' | '！' | '：' | '；' | '、')
}

///|
fn count_cjk(line : String) -> Int {
  let mut count = 0
  for ch in line.iter() {
    if is_cjk_char(ch) {
      count += 1
    }
  }
  count
}

///|
fn count_ascii_words(line : String) -> Int {
  let mut count = 0
  for ch in line.iter() {
    if is_ascii_letter_or_digit(ch) {
      count += 1
    }
  }
  count
}

///|
fn has_ascii_punctuation(line : String) -> Bool {
  for ch in line.iter() {
    if is_ascii_sentence_punctuation(ch) {
      return true
    }
  }
  false
}

///|
fn has_fullwidth_punctuation(line : String) -> Bool {
  for ch in line.iter() {
    if is_fullwidth_sentence_punctuation(ch) {
      return true
    }
  }
  false
}

///|
fn should_warn_mixed_punctuation(
  line : String,
  profile : TextStyleProfile,
) -> Bool {
  let cjk = count_cjk(line)
  let ascii = count_ascii_words(line)
  match profile.mode {
    TextStyleNone => false
    TextStyleZh => cjk > 0 && has_ascii_punctuation(line)
    TextStyleEn => ascii > 0 && has_fullwidth_punctuation(line)
    TextStyleBilingual =>
      (cjk > ascii && has_ascii_punctuation(line)) ||
      (ascii > cjk && has_fullwidth_punctuation(line))
  }
}

///|
fn has_repeated_punctuation(line : String) -> Bool {
  let mut previous : Char? = None
  for ch in line.iter() {
    if is_ascii_sentence_punctuation(ch) ||
      is_fullwidth_sentence_punctuation(ch) {
      match previous {
        Some(prev) if prev == ch => return true
        _ => previous = Some(ch)
      }
    } else {
      previous = None
    }
  }
  false
}

///|
fn has_suspicious_pairs(line : String) -> Bool {
  (line.contains("（") && line.contains(")")) ||
  (line.contains("(") && line.contains("）")) ||
  (line.contains("“") && line.contains("\"")) ||
  (line.contains("\"") && line.contains("”")) ||
  (line.contains("‘") && line.contains("'")) ||
  (line.contains("'") && line.contains("’"))
}

///|
fn longest_unbroken_block(line : String) -> Int {
  let mut longest = 0
  let mut current = 0
  for ch in line.iter() {
    if is_break_char(ch) {
      if current > longest {
        longest = current
      }
      current = 0
    } else if is_visible_char(ch) {
      current += 1
    }
  }
  if current > longest {
    current
  } else {
    longest
  }
}

///|
fn is_isolated_single_cjk_line(line : String) -> Bool {
  let trimmed = line.trim().to_owned()
  trimmed.char_length() == 1 &&
  (match trimmed.get_char(0) {
    Some(ch) => is_cjk_char(ch)
    None => false
  })
}

///|
fn check_dictionary_terms(
  issues : Array[QcIssue],
  label : Int?,
  line : String,
  terms : Array[DictionaryTerm],
) -> Unit {
  for term in terms {
    if line.contains(term.suspicious) {
      push_issue(
        issues,
        Warning,
        "W520",
        label,
        "'\{term.suspicious}' should be '\{term.replacement}' (\{term.reason})",
      )
    }
  }
}

///|
fn check_text_style_line(
  issues : Array[QcIssue],
  label : Int?,
  line : String,
  line_index : Int,
  profile : TextStyleProfile,
) -> Unit {
  if should_warn_mixed_punctuation(line, profile) {
    push_issue(
      issues,
      Warning,
      "W501",
      label,
      "line \{line_index + 1}: mixed punctuation style",
    )
  }
  if has_repeated_punctuation(line) {
    push_issue(
      issues,
      Warning,
      "W502",
      label,
      "line \{line_index + 1}: repeated punctuation",
    )
  }
  if has_suspicious_pairs(line) {
    push_issue(
      issues,
      Warning,
      "W503",
      label,
      "line \{line_index + 1}: suspicious paired punctuation",
    )
  }
  let longest = longest_unbroken_block(line)
  if profile.max_unbroken_chars > 0 && longest > profile.max_unbroken_chars {
    push_issue(
      issues,
      Warning,
      "W510",
      label,
      "line \{line_index + 1}: unbroken text block \{longest} chars exceeds max \{profile.max_unbroken_chars}",
    )
  }
  if profile.warn_single_char_line && is_isolated_single_cjk_line(line) {
    push_issue(
      issues,
      Warning,
      "W511",
      label,
      "line \{line_index + 1}: isolated single-character line",
    )
  }
  check_dictionary_terms(issues, label, line, profile.dictionary_terms)
}

///|
pub fn check_text_style_cues(
  cues : Array[@subtitle.Cue],
  profile : TextStyleProfile,
) -> Array[QcIssue] {
  let issues : Array[QcIssue] = []
  if profile.mode == TextStyleNone {
    return issues
  }
  for cue_index in 0..<cues.length() {
    let cue = cues[cue_index]
    let label = cue_label(cue, cue_index)
    for line_index in 0..<cue.text.length() {
      check_text_style_line(
        issues,
        label,
        cue.text[line_index],
        line_index,
        profile,
      )
    }
  }
  issues
}
