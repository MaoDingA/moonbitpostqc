///|
test "Apple delivery timecode format parses NTSC drop and non-drop labels" {
  assert_true(
    AppleDeliveryTimecodeFormat::parse("30/1000 1001/dropNTSC") ==
    Some(Fps2997Drop),
  )
  assert_true(
    AppleDeliveryTimecodeFormat::parse("30/1000 1001/nonDrop") ==
    Some(Fps2997NonDrop),
  )
  assert_true(
    AppleDeliveryTimecodeFormat::parse("60/1000 1001/dropNTSC") ==
    Some(Fps5994Drop),
  )
}

///|
test "Apple delivery timecode format parses integer non-drop labels" {
  assert_true(
    AppleDeliveryTimecodeFormat::parse("24/1 1/nonDrop") == Some(Fps24),
  )
  assert_true(
    AppleDeliveryTimecodeFormat::parse("60/1 1/nonDrop") == Some(Fps60),
  )
  assert_true(AppleDeliveryTimecodeFormat::parse("24/1 1/dropNTSC") is None)
}

///|
test "Apple delivery timecode format serializes supported frame rates" {
  assert_true(
    AppleDeliveryTimecodeFormat::format(Fps2997Drop) ==
    Some("30/1000 1001/dropNTSC"),
  )
  assert_true(
    AppleDeliveryTimecodeFormat::format(Fps24) == Some("24/1 1/nonDrop"),
  )
  assert_true(AppleDeliveryTimecodeFormat::format(Fps47952) is None)
}

///|
test "Apple delivery timecode format exposes supported rate capability" {
  assert_true(AppleDeliveryTimecodeFormat::is_supported(Fps2997Drop))
  assert_true(AppleDeliveryTimecodeFormat::is_supported(Fps5994NonDrop))
  assert_false(AppleDeliveryTimecodeFormat::is_supported(Fps47952))
  assert_eq(AppleDeliveryTimecodeFormat::supported_rates().length(), 9)
}
