///|
pub(all) enum SubtitleFormat {
  Srt
  WebVtt
  Ass
  Ssa
} derive(Eq, Debug)

///|
pub(all) struct Cue {
  index : Int?
  identifier : String?
  start_ms : Int
  end_ms : Int
  text : Array[String]
  settings : String
} derive(Eq, Debug)

///|
pub(all) struct SubtitleTrack {
  format : SubtitleFormat
  cues : Array[Cue]
} derive(Eq, Debug)

///|
pub(all) struct ParseError {
  format : SubtitleFormat?
  block : Int
  line : Int
  message : String
} derive(Eq, Debug)

///|
pub fn ParseError::format_message(self : ParseError) -> String {
  "line \{self.line}, block \{self.block}: \{self.message}"
}

///|
pub(all) struct ParseResult {
  track : SubtitleTrack
  errors : Array[ParseError]
} derive(Eq, Debug)

///|
pub fn ParseResult::cues(self : ParseResult) -> Array[Cue] {
  self.track.cues
}

///|
pub fn ParseResult::has_errors(self : ParseResult) -> Bool {
  self.errors.length() > 0
}

///|
pub fn ParseResult::error_count(self : ParseResult) -> Int {
  self.errors.length()
}
