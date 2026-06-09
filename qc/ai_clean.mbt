///|
pub(all) struct AsrMarker {
  pattern : String
  description : String
} derive(Eq, Debug)

///|
pub(all) struct FillerWord {
  word : String
  description : String
} derive(Eq, Debug)

///|
fn default_asr_markers() -> Array[AsrMarker] {
  [
    { pattern: "[Music]", description: "ASR music marker" },
    { pattern: "[music]", description: "ASR music marker" },
    { pattern: "[Applause]", description: "ASR applause marker" },
    { pattern: "[applause]", description: "ASR applause marker" },
    { pattern: "[Laughter]", description: "ASR laughter marker" },
    { pattern: "[laughter]", description: "ASR laughter marker" },
    { pattern: "(laughs)", description: "ASR laughter marker" },
    { pattern: "(Laugh)", description: "ASR laughter marker" },
    { pattern: "(applause)", description: "ASR applause marker" },
    { pattern: "(music)", description: "ASR music marker" },
    { pattern: "[SILENCE]", description: "ASR silence marker" },
    { pattern: "[silence]", description: "ASR silence marker" },
    { pattern: "(silence)", description: "ASR silence marker" },
    { pattern: "__SILENCE__", description: "ASR silence marker" },
    { pattern: "[NO_SPEECH]", description: "ASR no-speech marker" },
    { pattern: "[inaudible]", description: "ASR inaudible marker" },
    { pattern: "[crosstalk]", description: "ASR crosstalk marker" },
    { pattern: "[CROSSTALK]", description: "ASR crosstalk marker" },
    { pattern: "(unintelligible)", description: "ASR unintelligible marker" },
  ]
}

///|
fn default_filler_words_zh() -> Array[FillerWord] {
  [
    { word: "然后", description: "Chinese filler word" },
    { word: "那个", description: "Chinese filler word" },
    { word: "那个什么", description: "Chinese filler word" },
    { word: "就是", description: "Chinese filler word" },
    { word: "就是说是", description: "Chinese filler word" },
    { word: "对吧", description: "Chinese filler word" },
    { word: "对对对", description: "Chinese filler word" },
    { word: "对的对的", description: "Chinese filler word" },
    { word: "是不是", description: "Chinese filler word" },
    { word: "就是说", description: "Chinese filler word" },
    { word: "然后呢", description: "Chinese filler word" },
    { word: "嗯嗯嗯", description: "Chinese filler word" },
    { word: "对吧对吧", description: "Chinese filler word" },
  ]
}

///|
fn default_filler_words_en() -> Array[FillerWord] {
  [
    { word: "um", description: "English filler word" },
    { word: "uh", description: "English filler word" },
    { word: "like", description: "English filler word" },
    { word: "you know", description: "English filler word" },
    { word: "I mean", description: "English filler word" },
    { word: "sort of", description: "English filler word" },
    { word: "kind of", description: "English filler word" },
    { word: "right right", description: "English filler word" },
    { word: "yeah yeah", description: "English filler word" },
    { word: "so so", description: "English filler word" },
    { word: "actually actually", description: "English filler word" },
  ]
}

///|
fn is_zh_char(ch : Char) -> Bool {
  let code = ch.to_int()
  (code >= 0x4E00 && code <= 0x9FFF) || (code >= 0x3400 && code <= 0x4DBF)
}

///|
fn collect_en_words(text : String) -> Array[String] {
  let words : Array[String] = []
  let mut current = ""
  for ch in text.iter() {
    if ch.is_ascii_alphabetic() || ch is '\'' {
      current = current + ch.to_string()
    } else {
      if current.length() >= 2 {
        words.push(current.to_lower())
      }
      current = ""
    }
  }
  if current.length() >= 2 {
    words.push(current.to_lower())
  }
  words
}

///|
fn detect_repeated_zh(
  line : String,
  issues : Array[QcIssue],
  label : Int?,
) -> Unit {
  // 用滑动窗口检测中文重复词（2~4 字）
  for word_len in [2, 3, 4] {
    let chars = line.iter().filter(fn(ch) { is_zh_char(ch) }).collect()
    if chars.length() < word_len * 2 {
      continue
    }
    let mut i = 0
    while i + word_len * 2 <= chars.length() {
      let mut same = true
      for j in 0..<word_len {
        if chars[i + j] != chars[i + word_len + j] {
          same = false
          break
        }
      }
      if same {
        let word_chars : Array[Char] = []
        for k in i..<(i + word_len) {
          word_chars.push(chars[k])
        }
        let word = String::from_array(word_chars)
        push_issue(issues, Warning, "C601", label, "repeated word: '\{word}'")
        i += word_len * 2
      } else {
        i += 1
      }
    }
  }
}

