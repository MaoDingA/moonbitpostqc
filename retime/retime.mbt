///|
fn clamp_ms(ms : Int) -> Int {
  if ms < 0 {
    0
  } else {
    ms
  }
}

///|
fn copy_cue_with_times(
  cue : @subtitle.Cue,
  start_ms : Int,
  end_ms : Int,
) -> @subtitle.Cue {
  {
    index: cue.index,
    identifier: cue.identifier,
    start_ms: clamp_ms(start_ms),
    end_ms: clamp_ms(end_ms),
    text: cue.text,
    settings: cue.settings,
  }
}

///|
pub fn offset_cues(
  cues : Array[@subtitle.Cue],
  offset_ms : Int,
) -> Array[@subtitle.Cue] {
  let shifted : Array[@subtitle.Cue] = []
  for cue in cues {
    shifted.push(
      copy_cue_with_times(cue, cue.start_ms + offset_ms, cue.end_ms + offset_ms),
    )
  }
  shifted
}

///|
pub fn convert_fps_cues(
  cues : Array[@subtitle.Cue],
  source_rate : @timecode.FrameRate,
  target_rate : @timecode.FrameRate,
) -> Array[@subtitle.Cue] {
  let converted : Array[@subtitle.Cue] = []
  for cue in cues {
    converted.push(
      copy_cue_with_times(
        cue,
        @timecode.rescale_ms_between_rates(
          cue.start_ms,
          source_rate,
          target_rate,
        ),
        @timecode.rescale_ms_between_rates(cue.end_ms, source_rate, target_rate),
      ),
    )
  }
  converted
}

///|
fn snap_ms_to_frame(ms : Int, rate : @timecode.FrameRate) -> Int {
  rate.frames_to_ms(rate.ms_to_frames(ms))
}

///|
pub fn snap_cues_to_frames(
  cues : Array[@subtitle.Cue],
  rate : @timecode.FrameRate,
) -> Array[@subtitle.Cue] {
  let snapped : Array[@subtitle.Cue] = []
  for cue in cues {
    snapped.push(
      copy_cue_with_times(
        cue,
        snap_ms_to_frame(cue.start_ms, rate),
        snap_ms_to_frame(cue.end_ms, rate),
      ),
    )
  }
  snapped
}
