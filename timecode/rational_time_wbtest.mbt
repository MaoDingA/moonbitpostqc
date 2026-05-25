///|
test "rational seconds parse and format common media times" {
  match RationalSeconds::parse("1001/24000s") {
    Some(value) => {
      assert_eq(value.numerator, 1001L)
      assert_eq(value.denominator, 24000L)
      assert_eq(value.format(), "1001/24000s")
    }
    None => fail("expected rational seconds")
  }
  match RationalSeconds::parse("3600s") {
    Some(value) => {
      assert_eq(value.numerator, 3600L)
      assert_eq(value.denominator, 1L)
      assert_eq(value.format(), "3600s")
    }
    None => fail("expected integer seconds")
  }
  assert_true(RationalSeconds::parse("1001/0s") is None)
  assert_true(RationalSeconds::parse("bad") is None)
}

///|
test "rational seconds convert to and from frame counts" {
  match RationalSeconds::parse("1001/24000s") {
    Some(frame_duration) => assert_eq(frame_duration.to_frames(Fps23976), 1)
    None => fail("expected frame duration")
  }
  match RationalSeconds::parse("3600s") {
    Some(hour) => assert_eq(hour.to_frames(Fps25), 90000)
    None => fail("expected hour duration")
  }
  assert_eq(RationalSeconds::from_frames(1, Fps23976).format(), "1001/24000s")
  assert_eq(RationalSeconds::from_frames(90000, Fps25).format(), "3600s")
}