///|
fn detect_repeated_words(
  issues : Array[QcIssue],
  label : Int?,
  text : Array[String],
  mode : TextStyleMode,
) -> Unit {
  for line in text {
    if mode == TextStyleEn || mode == TextStyleBilingual {
      let en_words = collect_en_words(line)
      for i in 0..<(en_words.length() - 1) {
        if en_words[i] == en_words[i + 1] && en_words[i].length() >= 2 {
          push_issue(
            issues,
            Warning,
            "C601",
            label,
            "repeated word: '\{en_words[i]}'",
          )
        }
      }
    }
    if mode == TextStyleZh || mode == TextStyleBilingual {
      detect_repeated_zh(line, issues, label)
    }
  }
}

///|
fn detect_asr_markers(
  issues : Array[QcIssue],
  label : Int?,
  text : Array[String],
  markers : Array[AsrMarker],
) -> Unit {
  for line in text {
    for marker in markers {
      if line.contains(marker.pattern) {
        push_issue(
          issues,
          Warning,
          "C602",
          label,
          "ASR marker: \{marker.description} '\{marker.pattern}'",
        )
      }
    }
  }
}

///|
fn count_substring(line : String, pattern : String) -> Int {
  let mut count = 0
  let chars = line.to_array()
  let pat = pattern.to_array()
  let pat_len = pat.length()
  if pat_len == 0 || chars.length() < pat_len {
    return 0
  }
  let mut i = 0
  while i <= chars.length() - pat_len {
    let mut match_ = true
    for j in 0..<pat_len {
      if chars[i + j] != pat[j] {
        match_ = false
        break
      }
    }
    if match_ {
      count += 1
      i += pat_len
    } else {
      i += 1
    }
  }
  count
}

///|
fn detect_filler_words(
  issues : Array[QcIssue],
  label : Int?,
  text : Array[String],
  fillers : Array[FillerWord],
) -> Unit {
  for filler in fillers {
    let mut total = 0
    for line in text {
      total += count_substring(line, filler.word)
    }
    if total >= 3 {
      push_issue(
        issues,
        Warning,
        "C603",
        label,
        "filler word '\{filler.word}' appears \{total} times in this cue",
      )
    }
  }
}

///|
pub fn check_ai_clean_cues(
  cues : Array[@subtitle.Cue],
  mode : TextStyleMode,
  asr_markers : Array[AsrMarker],
  filler_words : Array[FillerWord],
) -> Array[QcIssue] {
  let issues : Array[QcIssue] = []
  for cue_index in 0..<cues.length() {
    let cue = cues[cue_index]
    let label = cue_label(cue, cue_index)
    detect_repeated_words(issues, label, cue.text, mode)
    detect_asr_markers(issues, label, cue.text, asr_markers)
    detect_filler_words(issues, label, cue.text, filler_words)
  }
  issues
}

///|
pub fn default_asr_markers_list() -> Array[AsrMarker] {
  default_asr_markers()
}

///|
pub fn default_filler_words_list(mode : TextStyleMode) -> Array[FillerWord] {
  let zh = default_filler_words_zh()
  let en = default_filler_words_en()
  match mode {
    TextStyleZh => zh
    TextStyleEn => en
    TextStyleBilingual => {
      let result : Array[FillerWord] = []
      for item in zh {
        result.push(item)
      }
      for item in en {
        result.push(item)
      }
      result
    }
    TextStyleNone => []
  }
}

///|
fn fix_repeated_zh_line(line : String) -> LineCleanResult {
  let actions : Array[CleanAction] = []
  let mut result = line
  for word_len in [4, 3, 2] {
    let chars = result.iter().filter(fn(ch) { is_zh_char(ch) }).collect()
    if chars.length() < word_len * 2 {
      continue
    }
    let mut i = 0
    while i + word_len * 2 <= chars.length() {
      let mut same = true
      for j in 0..<word_len {
        if chars[i + j] != chars[i + word_len + j] {
          same = false
          break
        }
      }
      if same {
        let word_chars : Array[Char] = []
        for k in i..<(i + word_len) {
          word_chars.push(chars[k])
        }
        let word = String::from_array(word_chars)
        let dup = word + word
        if result.contains(dup) {
          result = result.replace_all(old=dup, new=word)
          actions.push({ code: "C601", original: dup, replacement: word })
        }
        i += word_len * 2
      } else {
        i += 1
      }
    }
  }
  { text: result, actions }
}

