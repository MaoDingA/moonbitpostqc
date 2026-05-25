///|
test "timecode frame arithmetic round trips across drop-frame boundary" {
  let start = Fps2997Drop.frames_to_timecode(1797)
  let advanced = start.add_frames(5)
  assert_eq(advanced.to_frames(), 1802)
  assert_eq(advanced.format(), "00:01:00;04")
  assert_true(advanced.sub_frames(5) == start)
}

///|
test "timecode subtraction saturates at zero" {
  let start = Fps25.frames_to_timecode(10)
  assert_eq(start.sub_frames(20).format(), "00:00:00:00")
}

///|
test "timecode duration arithmetic requires matching rates" {
  let start = Fps25.frames_to_timecode(100)
  match start.add_duration(Duration::from_frames(25, Fps25)) {
    Some(tc) => assert_eq(tc.to_frames(), 125)
    None => fail("expected matching-rate add_duration")
  }
  match start.sub_duration(Duration::from_frames(25, Fps25)) {
    Some(tc) => assert_eq(tc.to_frames(), 75)
    None => fail("expected matching-rate sub_duration")
  }
  assert_true(start.add_duration(Duration::from_frames(25, Fps24)) is None)
  assert_true(start.sub_duration(Duration::from_frames(25, Fps24)) is None)
}

///|
test "timecode distance and ordering are explicit about frame rates" {
  let left = Fps24.frames_to_timecode(100)
  let right = Fps24.frames_to_timecode(125)
  assert_true(left.frame_distance(right) == Some(25))
  assert_true(right.frame_distance(left) == Some(-25))
  assert_true(left.is_before(right) == Some(true))
  assert_true(right.is_after(left) == Some(true))
  assert_true(left.is_after(right) == Some(false))
  assert_true(left.frame_distance(Fps25.frames_to_timecode(125)) is None)
  assert_true(left.is_before(Fps25.frames_to_timecode(125)) is None)
}
