///|
pub(all) enum SubtitleFormat {
  Srt
  WebVtt
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