///|
fn fix_repeated_en_line(line : String) -> LineCleanResult {
  let actions : Array[CleanAction] = []
  let mut result = line
  // Keep scanning until no more duplicates found
  let mut changed = true
  while changed {
    changed = false
    let words = collect_en_words(result)
    if words.length() < 2 {
      break
    }
    let mut idx = 0
    while idx < words.length() - 1 {
      if words[idx] == words[idx + 1] && words[idx].length() >= 2 {
        let lower_word = words[idx]
        // Scan result to find the case-preserving duplicate pattern
        let mut pos = 0
        while pos < result.length() {
          match result.get_char(pos) {
            Some(c) =>
              if c.is_ascii_alphabetic() {
                let mut w1_end = pos
                let w1_chars : Array[Char] = []
                while w1_end < result.length() {
                  match result.get_char(w1_end) {
                    Some(wc) =>
                      if wc.is_ascii_alphabetic() || wc is '\'' {
                        w1_chars.push(wc)
                        w1_end += 1
                      } else {
                        break
                      }
                    None => break
                  }
                }
                let w1 = String::from_array(w1_chars)
                if w1.to_lower() == lower_word && w1.length() >= 2 {
                  let mut gap_end = w1_end
                  while gap_end < result.length() {
                    match result.get_char(gap_end) {
                      Some(gc) =>
                        if gc.is_whitespace() {
                          gap_end += 1
                        } else {
                          break
                        }
                      None => break
                    }
                  }
                  if gap_end < result.length() {
                    match result.get_char(gap_end) {
                      Some(nc) =>
                        if nc.is_ascii_alphabetic() {
                          let mut w2_end = gap_end
                          let w2_chars : Array[Char] = []
                          while w2_end < result.length() {
                            match result.get_char(w2_end) {
                              Some(wc) =>
                                if wc.is_ascii_alphabetic() || wc is '\'' {
                                  w2_chars.push(wc)
                                  w2_end += 1
                                } else {
                                  break
                                }
                              None => break
                            }
                          }
                          let w2 = String::from_array(w2_chars)
                          if w2.to_lower() == lower_word && w2.length() >= 2 {
                            let dup = w1 + " " + w2
                            actions.push({
                              code: "C601",
                              original: dup,
                              replacement: w1,
                            })
                            result = result.replace_all(old=dup, new=w1)
                            changed = true
                            pos = w2_end
                          } else {
                            pos = w2_end
                          }
                        } else {
                          pos = gap_end
                        }
                      None => pos = result.length()
                    }
                  } else {
                    pos = w1_end
                  }
                } else {
                  pos = w1_end
                }
              } else {
                pos += 1
              }
            None => pos += 1
          }
        }
        // Restart outer scan after any change
        if changed {
          break
        }
        idx += 2
      } else {
        idx += 1
      }
    }
  }
  // Deduplicate actions
  let unique : Array[CleanAction] = []
  for action in actions {
    let mut found = false
    for existing in unique {
      if existing.original == action.original &&
        existing.replacement == action.replacement {
        found = true
      }
    }
    if !found {
      unique.push(action)
    }
  }
  { text: result, actions: unique }
}

///|
pub fn fix_repeated_words_line(
  line : String,
  mode : TextStyleMode,
) -> LineCleanResult {
  let empty_actions : Array[CleanAction] = []
  let mut result = { text: line, actions: empty_actions }
  if mode == TextStyleEn || mode == TextStyleBilingual {
    let en_result = fix_repeated_en_line(result.text)
    result = {
      text: en_result.text,
      actions: result.actions + en_result.actions,
    }
  }
  if mode == TextStyleZh || mode == TextStyleBilingual {
    let zh_result = fix_repeated_zh_line(result.text)
    result = {
      text: zh_result.text,
      actions: result.actions + zh_result.actions,
    }
  }
  result
}

///|
fn collapse_whitespace(text : String) -> String {
  let mut result = ""
  let mut prev_space = false
  for ch in text.iter() {
    if ch.is_whitespace() {
      if !prev_space {
        result = result + " "
        prev_space = true
      }
    } else {
      result = result + ch.to_string()
      prev_space = false
    }
  }
  result
}

///|
pub fn fix_asr_markers_line(
  line : String,
  markers : Array[AsrMarker],
) -> LineCleanResult {
  let actions : Array[CleanAction] = []
  let mut result = line
  for marker in markers {
    if result.contains(marker.pattern) {
      actions.push({ code: "C602", original: marker.pattern, replacement: "" })
      result = result.replace_all(old=marker.pattern, new="")
    }
  }
  let cleaned = collapse_whitespace(result).trim().to_owned()
  { text: cleaned, actions }
}
