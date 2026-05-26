///|
/// ST 12 binary groups represented as eight hexadecimal user-bit digits.
pub(all) struct SmpteUserBits {
  value : Int64
} derive(Eq, Debug)

///|
/// Logical ST 12 timecode word data before transport-specific encoding.
pub(all) struct SmpteTimecodeWord {
  timecode : Timecode
  user_bits : SmpteUserBits
  color_frame : Bool
  field_mark : Bool
  binary_group_flags : Int
} derive(Eq, Debug)

///|
fn hex_digit_value(ch : Char) -> Int? {
  if ch >= '0' && ch <= '9' {
    Some(ch.to_int() - '0'.to_int())
  } else if ch >= 'a' && ch <= 'f' {
    Some(ch.to_int() - 'a'.to_int() + 10)
  } else if ch >= 'A' && ch <= 'F' {
    Some(ch.to_int() - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
fn upper_hex_char(value : Int) -> Char {
  if value < 10 {
    ('0'.to_int() + value).unsafe_to_char()
  } else {
    ('A'.to_int() + value - 10).unsafe_to_char()
  }
}

///|
fn user_bit_nibble(bits : SmpteUserBits, index : Int) -> Int {
  let shift = (7 - index) * 4
  ((bits.value >> shift) & 15L).to_int()
}

///|
fn user_bits_from_nibbles(nibbles : Array[Int]) -> SmpteUserBits {
  let mut value = 0L
  for nibble in nibbles {
    value = value * 16L + Int64::from_int(nibble)
  }
  { value, }
}

///|
/// Parses exactly eight hexadecimal digits of ST 12 user bits.
pub fn SmpteUserBits::from_hex(
  raw : String,
) -> Result[SmpteUserBits, TimecodeInteropError] {
  let text = raw.trim().to_owned()
  if text.char_length() != 8 {
    Err(InvalidUserBits)
  } else {
    let mut value = 0L
    let mut valid = true
    for ch in text.iter() {
      match hex_digit_value(ch) {
        Some(digit) => value = value * 16L + Int64::from_int(digit)
        None => valid = false
      }
    }
    if valid {
      Ok({ value, })
    } else {
      Err(InvalidUserBits)
    }
  }
}

///|
/// Formats ST 12 user bits as eight uppercase hexadecimal digits.
pub fn SmpteUserBits::format_hex(self : SmpteUserBits) -> String {
  let builder = StringBuilder::new(size_hint=8)
  for index in 0..<8 {
    builder.write_char(upper_hex_char(user_bit_nibble(self, index)))
  }
  builder.to_string()
}

///|
/// Creates a logical ST 12 word from a timecode label with zeroed user bits.
pub fn SmpteTimecodeWord::from_timecode(
  timecode : Timecode,
) -> SmpteTimecodeWord {
  {
    timecode,
    user_bits: { value: 0L },
    color_frame: false,
    field_mark: false,
    binary_group_flags: 0,
  }
}

///|
/// Extracts the timecode label from a logical ST 12 word.
pub fn SmpteTimecodeWord::to_timecode(
  self : SmpteTimecodeWord,
) -> Result[Timecode, TimecodeInteropError] {
  match parse_timecode_result(self.timecode.format(), self.timecode.rate) {
    Ok(_) => Ok(self.timecode)
    Err(error) => Err(InvalidTimecode(error))
  }
}

///|
fn ltc_byte(low : Int, high : Int) -> Byte {
  ((low & 15) | ((high & 15) << 4)).to_byte()
}

///|
fn ltc_flag_byte(low : Int, high : Int, flag2 : Bool, flag3 : Bool) -> Byte {
  let mut value = low & 7
  if flag2 {
    value = value | 4
  }
  if flag3 {
    value = value | 8
  }
  (value | ((high & 15) << 4)).to_byte()
}

///|
fn validate_word_for_packing(
  word : SmpteTimecodeWord,
) -> Result[Unit, TimecodeInteropError] {
  if word.binary_group_flags < 0 || word.binary_group_flags > 7 {
    Err(InvalidPackedTimecode)
  } else if word.user_bits.value < 0L || word.user_bits.value > 4294967295L {
    Err(InvalidUserBits)
  } else if word.timecode.rate.nominal_fps() > 30 {
    Err(UnsupportedFrameDuration)
  } else if word.timecode.hour < 0 || word.timecode.hour > 23 {
    Err(InvalidPackedTimecode)
  } else {
    match word.to_timecode() {
      Ok(_) => Ok(())
      Err(error) => Err(error)
    }
  }
}

///|
/// Packs the logical word into ten LTC-style bytes.
///
/// This is codeword packing only; it does not generate LTC audio waveform data.
pub fn SmpteTimecodeWord::pack_ltc_bytes(
  self : SmpteTimecodeWord,
) -> Result[Bytes, TimecodeInteropError] {
  match validate_word_for_packing(self) {
    Err(error) => Err(error)
    Ok(_) => {
      let frame_units = self.timecode.frame % 10
      let frame_tens = self.timecode.frame / 10
      let second_units = self.timecode.second % 10
      let second_tens = self.timecode.second / 10
      let minute_units = self.timecode.minute % 10
      let minute_tens = self.timecode.minute / 10
      let hour_units = self.timecode.hour % 10
      let hour_tens = self.timecode.hour / 10
      let bgf0 = (self.binary_group_flags & 1) != 0
      let bgf1 = (self.binary_group_flags & 2) != 0
      let bgf2 = (self.binary_group_flags & 4) != 0
      Ok(
        Bytes::from_array([
          ltc_byte(frame_units, user_bit_nibble(self.user_bits, 0)),
          ltc_flag_byte(
            frame_tens,
            user_bit_nibble(self.user_bits, 1),
            self.timecode.rate.is_drop_frame(),
            self.color_frame,
          ),
          ltc_byte(second_units, user_bit_nibble(self.user_bits, 2)),
          ltc_flag_byte(
            second_tens,
            user_bit_nibble(self.user_bits, 3),
            false,
            bgf0,
          ),
          ltc_byte(minute_units, user_bit_nibble(self.user_bits, 4)),
          ltc_flag_byte(
            minute_tens,
            user_bit_nibble(self.user_bits, 5),
            false,
            bgf1,
          ),
          ltc_byte(hour_units, user_bit_nibble(self.user_bits, 6)),
          ltc_flag_byte(
            hour_tens,
            user_bit_nibble(self.user_bits, 7),
            bgf2,
            self.field_mark,
          ),
          Int::to_byte(252),
          Int::to_byte(191),
        ]),
      )
    }
  }
}

///|
fn packed_byte_at(bytes : Bytes, index : Int) -> Int {
  bytes[index].to_int()
}

///|
fn packed_low_nibble(bytes : Bytes, index : Int) -> Int {
  packed_byte_at(bytes, index) & 15
}

///|
fn packed_high_nibble(bytes : Bytes, index : Int) -> Int {
  (packed_byte_at(bytes, index) >> 4) & 15
}

///|
fn packed_bcd_value(tens : Int, units : Int, max_value : Int) -> Int? {
  if units > 9 || tens > 9 {
    None
  } else {
    let value = tens * 10 + units
    if value <= max_value {
      Some(value)
    } else {
      None
    }
  }
}

///|
/// Unpacks ten LTC-style bytes into a logical ST 12 word.
pub fn SmpteTimecodeWord::unpack_ltc_bytes(
  bytes : Bytes,
  rate : FrameRate,
) -> Result[SmpteTimecodeWord, TimecodeInteropError] {
  if bytes.length() != 10 ||
    packed_byte_at(bytes, 8) != 252 ||
    packed_byte_at(bytes, 9) != 191 {
    Err(InvalidPackedTimecode)
  } else if rate.nominal_fps() > 30 {
    Err(UnsupportedFrameDuration)
  } else {
    let frame_units = packed_low_nibble(bytes, 0)
    let frame_tens = packed_byte_at(bytes, 1) & 3
    let second_units = packed_low_nibble(bytes, 2)
    let second_tens = packed_byte_at(bytes, 3) & 7
    let minute_units = packed_low_nibble(bytes, 4)
    let minute_tens = packed_byte_at(bytes, 5) & 7
    let hour_units = packed_low_nibble(bytes, 6)
    let hour_tens = packed_byte_at(bytes, 7) & 3
    match
      (
        packed_bcd_value(frame_tens, frame_units, rate.nominal_fps() - 1),
        packed_bcd_value(second_tens, second_units, 59),
        packed_bcd_value(minute_tens, minute_units, 59),
        packed_bcd_value(hour_tens, hour_units, 23),
      ) {
      (Some(frame), Some(second), Some(minute), Some(hour)) => {
        let packed_drop = (packed_byte_at(bytes, 1) & 4) != 0
        if packed_drop != rate.is_drop_frame() {
          Err(InvalidPackedTimecode)
        } else {
          let timecode = { hour, minute, second, frame, rate }
          match parse_timecode_result(timecode.format(), rate) {
            Err(_) => Err(InvalidPackedTimecode)
            Ok(_) => {
              let nibbles = [
                packed_high_nibble(bytes, 0),
                packed_high_nibble(bytes, 1),
                packed_high_nibble(bytes, 2),
                packed_high_nibble(bytes, 3),
                packed_high_nibble(bytes, 4),
                packed_high_nibble(bytes, 5),
                packed_high_nibble(bytes, 6),
                packed_high_nibble(bytes, 7),
              ]
              let bgf0 = (packed_byte_at(bytes, 3) & 8) != 0
              let bgf1 = (packed_byte_at(bytes, 5) & 8) != 0
              let bgf2 = (packed_byte_at(bytes, 7) & 4) != 0
              Ok({
                timecode,
                user_bits: user_bits_from_nibbles(nibbles),
                color_frame: (packed_byte_at(bytes, 1) & 8) != 0,
                field_mark: (packed_byte_at(bytes, 7) & 8) != 0,
                binary_group_flags: (if bgf0 { 1 } else { 0 }) +
                (if bgf1 { 2 } else { 0 }) +
                (if bgf2 { 4 } else { 0 }),
              })
            }
          }
        }
      }
      _ => Err(InvalidPackedTimecode)
    }
  }
}
