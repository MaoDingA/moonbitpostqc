///|
test "public API parses frame-rate aliases and formats stable labels" {
  assert_true(@timecode.FrameRate::parse("23.98") == Some(Fps23976))
  assert_true(@timecode.FrameRate::parse("29.97df") == Some(Fps2997Drop))
  assert_true(@timecode.FrameRate::parse("29.97 drop") == Some(Fps2997Drop))
  assert_true(@timecode.FrameRate::parse("59.94ndf") == Some(Fps5994NonDrop))
  assert_true(@timecode.FrameRate::parse("bad") is None)
  assert_eq(@timecode.Fps23976.label(), "23.976fps")
  assert_eq(@timecode.Fps2997Drop.label(), "29.97df")
}

///|
test "public API reports parse errors without breaking option parser" {
  match @timecode.parse_timecode_result("00:00:01:25", Fps25) {
    Err(OutOfRange(field)) => assert_eq(field, "frame")
    _ => fail("expected frame range parse error")
  }
  match @timecode.parse_timecode_result("00:01:00;00", Fps2997Drop) {
    Err(InvalidDropFrameLabel) => ()
    _ => fail("expected drop-frame label parse error")
  }
  match @timecode.parse_timecode_result("00:00:01;00", Fps25) {
    Err(InvalidSeparator) => ()
    _ => fail("expected separator parse error")
  }
  assert_true(@timecode.parse_timecode("00:00:01:25", Fps25) is None)
  match @timecode.parse_timecode_result("00:00:aa:00", Fps25) {
    Err(InvalidNumber) => ()
    _ => fail("expected invalid number parse error")
  }
  match @timecode.parse_timecode_result("00:00:00", Fps25) {
    Err(InvalidFormat) => ()
    _ => fail("expected invalid format parse error")
  }
}

///|
test "public API converts and compares timecode labels through frame counts" {
  let source = @timecode.Fps23976.frames_to_timecode(24000)
  let converted = @timecode.convert_timecode(source, Fps25)
  assert_eq(converted.format(), "00:16:41:00")
  assert_true(
    @timecode.convert_timecode(converted, Fps23976).to_frames() == 24000,
  )

  let start = @timecode.Fps2997Drop.frames_to_timecode(1797)
  let end = start.add_frames(5)
  assert_eq(end.format(), "00:01:00;04")
  assert_true(start.frame_distance(end) == Some(5))
}

///|
test "public API models durations and ranges at one explicit frame rate" {
  let start = @timecode.Fps25.frames_to_timecode(100)
  let end = @timecode.Fps25.frames_to_timecode(160)
  match @timecode.TimecodeRange::new(start, end) {
    Some(range) => {
      match range.duration() {
        Some(duration) => {
          assert_eq(duration.to_frames(), 60)
          assert_eq(duration.format(), "00:00:02:10")
        }
        None => fail("expected same-rate duration")
      }
      assert_true(
        range.contains(@timecode.Fps25.frames_to_timecode(120)) == Some(true),
      )
      assert_true(
        range.contains(@timecode.Fps25.frames_to_timecode(160)) == Some(false),
      )
      match range.shift(@timecode.Duration::from_frames(25, Fps25)) {
        Some(shifted) => {
          assert_eq(shifted.start.to_frames(), 125)
          assert_eq(shifted.end.to_frames(), 185)
        }
        None => fail("expected same-rate shift")
      }
      match
        @timecode.TimecodeRange::new(
          @timecode.Fps25.frames_to_timecode(150),
          @timecode.Fps25.frames_to_timecode(200),
        ) {
        Some(other) => assert_true(range.overlaps(other) == Some(true))
        None => fail("expected comparison range")
      }
    }
    None => fail("expected valid timecode range")
  }
  assert_true(
    @timecode.TimecodeRange::new(start, @timecode.Fps24.frames_to_timecode(160))
    is None,
  )
}
