///|
fn cue_text(text : Array[String]) -> String {
  text.join("\n")
}

///|
pub fn write_srt(track : SubtitleTrack) -> String {
  let blocks : Array[String] = []
  for index in 0..<track.cues.length() {
    let cue = track.cues[index]
    let number = match cue.index {
      Some(value) => value
      None => index + 1
    }
    let timing = "\{format_srt_timestamp(cue.start_ms)} --> \{format_srt_timestamp(cue.end_ms)}"
    let body = if cue.text.length() > 0 {
      "\{number}\n\{timing}\n\{cue_text(cue.text)}"
    } else {
      "\{number}\n\{timing}"
    }
    blocks.push(body)
  }
  if blocks.length() == 0 {
    ""
  } else {
    blocks.join("\n\n") + "\n"
  }
}

///|
pub fn write_webvtt(track : SubtitleTrack) -> String {
  let blocks : Array[String] = []
  for cue in track.cues {
    let timing = if cue.settings.is_empty() {
      "\{format_vtt_timestamp(cue.start_ms)} --> \{format_vtt_timestamp(cue.end_ms)}"
    } else {
      "\{format_vtt_timestamp(cue.start_ms)} --> \{format_vtt_timestamp(cue.end_ms)} \{cue.settings}"
    }
    let body = if cue.text.length() > 0 {
      "\{timing}\n\{cue_text(cue.text)}"
    } else {
      timing
    }
    match cue.identifier {
      Some(identifier) => blocks.push("\{identifier}\n\{body}")
      None => blocks.push(body)
    }
  }
  if blocks.length() == 0 {
    "WEBVTT\n"
  } else {
    "WEBVTT\n\n" + blocks.join("\n\n") + "\n"
  }
}
