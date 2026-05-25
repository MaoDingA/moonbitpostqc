///|
fn scale_rounded(value : Int, numerator : Int, denominator : Int) -> Int {
  if value < 0 {
    -scale_rounded(-value, numerator, denominator)
  } else {
    let scaled = Int64::from_int(value) * Int64::from_int(numerator)
    let divisor = Int64::from_int(denominator)
    ((scaled + divisor / Int64::from_int(2)) / divisor).to_int()
  }
}

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}
