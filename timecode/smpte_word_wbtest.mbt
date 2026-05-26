///|
test "SMPTE user bits parse and format eight hex digits" {
  match SmpteUserBits::from_hex("1234abcd") {
    Ok(bits) => {
      assert_eq(bits.value, 305441741L)
      assert_eq(bits.format_hex(), "1234ABCD")
    }
    Err(_) => fail("expected valid SMPTE user bits")
  }
  match SmpteUserBits::from_hex("123456789") {
    Err(InvalidUserBits) => ()
    _ => fail("expected invalid user bits length")
  }
  match SmpteUserBits::from_hex("1234ZZZZ") {
    Err(InvalidUserBits) => ()
    _ => fail("expected invalid user bits digits")
  }
}

///|
test "SMPTE timecode word packs BCD address flags and user bits" {
  let tc = Timecode::{
    hour: 1,
    minute: 23,
    second: 45,
    frame: 12,
    rate: Fps2997Drop,
  }
  let user_bits = match SmpteUserBits::from_hex("1234ABCD") {
    Ok(bits) => bits
    Err(_) => fail("expected valid user bits")
  }
  let word = SmpteTimecodeWord::{
    timecode: tc,
    user_bits,
    color_frame: true,
    field_mark: true,
    binary_group_flags: 5,
  }
  match word.pack_ltc_bytes() {
    Ok(bytes) => {
      assert_eq(bytes.length(), 10)
      assert_eq(bytes[0].to_int(), 18)
      assert_eq(bytes[1].to_int(), 45)
      assert_eq(bytes[2].to_int(), 53)
      assert_eq(bytes[3].to_int(), 76)
      assert_eq(bytes[4].to_int(), 163)
      assert_eq(bytes[5].to_int(), 178)
      assert_eq(bytes[6].to_int(), 193)
      assert_eq(bytes[7].to_int(), 220)
      assert_eq(bytes[8].to_int(), 252)
      assert_eq(bytes[9].to_int(), 191)
    }
    Err(_) => fail("expected packed LTC bytes")
  }
}

///|
test "SMPTE timecode word unpacks LTC bytes and validates sync" {
  let bytes = Bytes::from_array([
    Int::to_byte(18),
    Int::to_byte(45),
    Int::to_byte(53),
    Int::to_byte(76),
    Int::to_byte(163),
    Int::to_byte(178),
    Int::to_byte(193),
    Int::to_byte(220),
    Int::to_byte(252),
    Int::to_byte(191),
  ])
  match SmpteTimecodeWord::unpack_ltc_bytes(bytes, Fps2997Drop) {
    Ok(word) => {
      assert_eq(word.timecode.format(), "01:23:45;12")
      assert_eq(word.user_bits.format_hex(), "1234ABCD")
      assert_true(word.color_frame)
      assert_true(word.field_mark)
      assert_eq(word.binary_group_flags, 5)
    }
    Err(_) => fail("expected unpacked LTC word")
  }

  let invalid_sync = Bytes::from_array([
    Int::to_byte(18),
    Int::to_byte(45),
    Int::to_byte(53),
    Int::to_byte(76),
    Int::to_byte(163),
    Int::to_byte(178),
    Int::to_byte(193),
    Int::to_byte(220),
    Int::to_byte(0),
    Int::to_byte(0),
  ])
  match SmpteTimecodeWord::unpack_ltc_bytes(invalid_sync, Fps2997Drop) {
    Err(InvalidPackedTimecode) => ()
    _ => fail("expected sync validation failure")
  }
}

///|
test "SMPTE packed LTC bytes reject unsupported high-rate and over-24h labels" {
  let high_rate = SmpteTimecodeWord::from_timecode({
    hour: 0,
    minute: 0,
    second: 0,
    frame: 40,
    rate: Fps60,
  })
  match high_rate.pack_ltc_bytes() {
    Err(UnsupportedFrameDuration) => ()
    _ => fail("expected high-rate packed LTC rejection")
  }

  let over_24h = SmpteTimecodeWord::from_timecode({
    hour: 24,
    minute: 0,
    second: 0,
    frame: 0,
    rate: Fps25,
  })
  match over_24h.pack_ltc_bytes() {
    Err(InvalidPackedTimecode) => ()
    _ => fail("expected over-24h packed LTC rejection")
  }
}
