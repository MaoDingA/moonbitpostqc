///|
/// FCPXML timecode format flag.
pub(all) enum FcpXmlTcFormat {
  DF
  NDF
} derive(Eq, Debug)

///|
/// Minimal FCPXML timecode attributes needed to map timeline start time.
pub(all) struct FcpXmlTimecodeAttrs {
  frame_duration : RationalSeconds
  tc_start : RationalSeconds
  tc_format : FcpXmlTcFormat
} derive(Eq, Debug)

///|
fn normalized_rational_seconds(value : RationalSeconds) -> RationalSeconds {
  match RationalSeconds::new(value.numerator, value.denominator) {
    Some(normalized) => normalized
    None => { numerator: 0L, denominator: 1L }
  }
}

///|
fn frame_duration_is(
  value : RationalSeconds,
  numerator : Int64,
  denominator : Int64,
) -> Bool {
  normalized_rational_seconds(value) == { numerator, denominator }
}

///|
fn frame_rate_from_fcpxml_duration(
  frame_duration : RationalSeconds,
  format : FcpXmlTcFormat,
) -> Result[FrameRate, TimecodeInteropError] {
  if frame_duration_is(frame_duration, 1001L, 24000L) {
    match format {
      NDF => Ok(Fps23976)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 24L) {
    match format {
      NDF => Ok(Fps24)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 25L) {
    match format {
      NDF => Ok(Fps25)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1001L, 48000L) {
    match format {
      NDF => Ok(Fps47952)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 48L) {
    match format {
      NDF => Ok(Fps48)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1001L, 30000L) {
    match format {
      DF => Ok(Fps2997Drop)
      NDF => Ok(Fps2997NonDrop)
    }
  } else if frame_duration_is(frame_duration, 1L, 30L) {
    match format {
      NDF => Ok(Fps30)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 50L) {
    match format {
      NDF => Ok(Fps50)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1001L, 60000L) {
    match format {
      DF => Ok(Fps5994Drop)
      NDF => Ok(Fps5994NonDrop)
    }
  } else if frame_duration_is(frame_duration, 1L, 60L) {
    match format {
      NDF => Ok(Fps60)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 72L) {
    match format {
      NDF => Ok(Fps72)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 96L) {
    match format {
      NDF => Ok(Fps96)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 100L) {
    match format {
      NDF => Ok(Fps100)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1001L, 120000L) {
    match format {
      NDF => Ok(Fps11988)
      DF => Err(InvalidDropFrameRate)
    }
  } else if frame_duration_is(frame_duration, 1L, 120L) {
    match format {
      NDF => Ok(Fps120)
      DF => Err(InvalidDropFrameRate)
    }
  } else {
    Err(UnsupportedFrameDuration)
  }
}

///|
/// Converts FCPXML timecode attributes to a `Timecode` label.
pub fn FcpXmlTimecodeAttrs::to_timecode(
  self : FcpXmlTimecodeAttrs,
) -> Result[Timecode, TimecodeInteropError] {
  match frame_rate_from_fcpxml_duration(self.frame_duration, self.tc_format) {
    Ok(rate) => Ok(rate.frames_to_timecode(self.tc_start.to_frames(rate)))
    Err(error) => Err(error)
  }
}

///|
/// Creates FCPXML-style attributes from a `Timecode` label.
pub fn FcpXmlTimecodeAttrs::from_timecode(
  timecode : Timecode,
) -> FcpXmlTimecodeAttrs {
  {
    frame_duration: RationalSeconds::from_frames(1, timecode.rate),
    tc_start: RationalSeconds::from_frames(timecode.to_frames(), timecode.rate),
    tc_format: if timecode.rate.is_drop_frame() {
      DF
    } else {
      NDF
    },
  }
}
