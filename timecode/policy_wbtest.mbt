///|
test "extended SMPTE frame rates expose exact ratios and labels" {
  assert_true(FrameRate::parse("47.952") == Some(Fps47952))
  assert_true(FrameRate::parse("48") == Some(Fps48))
  assert_true(FrameRate::parse("60") == Some(Fps60))
  assert_true(FrameRate::parse("72") == Some(Fps72))
  assert_true(FrameRate::parse("96") == Some(Fps96))
  assert_true(FrameRate::parse("100") == Some(Fps100))
  assert_true(FrameRate::parse("119.88") == Some(Fps11988))
  assert_true(FrameRate::parse("120") == Some(Fps120))
  assert_eq(Fps47952.nominal_fps(), 48)
  assert_eq(Fps47952.fps_numerator(), 48000)
  assert_eq(Fps47952.fps_denominator(), 1001)
  assert_eq(Fps11988.nominal_fps(), 120)
  assert_eq(Fps11988.fps_numerator(), 120000)
  assert_eq(Fps11988.fps_denominator(), 1001)
  assert_eq(Fps60.label(), "60fps")
  assert_eq(Fps120.label(), "120fps")
}

///|
test "parse policy can ignore separators for metadata-driven interop" {
  let policy = TimecodeParsePolicy::{ separator_mode: IgnoreForInterop }
  match parse_timecode_with_policy("01:00:00:00", Fps2997Drop, policy) {
    Ok(tc) => {
      assert_eq(tc.to_frames(), 107892)
      assert_eq(tc.format(), "01:00:00;00")
    }
    Err(_) => fail("expected metadata-driven drop-frame parse")
  }
  assert_true(
    parse_timecode_result("01:00:00:00", Fps2997Drop) == Err(InvalidSeparator),
  )
}

///|
test "24-hour wrap mode wraps labels at one day" {
  assert_eq(
    Fps25.frames_to_timecode_with_wrap(25 * 3600 * 24, Wrap24Hour).format(),
    "00:00:00:00",
  )
  assert_eq(
    Fps2997Drop.frames_to_timecode_with_wrap(2589408, Wrap24Hour).format(),
    "00:00:00;00",
  )
  assert_eq(
    Fps25.frames_to_timecode_with_wrap(25 * 3600 * 24, NoWrap).format(),
    "24:00:00:00",
  )
}
