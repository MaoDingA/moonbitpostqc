///|
test "duration stores frame spans at an explicit rate" {
  let duration = Duration::from_frames(50, Fps25)
  assert_eq(duration.to_frames(), 50)
  assert_eq(duration.to_ms(), 2000)
  assert_eq(duration.format(), "00:00:02:00")
}

///|
test "duration can be constructed from milliseconds" {
  let duration = Duration::from_ms(1001, Fps2997Drop)
  assert_eq(duration.to_frames(), 30)
  assert_eq(duration.format(), "00:00:01;00")
}

///|
test "negative duration formats with a leading sign" {
  let duration = Duration::from_frames(-50, Fps25)
  assert_eq(duration.to_frames(), -50)
  assert_eq(duration.to_ms(), -2000)
  assert_eq(duration.format(), "-00:00:02:00")
}

///|
test "duration arithmetic requires matching frame rates" {
  let left = Duration::from_frames(48, Fps24)
  let right = Duration::from_frames(12, Fps24)
  match left.add(right) {
    Some(total) => assert_eq(total.to_frames(), 60)
    None => fail("expected matching-rate duration add")
  }
  match left.sub(right) {
    Some(total) => assert_eq(total.to_frames(), 36)
    None => fail("expected matching-rate duration sub")
  }
  assert_true(left.add(Duration::from_frames(12, Fps25)) is None)
  assert_true(left.sub(Duration::from_frames(12, Fps25)) is None)
}

///|
test "duration scaling preserves rate and sign" {
  let duration = Duration::from_frames(24, Fps24).scale(-3)
  assert_eq(duration.to_frames(), -72)
  assert_true(duration.rate == Fps24)
}
