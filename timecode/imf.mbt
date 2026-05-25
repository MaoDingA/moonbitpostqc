///|
/// Minimal IMF Composition Playlist timecode fields.
pub(all) struct ImfTimecode {
  rate : Int
  drop_frame : Bool
  start_address : String
} derive(Eq, Debug)

///|
fn imf_rate_to_frame_rate(
  rate : Int,
  drop_frame : Bool,
) -> Result[FrameRate, TimecodeInteropError] {
  match (rate, drop_frame) {
    (24, false) => Ok(Fps24)
    (25, false) => Ok(Fps25)
    (30, false) => Ok(Fps30)
    (30, true) => Ok(Fps2997Drop)
    (48, false) => Ok(Fps48)
    (50, false) => Ok(Fps50)
    (60, false) => Ok(Fps60)
    (60, true) => Ok(Fps5994Drop)
    (72, false) => Ok(Fps72)
    (96, false) => Ok(Fps96)
    (100, false) => Ok(Fps100)
    (120, false) => Ok(Fps120)
    (_, true) => Err(InvalidDropFrameRate)
    _ => Err(UnsupportedFrameDuration)
  }
}

///|
/// Converts IMF timecode metadata to a `Timecode` label.
pub fn ImfTimecode::to_timecode(
  self : ImfTimecode,
) -> Result[Timecode, TimecodeInteropError] {
  match imf_rate_to_frame_rate(self.rate, self.drop_frame) {
    Ok(rate) =>
      match
        parse_timecode_with_policy(self.start_address, rate, {
          separator_mode: IgnoreForInterop,
        }) {
        Ok(tc) => Ok(tc)
        Err(error) => Err(InvalidTimecode(error))
      }
    Err(error) => Err(error)
  }
}

///|
/// Creates minimal IMF timecode fields from a `Timecode` label.
pub fn ImfTimecode::from_timecode(timecode : Timecode) -> ImfTimecode {
  {
    rate: timecode.rate.nominal_fps(),
    drop_frame: timecode.rate.is_drop_frame(),
    start_address: timecode.format().replace(old=";", new=":"),
  }
}
