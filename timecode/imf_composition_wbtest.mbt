///|
test "IMF composition timecode preserves fractional non-drop edit rates" {
  let source_2997 = Fps2997NonDrop.frames_to_timecode(30000)
  let imf_2997 = ImfCompositionTimecode::from_timecode(source_2997)
  assert_eq(imf_2997.edit_rate.numerator, 30000)
  assert_eq(imf_2997.edit_rate.denominator, 1001)
  assert_eq(imf_2997.timecode_rate, 30)
  assert_false(imf_2997.drop_frame)
  match imf_2997.to_timecode() {
    Ok(round_trip) => {
      assert_true(round_trip.rate == Fps2997NonDrop)
      assert_eq(round_trip.to_frames(), source_2997.to_frames())
    }
    Err(_) => fail("expected 29.97 non-drop IMF round trip")
  }

  let source_5994 = Fps5994NonDrop.frames_to_timecode(60000)
  let imf_5994 = ImfCompositionTimecode::from_timecode(source_5994)
  assert_eq(imf_5994.edit_rate.numerator, 60000)
  assert_eq(imf_5994.edit_rate.denominator, 1001)
  assert_eq(imf_5994.timecode_rate, 60)
  assert_false(imf_5994.drop_frame)
  match imf_5994.to_timecode() {
    Ok(round_trip) => {
      assert_true(round_trip.rate == Fps5994NonDrop)
      assert_eq(round_trip.to_frames(), source_5994.to_frames())
    }
    Err(_) => fail("expected 59.94 non-drop IMF round trip")
  }
}

///|
test "IMF composition timecode uses drop flag and rejects invalid drop rates" {
  let drop_source = Fps2997Drop.frames_to_timecode(107892)
  let drop_imf = ImfCompositionTimecode::from_timecode(drop_source)
  assert_true(drop_imf.drop_frame)
  assert_eq(drop_imf.start_address, "01:00:00:00")
  match drop_imf.to_timecode() {
    Ok(round_trip) => {
      assert_true(round_trip.rate == Fps2997Drop)
      assert_eq(round_trip.to_frames(), 107892)
    }
    Err(_) => fail("expected drop-frame IMF composition timecode")
  }

  let invalid = ImfCompositionTimecode::{
    edit_rate: { numerator: 25, denominator: 1 },
    timecode_rate: 25,
    drop_frame: true,
    start_address: "00:00:00:00",
  }
  match invalid.to_timecode() {
    Err(InvalidDropFrameRate) => ()
    _ => fail("expected invalid drop-frame IMF composition rate")
  }
}
