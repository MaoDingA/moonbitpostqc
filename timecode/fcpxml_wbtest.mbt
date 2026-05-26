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

///|
test "FCPXML attrs round trip all supported frame-rate metadata forms" {
  for
    rate in [
      Fps23976,
      Fps24,
      Fps25,
      Fps47952,
      Fps48,
      Fps2997Drop,
      Fps2997NonDrop,
      Fps30,
      Fps50,
      Fps5994Drop,
      Fps5994NonDrop,
      Fps60,
      Fps72,
      Fps96,
      Fps100,
      Fps11988,
      Fps120,
    ] {
    let source = rate.frames_to_timecode(12345)
    let attrs = FcpXmlTimecodeAttrs::from_timecode(source)
    match attrs.to_timecode() {
      Ok(round_trip) => {
        assert_true(round_trip.rate == rate)
        assert_eq(round_trip.to_frames(), source.to_frames())
      }
      Err(_) => fail("expected FCPXML metadata round trip")
    }
  }
}
