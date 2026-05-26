///|
/// Exact IMF edit-rate ratio.
pub(all) struct ImfEditRate {
  numerator : Int
  denominator : Int
} derive(Eq, Debug)

///|
/// IMF Composition Playlist-style timecode fields with exact edit-rate data.
pub(all) struct ImfCompositionTimecode {
  edit_rate : ImfEditRate
  timecode_rate : Int
  drop_frame : Bool
  start_address : String
} derive(Eq, Debug)

///|
/// Creates an exact IMF edit rate from a supported frame rate.
pub fn ImfEditRate::from_frame_rate(rate : FrameRate) -> ImfEditRate {
  { numerator: rate.fps_numerator(), denominator: rate.fps_denominator() }
}

///|
/// Converts this exact edit rate and drop-frame flag to a supported frame rate.
pub fn ImfEditRate::to_frame_rate(
  self : ImfEditRate,
  drop_frame : Bool,
) -> Result[FrameRate, TimecodeInteropError] {
  match (self.numerator, self.denominator, drop_frame) {
    (24000, 1001, false) => Ok(Fps23976)
    (24, 1, false) => Ok(Fps24)
    (25, 1, false) => Ok(Fps25)
    (48000, 1001, false) => Ok(Fps47952)
    (48, 1, false) => Ok(Fps48)
    (30000, 1001, true) => Ok(Fps2997Drop)
    (30000, 1001, false) => Ok(Fps2997NonDrop)
    (30, 1, false) => Ok(Fps30)
    (50, 1, false) => Ok(Fps50)
    (60000, 1001, true) => Ok(Fps5994Drop)
    (60000, 1001, false) => Ok(Fps5994NonDrop)
    (60, 1, false) => Ok(Fps60)
    (72, 1, false) => Ok(Fps72)
    (96, 1, false) => Ok(Fps96)
    (100, 1, false) => Ok(Fps100)
    (120000, 1001, false) => Ok(Fps11988)
    (120, 1, false) => Ok(Fps120)
    (_, _, true) => Err(InvalidDropFrameRate)
    _ => Err(UnsupportedFrameDuration)
  }
}

///|
fn imf_timecode_rate_matches(rate : FrameRate, timecode_rate : Int) -> Bool {
  rate.nominal_fps() == timecode_rate
}

///|
/// Converts IMF composition timecode metadata to a `Timecode` label.
pub fn ImfCompositionTimecode::to_timecode(
  self : ImfCompositionTimecode,
) -> Result[Timecode, TimecodeInteropError] {
  match self.edit_rate.to_frame_rate(self.drop_frame) {
    Ok(rate) =>
      if !imf_timecode_rate_matches(rate, self.timecode_rate) {
        Err(UnsupportedFrameDuration)
      } else {
        match
          parse_timecode_with_policy(self.start_address, rate, {
            separator_mode: IgnoreForInterop,
          }) {
          Ok(tc) => Ok(tc)
          Err(error) => Err(InvalidTimecode(error))
        }
      }
    Err(error) => Err(error)
  }
}

///|
/// Creates exact IMF composition timecode fields from a `Timecode` label.
pub fn ImfCompositionTimecode::from_timecode(
  timecode : Timecode,
) -> ImfCompositionTimecode {
  {
    edit_rate: ImfEditRate::from_frame_rate(timecode.rate),
    timecode_rate: timecode.rate.nominal_fps(),
    drop_frame: timecode.rate.is_drop_frame(),
    start_address: timecode.format().replace(old=";", new=":"),
  }
}
