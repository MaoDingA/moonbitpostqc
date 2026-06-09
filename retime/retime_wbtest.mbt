///|
fn cue(start_ms : Int, end_ms : Int) -> @subtitle.Cue {
  {
    index: Some(1),
    identifier: None,
    start_ms,
    end_ms,
    text: ["Hello"],
    settings: "",
  }
}

///|
test "offset shifts cue timings without changing text" {
  let shifted = offset_cues([cue(1000, 2500)], 1200)
  assert_eq(shifted[0].start_ms, 2200)
  assert_eq(shifted[0].end_ms, 3700)
  assert_eq(shifted[0].text[0], "Hello")
}

///|
test "negative offset clamps at zero" {
  let shifted = offset_cues([cue(300, 1200)], -500)
  assert_eq(shifted[0].start_ms, 0)
  assert_eq(shifted[0].end_ms, 700)
}

///|
test "fps conversion applies the source-to-target speed change" {
  let converted = convert_fps_cues([cue(1000, 2000)], Fps23976, Fps25)
  assert_eq(converted[0].start_ms, 959)
  assert_eq(converted[0].end_ms, 1918)
}

///|
test "snap to frames rounds cue edges" {
  let snapped = snap_cues_to_frames([cue(1123, 2037)], Fps25)
  assert_eq(snapped[0].start_ms, 1120)
  assert_eq(snapped[0].end_ms, 2040)
}

///|
test "zero offset preserves cue timing" {
  let shifted = offset_cues([cue(1000, 2000)], 0)
  assert_eq(shifted[0].start_ms, 1000)
  assert_eq(shifted[0].end_ms, 2000)
}

///|
test "snap to 30fps uses nearest frame" {
  let snapped = snap_cues_to_frames([cue(1017, 1984)], Fps30)
  assert_eq(snapped[0].start_ms, 1033)
  assert_eq(snapped[0].end_ms, 2000)
}
