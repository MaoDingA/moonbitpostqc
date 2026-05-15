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
