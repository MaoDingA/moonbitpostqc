///|
fn explain_code(code : String) -> Array[String] {
  match code {
    // 时间轴硬错误
    "E101" =>
      [
        "E101 [Error] Cue overlap", "", "The current cue's end time overlaps the next cue's start time.",
        "This is a hard error in all delivery profiles.", "", "Fix: Adjust the end time of the current cue or the start time of",
        "the next cue so there is no overlap.",
      ]
    "E102" =>
      [
        "E102 [Error] End time not after start time", "", "The cue's end time is at or before its start time, making the",
        "duration zero or negative.", "", "Fix: Ensure end time > start time for every cue.",
      ]
    "E201" =>
      [
        "E201 [Error] Empty cue text", "", "The cue contains no visible text (only whitespace or empty lines).",
        "", "Fix: Add text to the cue or remove the empty cue.",
      ]
    // 时长和行数
    "W201" =>
      [
        "W201 [Warning] Duration below minimum", "", "The cue duration is shorter than the profile's minimum. Short cues",
        "may not be readable, especially on small screens.", "", "Fix: Extend the duration or merge with an adjacent cue.",
      ]
    "W202" =>
      [
        "W202 [Warning] Duration above maximum", "", "The cue duration exceeds the profile's maximum. Long-duration cues",
        "may present too much text at once.", "", "Fix: Split the cue into multiple shorter cues.",
      ]
    "W203" =>
      [
        "W203 [Warning] Line exceeds CPL limit", "", "A single line of text exceeds the Characters Per Line (CPL) limit.",
        "Long lines may wrap unpredictably or be cut off on screen.", "", "Fix: Break the line into multiple lines or shorten the text.",
      ]
    "W204" =>
      [
        "W204 [Warning] Too many lines", "", "The cue has more text lines than the profile allows.",
        "", "Fix: Reduce the number of lines or split into multiple cues.",
      ]
    "W205" =>
      [
        "W205 [Warning] Leading or trailing whitespace", "", "A text line begins or ends with a space or tab. This may cause",
        "inconsistent rendering or spacing on different players.", "", "Fix: Remove the leading/trailing whitespace from the line.",
      ]
    "W206" =>
      [
        "W206 [Warning] Consecutive blank lines", "", "The cue text contains two or more blank lines in a row, which",
        "usually indicates a formatting error.", "", "Fix: Remove the extra blank line(s).",
      ]
    "W207" =>
      [
        "W207 [Warning] Whitespace-only line", "", "A line inside the cue contains only spaces or tabs (not truly empty",
        "but visually blank).", "", "Fix: Remove the whitespace-only line or replace with actual content.",
      ]
    "W208" =>
      [
        "W208 [Warning] Line length imbalance", "", "The longest visible line is much longer than the shortest visible",
        "line in the same cue, creating visual imbalance on screen.", "", "Fix: Rebalance the text so the two lines are closer in length.",
      ]
    // 阅读速度
    "W310" =>
      [
        "W310 [Warning] Reading speed exceeds CPS limit", "", "Characters Per Second (CPS) exceeds the profile's maximum. The",
        "subtitle may be too fast to read comfortably.", "", "Fix: Shorten the text or extend the cue duration.",
      ]
    "W311" =>
      [
        "W311 [Warning] Words Per Second exceeds WPS limit", "", "Words Per Second (WPS) for Latin-script text exceeds the profile's",
        "maximum. This is the English-reading-speed counterpart to CPS.", "", "Fix: Shorten the text or extend the cue duration.",
      ]
    // 帧网格和间隔
    "W401" =>
      [
        "W401 [Warning] Frame grid misalignment", "", "Cue start or end time does not align to the frame grid at the",
        "configured frame rate. This matters for broadcast and cinema where", "subtitles must be frame-accurate.",
        "", "Fix: Snap cue times to the nearest frame boundary.",
      ]
    "W402" =>
      [
        "W402 [Warning] Gap below minimum frame interval", "", "The gap between consecutive cues is less than the minimum number",
        "of frames required by the profile.", "", "Fix: Increase the gap between cues or merge overlapping cues.",
      ]
    // 文本风格
    "W501" =>
      [
        "W501 [Warning] Mixed punctuation style", "", "Chinese and English punctuation are mixed in the same line. For",
        "example, a Chinese sentence uses an English comma.", "", "Fix: Use consistent punctuation style for the line's language.",
      ]
    "W502" =>
      [
        "W502 [Warning] Repeated punctuation", "", "The same punctuation mark appears consecutively, e.g. '!!' or '，，'.",
        "", "Fix: Remove the duplicate punctuation.",
      ]
    "W503" =>
      [
        "W503 [Warning] Suspicious paired punctuation", "", "Mixed opening and closing bracket/quote styles detected, e.g.",
        "mixing full-width opening with half-width closing brackets.", "", "Fix: Use matching pairs for all brackets and quotes.",
      ]
    "W510" =>
      [
        "W510 [Warning] Unbroken text block too long", "", "A continuous run of characters (no spaces or punctuation breaks)",
        "exceeds the profile's limit. This often indicates missing breaks.", "",
        "Fix: Add spaces, punctuation, or line breaks as appropriate.",
      ]
    "W511" =>
      [
        "W511 [Warning] Isolated single-character line", "", "A line contains only a single CJK character, which is usually",
        "a fragment or error.", "", "Fix: Merge with the adjacent line or verify the content.",
      ]
    "W520" =>
      [
        "W520 [Warning] Terminology suggestion", "", "A term in the built-in dictionary was found with a suspicious",
        "spelling. For example, '登陆' might be '登录'.", "", "Fix: Verify and use the correct term.",
      ]
    // SRT 源文件风险
    "W601" =>
      [
        "W601 [Warning] SRT contains font/color tags", "", "The SRT file contains HTML-like font or color tags. These may not",
        "be preserved when converting to other formats.", "", "Fix: Remove inline styling or move it to a container-level format.",
      ]
    "W602" =>
      [
        "W602 [Warning] SRT contains ASS/SSA style overrides", "", "The SRT file contains ASS/SSA-style override tags (e.g. {\\an8}).",
        "These may not render correctly in all players.", "", "Fix: Use standard SRT formatting or convert to ASS/SSA.",
      ]
    "W603" =>
      [
        "W603 [Warning] SRT cue contains WebVTT settings", "", "The SRT cue's timestamp line includes WebVTT-style position/align",
        "settings that are not valid in SRT.", "", "Fix: Remove WebVTT settings or convert to WebVTT format.",
      ]
    "W701" =>
      [
        "W701 [Warning] First subtitle too close to program start", "", "In DCP source SRT profiles, the first subtitle appears very close",
        "to the program start, which may cause display issues during", "theatrical playback.",
        "", "Fix: Delay the first cue or confirm this is intentional.",
      ]
    // 术语 C 系列
    "C401" =>
      [
        "C401 [Warning] Confusion pair detected", "", "A commonly confused word pair was detected. For example:",
        "  的/地/得: '认真的做' → '认真地做'", "  在/再:   '再一起' → '在一起'",
        "  做/作:   '做贡献' → '作贡献'", "", "Fix: Use the correct form based on grammatical context.",
      ]
    "C402" =>
      [
        "C402 [Warning] Term inconsistency", "", "The same concept appears with different spellings across cues in",
        "the file. For example, 'MoonPost' and 'moonpost', or '账号' and", "'帐号'.",
        "", "Fix: Use the canonical form consistently throughout the file.",
      ]
    "C403" =>
      [
        "C403 [Warning/Error] User term rule triggered", "", "A user-defined term rule was triggered. These are custom rules",
        "loaded from a terminology file. Forbidden terms produce Error;", "preferred terms produce Warning.",
        "", "Fix: Replace with the preferred term or update the rule.",
      ]
    // AI 清洗 C6 系列
    "C601" =>
      [
        "C601 [Warning] Repeated word", "", "The same word appears consecutively, which is common in AI/ASR",
        "transcripts. Examples: '然后然后', '就是就是', 'like like'.", "",
        "Fix: Remove the duplicate word.",
      ]
    "C602" =>
      [
        "C602 [Warning] ASR marker detected", "", "An ASR (Automatic Speech Recognition) marker was found, such as",
        "'[Music]', '[Applause]', or '(laughs)'. These are artifacts from", "speech-to-text tools and usually should be removed.",
        "", "Fix: Remove the ASR marker or replace with a description.",
      ]
    "C603" =>
      [
        "C603 [Warning] Filler word overuse", "", "A filler word appears 3 or more times in a single cue. Common",
        "fillers: '然后', '那个', '就是', 'um', 'like', 'you know'.", "", "Fix: Reduce filler words for cleaner subtitles.",
      ]
    // Delivery D 系列
    "D101" =>
      [
        "D101 [Error] Missing main video file", "", "The delivery package does not contain a main video file (.mov,",
        ".mp4, or .mxf).", "", "Fix: Add the video file to the delivery directory.",
      ]
    "D102" =>
      [
        "D102 [Error] Missing subtitle files", "", "The delivery package does not contain any subtitle files (.srt",
        "or .vtt).", "", "Fix: Add subtitle files to the delivery directory.",
      ]
    "D202" =>
      [
        "D202 [Warning] Missing metadata file", "", "The delivery package does not contain a metadata JSON file.",
        "", "Fix: Add a metadata.json file with episode information.",
      ]
    "D401" =>
      [
        "D401 [Error] Checksum file missing", "", "The delivery package does not contain a checksum file (checksum.txt,",
        "checksums.txt, or SHA256SUMS).", "", "Fix: Generate a checksum file with SHA-256 hashes for all assets.",
      ]
    "D402" =>
      [
        "D402 [Error] Checksum file unreadable", "", "The checksum file exists but could not be parsed.",
        "", "Fix: Ensure the file uses standard sha256sum format:", "  <64-hex-chars>  filename",
      ]
    "D403" =>
      [
        "D403 [Error] Checksum mismatch", "", "A file's actual SHA-256 hash does not match the checksum file.",
        "The file may be corrupted or modified.", "", "Fix: Re-generate the checksum file or re-transfer the file.",
      ]
    "D404" =>
      [
        "D404 [Error] Checksum covers path outside directory", "", "A checksum entry points to a file outside the delivery directory.",
        "Relative path traversal is not allowed.", "", "Fix: Ensure all checksum paths are relative to the delivery directory.",
      ]
    _ =>
      [
        "Unknown diagnostic code: \{code}",
        "",
        "Valid code ranges:",
        "  E1xx   Timecode hard errors",
        "  E2xx   Text hard errors",
        "  W2xx   Duration, line, and whitespace warnings",
        "  W3xx   Reading speed warnings",
        "  W4xx   Frame grid and gap warnings",
        "  W5xx   Text style warnings",
        "  W6xx   SRT source file risk warnings",
        "  W7xx   DCP source warnings",
        "  C4xx   Terminology warnings",
        "  C6xx   AI transcript clean warnings",
        "  D1xx   Delivery asset errors",
        "  D2xx   Delivery metadata warnings",
        "  D4xx   Delivery checksum errors",
      ]
  }
}

///|
fn run_explain(code : String) -> Int {
  let lines = explain_code(code)
  print_lines(lines)
  0
}
