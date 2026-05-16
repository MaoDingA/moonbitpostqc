///|
fn visible_before(chars : Array[Char], index : Int) -> Char? {
  let mut cursor = index - 1
  while cursor >= 0 {
    let ch = chars[cursor]
    if is_visible_char(ch) {
      return Some(ch)
    }
    cursor -= 1
  }
  None
}

///|
fn visible_after(chars : Array[Char], index : Int) -> Char? {
  let mut cursor = index + 1
  while cursor < chars.length() {
    let ch = chars[cursor]
    if is_visible_char(ch) {
      return Some(ch)
    }
    cursor += 1
  }
  None
}

///|
fn context_prefers_zh(chars : Array[Char], index : Int) -> Bool {
  match (visible_before(chars, index), visible_after(chars, index)) {
    (Some(prev), Some(next)) => is_cjk_char(prev) || is_cjk_char(next)
    (Some(prev), None) => is_cjk_char(prev)
    (None, Some(next)) => is_cjk_char(next)
    (None, None) => false
  }
}

///|
fn ascii_to_fullwidth(ch : Char) -> Char {
  match ch {
    ',' => '，'
    '.' => '。'
    '?' => '？'
    '!' => '！'
    ':' => '：'
    ';' => '；'
    '(' => '（'
    ')' => '）'
    _ => ch
  }
}

///|
fn fullwidth_to_ascii(ch : Char) -> Char {
  match ch {
    '，' | '、' => ','
    '。' => '.'
    '？' => '?'
    '！' => '!'
    '：' => ':'
    '；' => ';'
    '（' => '('
    '）' => ')'
    _ => ch
  }
}

///|
fn normalize_punctuation_char(
  ch : Char,
  chars : Array[Char],
  index : Int,
  mode : TextStyleMode,
) -> Char {
  match mode {
    TextStyleZh => ascii_to_fullwidth(ch)
    TextStyleEn => fullwidth_to_ascii(ch)
    TextStyleBilingual =>
      if context_prefers_zh(chars, index) {
        ascii_to_fullwidth(ch)
      } else {
        fullwidth_to_ascii(ch)
      }
    TextStyleNone => ch
  }
}

///|
pub fn normalize_punctuation(text : String, mode~ : TextStyleMode) -> String {
  let chars = text.to_array()
  let normalized : Array[Char] = []
  for index in 0..<chars.length() {
    normalized.push(
      normalize_punctuation_char(chars[index], chars, index, mode),
    )
  }
  String::from_array(normalized)
}
