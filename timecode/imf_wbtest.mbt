///|
test "IMF timecode uses metadata drop flag over text separator" {
  let imf = ImfTimecode::{
    rate: 30,
    drop_frame: true,
    start_address: "01:00:00:00",
  }
  match imf.to_timecode() {
    Ok(tc) => {
      assert_true(tc.rate == Fps2997Drop)
      assert_eq(tc.to_frames(), 107892)
      assert_eq(tc.format(), "01:00:00;00")
    }
    Err(_) => fail("expected IMF drop-frame timecode")
  }
}

///|
test "IMF timecode formats start address with external drop flag" {
  let imf = ImfTimecode::from_timecode(Fps5994Drop.frames_to_timecode(215784))
  assert_eq(imf.rate, 60)
  assert_true(imf.drop_frame)
  assert_eq(imf.start_address, "01:00:00:00")
}

///|
test "IMF timecode rejects unsupported drop-frame rates" {
  let imf = ImfTimecode::{
    rate: 24,
    drop_frame: true,
    start_address: "00:00:00:00",
  }
  match imf.to_timecode() {
    Err(InvalidDropFrameRate) => ()
    _ => fail("expected invalid drop-frame IMF rate")
  }
}
