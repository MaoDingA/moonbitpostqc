///|
test "FCPXML attrs convert rational start to timecode" {
  let attrs = FcpXmlTimecodeAttrs::{
    frame_duration: { numerator: 1001L, denominator: 24000L },
    tc_start: { numerator: 3600L, denominator: 1L },
    tc_format: NDF,
  }
  match attrs.to_timecode() {
    Ok(tc) => {
      assert_true(tc.rate == Fps23976)
      assert_eq(tc.to_frames(), 86314)
      assert_eq(tc.format(), "00:59:56:10")
    }
    Err(_) => fail("expected FCPXML timecode")
  }
}

///|
test "FCPXML attrs use tcFormat to choose drop-frame rates" {
  let attrs = FcpXmlTimecodeAttrs::{
    frame_duration: { numerator: 1001L, denominator: 30000L },
    tc_start: { numerator: 3600L, denominator: 1L },
    tc_format: DF,
  }
  match attrs.to_timecode() {
    Ok(tc) => {
      assert_true(tc.rate == Fps2997Drop)
      assert_eq(tc.to_frames(), 107892)
      assert_eq(tc.format(), "01:00:00;00")
    }
    Err(_) => fail("expected drop-frame FCPXML timecode")
  }
}

///|
test "FCPXML conversion rejects invalid drop-frame combinations" {
  let attrs = FcpXmlTimecodeAttrs::{
    frame_duration: { numerator: 1L, denominator: 25L },
    tc_start: { numerator: 0L, denominator: 1L },
    tc_format: DF,
  }
  match attrs.to_timecode() {
    Err(InvalidDropFrameRate) => ()
    _ => fail("expected invalid drop-frame rate")
  }
}

///|
test "FCPXML attrs can be created from timecode labels" {
  let tc = Fps2997Drop.frames_to_timecode(107892)
  let attrs = FcpXmlTimecodeAttrs::from_timecode(tc)
  assert_true(attrs.tc_format == DF)
  assert_eq(attrs.frame_duration.format(), "1001/30000s")
  assert_eq(attrs.tc_start.format(), "8999991/2500s")
}
