///|
fn sha256_k() -> FixedArray[UInt] {
  FixedArray::from_array([
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U, 0x3956c25bU, 0x59f111f1U,
    0x923f82a4U, 0xab1c5ed5U, 0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
    0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U, 0xe49b69c1U, 0xefbe4786U,
    0x0fc19dc6U, 0x240ca1ccU, 0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U, 0xc6e00bf3U, 0xd5a79147U,
    0x06ca6351U, 0x14292967U, 0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
    0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U, 0xa2bfe8a1U, 0xa81a664bU,
    0xc24b8b70U, 0xc76c51a3U, 0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U, 0x391c0cb3U, 0x4ed8aa4aU,
    0x5b9cca4fU, 0x682e6ff3U, 0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
    0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U,
  ])
}

///|
fn sha256_initial_state() -> FixedArray[UInt] {
  FixedArray::from_array([
    0x6a09e667U, 0xbb67ae85U, 0x3c6ef372U, 0xa54ff53aU, 0x510e527fU, 0x9b05688cU,
    0x1f83d9abU, 0x5be0cd19U,
  ])
}

///|
fn rotr(value : UInt, bits : Int) -> UInt {
  (value >> bits) | (value << (32 - bits))
}

///|
fn big_sigma0(value : UInt) -> UInt {
  rotr(value, 2) ^ rotr(value, 13) ^ rotr(value, 22)
}

///|
fn big_sigma1(value : UInt) -> UInt {
  rotr(value, 6) ^ rotr(value, 11) ^ rotr(value, 25)
}

///|
fn small_sigma0(value : UInt) -> UInt {
  rotr(value, 7) ^ rotr(value, 18) ^ (value >> 3)
}

///|
fn small_sigma1(value : UInt) -> UInt {
  rotr(value, 17) ^ rotr(value, 19) ^ (value >> 10)
}

///|
fn choose(x : UInt, y : UInt, z : UInt) -> UInt {
  (x & y) ^ (x.lnot() & z)
}

///|
fn majority(x : UInt, y : UInt, z : UInt) -> UInt {
  (x & y) ^ (x & z) ^ (y & z)
}

///|
fn uint32_from_be(bytes : Bytes, offset : Int) -> UInt {
  (bytes[offset].to_uint() << 24) |
  (bytes[offset + 1].to_uint() << 16) |
  (bytes[offset + 2].to_uint() << 8) |
  bytes[offset + 3].to_uint()
}

///|
fn compress_sha256_chunk(
  state : FixedArray[UInt],
  chunk : Bytes,
  offset : Int,
) -> Unit {
  let schedule = FixedArray::make(64, 0U)
  for index in 0..<16 {
    schedule[index] = uint32_from_be(chunk, offset + index * 4)
  }
  for index in 16..<64 {
    schedule[index] = small_sigma1(schedule[index - 2]) +
      schedule[index - 7] +
      small_sigma0(schedule[index - 15]) +
      schedule[index - 16]
  }
  let constants = sha256_k()
  let mut a = state[0]
  let mut b = state[1]
  let mut c = state[2]
  let mut d = state[3]
  let mut e = state[4]
  let mut f = state[5]
  let mut g = state[6]
  let mut h = state[7]
  for index in 0..<64 {
    let t1 = h +
      big_sigma1(e) +
      choose(e, f, g) +
      constants[index] +
      schedule[index]
    let t2 = big_sigma0(a) + majority(a, b, c)
    h = g
    g = f
    f = e
    e = d + t1
    d = c
    c = b
    b = a
    a = t1 + t2
  }
  state[0] = state[0] + a
  state[1] = state[1] + b
  state[2] = state[2] + c
  state[3] = state[3] + d
  state[4] = state[4] + e
  state[5] = state[5] + f
  state[6] = state[6] + g
  state[7] = state[7] + h
}

///|
fn hex_char(value : Int) -> Char {
  if value < 10 {
    (0x30 + value).unsafe_to_char()
  } else {
    (0x61 + value - 10).unsafe_to_char()
  }
}

///|
fn append_hex_byte(builder : StringBuilder, byte : Byte) -> Unit {
  let value = byte.to_int()
  builder.write_char(hex_char(value >> 4))
  builder.write_char(hex_char(value & 0x0f))
}

///|
fn append_hex_uint32(builder : StringBuilder, value : UInt) -> Unit {
  append_hex_byte(builder, (value >> 24).to_byte())
  append_hex_byte(builder, (value >> 16).to_byte())
  append_hex_byte(builder, (value >> 8).to_byte())
  append_hex_byte(builder, value.to_byte())
}

///|
struct Sha256State {
  state : FixedArray[UInt]
  buffer : Array[Byte]
  mut length_bytes : UInt64
}

///|
pub fn Sha256State::new() -> Sha256State {
  { state: sha256_initial_state(), buffer: [], length_bytes: 0UL }
}

///|
pub fn Sha256State::update(self : Sha256State, data : BytesView) -> Unit {
  self.length_bytes = self.length_bytes +
    data.length().reinterpret_as_uint().to_uint64()
  for byte in data {
    self.buffer.push(byte)
    if self.buffer.length() == 64 {
      compress_sha256_chunk(self.state, Bytes::from_array(self.buffer), 0)
      self.buffer.clear()
    }
  }
}

///|
pub fn Sha256State::final_hex(self : Sha256State) -> String {
  let final_state = self.state.copy()
  let final_buffer = self.buffer.copy()
  final_buffer.push(b'\x80')
  while final_buffer.length() % 64 != 56 {
    final_buffer.push(b'\x00')
  }
  let bit_len = self.length_bytes * 8UL
  for byte in bit_len.to_be_bytes() {
    final_buffer.push(byte)
  }
  let message = Bytes::from_array(final_buffer)
  for offset = 0; offset < message.length(); {
    compress_sha256_chunk(final_state, message, offset)
    continue offset + 64
  }
  let builder = StringBuilder(size_hint=64)
  for value in final_state {
    append_hex_uint32(builder, value)
  }
  builder.to_string()
}

///|
pub fn sha256_hex(data : BytesView) -> String {
  let state = Sha256State::new()
  state.update(data)
  state.final_hex()
}
