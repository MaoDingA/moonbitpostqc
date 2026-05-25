///|
test "25fps timecode converts to frame count and back" {
  let tc = parse_timecode("01:00:00:00", Fps25)
  match tc {
    Some(tc) => {
      assert_eq(tc.to_frames(), 90000)
      assert_eq(Fps25.frames_to_timecode(90000).format(), "01:00:00:00")
    }
    None => fail("expected valid timecode")
  }
}

///|
test "semicolon selects drop-frame parsing" {
  let tc = parse_timecode("01:00:00;00", Fps2997Drop)
  match tc {
    Some(tc) => {
      assert_eq(tc.to_frames(), 107892)
      assert_eq(Fps2997Drop.frames_to_timecode(107892).format(), "01:00:00;00")
    }
    None => fail("expected valid drop-frame timecode")
  }
}

///|
test "23.976 to 25 conversion preserves real time" {
  let source = Timecode::{
    hour: 0,
    minute: 1,
    second: 0,
    frame: 0,
    rate: Fps23976,
  }
  let converted = convert_timecode(source, Fps25)
  assert_eq(converted.to_frames(), 1502)
  assert_true(converted.rate == Fps25)
}

///|
test "23.976 hour conversion avoids integer overflow" {
  let source = Timecode::{
    hour: 1,
    minute: 0,
    second: 0,
    frame: 0,
    rate: Fps23976,
  }
  assert_eq(Fps23976.frames_to_ms(source.to_frames()), 3603600)
  let converted = convert_timecode(source, Fps25)
  assert_eq(converted.to_frames(), 90090)
  assert_eq(converted.format(), "01:00:03:15")
}

///|
test "fps retime helper avoids integer overflow on long cues" {
  assert_eq(rescale_ms_between_rates(3600000, Fps23976, Fps25), 3452547)
}

///|
test "invalid frame number is rejected" {
  assert_true(parse_timecode("00:00:01:25", Fps25) is None)
  assert_true(parse_timecode("00:00:01;02", Fps2997NonDrop) is None)
}

///|
test "24fps one second maps to 24 frames" {
  match parse_timecode("00:00:01:00", Fps24) {
    Some(tc) => assert_eq(tc.to_frames(), 24)
    None => fail("expected 24fps timecode")
  }
}

///|
test "negative frame input formats as zero timecode" {
  assert_eq(Fps25.frames_to_timecode(-10).format(), "00:00:00:00")
}

///|
test "drop-frame minute labels skip dropped frame numbers" {
  assert_true(parse_timecode("00:01:00;00", Fps2997Drop) is None)
  assert_true(parse_timecode("00:01:00;02", Fps2997Drop) is Some(_))
  assert_true(parse_timecode("00:10:00;00", Fps2997Drop) is Some(_))
}

///|
test "59.94 drop-frame doubles the 29.97 one-hour frame count" {
  match parse_timecode("01:00:00;00", Fps5994Drop) {
    Some(tc) => assert_eq(tc.to_frames(), 215784)
    None => fail("expected 59.94 DF timecode")
  }
}

///|
test "frame duration helpers round common rates" {
  assert_eq(Fps25.frames_to_ms(25), 1000)
  assert_eq(Fps30.ms_to_frames(1000), 30)
}

///|
test "frame rates expose exact fps ratios" {
  assert_eq(Fps23976.nominal_fps(), 24)
  assert_eq(Fps23976.fps_numerator(), 24000)
  assert_eq(Fps23976.fps_denominator(), 1001)
  assert_eq(Fps2997Drop.nominal_fps(), 30)
  assert_eq(Fps2997Drop.fps_numerator(), 30000)
  assert_eq(Fps2997Drop.fps_denominator(), 1001)
  assert_eq(Fps5994Drop.fps_numerator(), 60000)
  assert_eq(Fps5994Drop.fps_denominator(), 1001)
  assert_eq(Fps25.fps_numerator(), 25)
  assert_eq(Fps25.fps_denominator(), 1)
}

///|
test "convert timecode uses direct frame-rate ratio" {
  let source = Fps23976.frames_to_timecode(24000)
  let converted = convert_timecode(source, Fps25)
  assert_eq(converted.to_frames(), 25025)
  assert_eq(converted.format(), "00:16:41:00")
  assert_eq(convert_timecode(converted, Fps23976).to_frames(), 24000)
}

///|
test "drop-frame round trips sampled frame counts through one day" {
  let samples = [
    0, 1, 1797, 1798, 1799, 1800, 17982, 17983, 107892, 215784, 2589408,
  ]
  for frames in samples {
    let tc = Fps2997Drop.frames_to_timecode(frames)
    assert_eq(tc.to_frames(), frames)
  }
}

///|
test "all supported frame rates round trip representative frame counts" {
  for frames in [0, 1, 24, 1001, 17982, 107892] {
    assert_eq(Fps23976.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps24.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps25.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps2997Drop.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps2997NonDrop.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps30.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps50.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps5994Drop.frames_to_timecode(frames).to_frames(), frames)
    assert_eq(Fps5994NonDrop.frames_to_timecode(frames).to_frames(), frames)
  }
}
