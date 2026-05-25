///|
/// A rational number of seconds used by media container metadata.
pub(all) struct RationalSeconds {
  numerator : Int64
  denominator : Int64
} derive(Eq, Debug)

///|
fn gcd_int64(left : Int64, right : Int64) -> Int64 {
  let a = left.abs()
  let b = right.abs()
  if b == 0L {
    a
  } else {
    gcd_int64(b, a % b)
  }
}

///|
fn parse_int64(raw : String) -> Int64? {
  Some(@string.parse_int64(raw)) catch {
    _ => None
  }
}

///|
fn scale_rounded_int64_to_int(
  value : Int64,
  numerator : Int64,
  denominator : Int64,
) -> Int {
  if value < 0L {
    -scale_rounded_int64_to_int(-value, numerator, denominator)
  } else {
    ((value * numerator + denominator / 2L) / denominator).to_int()
  }
}

///|
/// Creates a normalized rational second value.
pub fn RationalSeconds::new(
  numerator : Int64,
  denominator : Int64,
) -> RationalSeconds? {
  if denominator == 0L {
    None
  } else {
    let sign = if denominator < 0L { -1L } else { 1L }
    let numerator = numerator * sign
    let denominator = denominator.abs()
    let divisor = gcd_int64(numerator, denominator)
    if divisor == 0L {
      Some({ numerator: 0L, denominator: 1L })
    } else {
      Some({
        numerator: numerator / divisor,
        denominator: denominator / divisor,
      })
    }
  }
}

///|
/// Parses `Ns` or `N/Ds` rational seconds syntax.
pub fn RationalSeconds::parse(raw : String) -> RationalSeconds? {
  let trimmed = raw.trim().to_owned()
  let body = match trimmed.strip_suffix("s") {
    Some(value) => value.to_owned()
    None => return None
  }
  match split_to_strings(body, "/") {
    [numerator, denominator] =>
      match (parse_int64(numerator), parse_int64(denominator)) {
        (Some(numerator), Some(denominator)) =>
          RationalSeconds::new(numerator, denominator)
        _ => None
      }
    [seconds] =>
      match parse_int64(seconds) {
        Some(seconds) => RationalSeconds::new(seconds, 1L)
        None => None
      }
    _ => None
  }
}

///|
/// Formats this rational value as `Ns` or `N/Ds`.
pub fn RationalSeconds::format(self : RationalSeconds) -> String {
  if self.denominator == 1L {
    "\{self.numerator}s"
  } else {
    "\{self.numerator}/\{self.denominator}s"
  }
}

///|
/// Converts rational seconds to a frame count using nearest-integer rounding.
pub fn RationalSeconds::to_frames(
  self : RationalSeconds,
  rate : FrameRate,
) -> Int {
  scale_rounded_int64_to_int(
    self.numerator,
    Int64::from_int(rate.fps_numerator()),
    self.denominator * Int64::from_int(rate.fps_denominator()),
  )
}

///|
/// Creates rational seconds from a frame count at an exact frame rate.
pub fn RationalSeconds::from_frames(
  frames : Int,
  rate : FrameRate,
) -> RationalSeconds {
  match
    RationalSeconds::new(
      Int64::from_int(frames) * Int64::from_int(rate.fps_denominator()),
      Int64::from_int(rate.fps_numerator()),
    ) {
    Some(value) => value
    None => { numerator: 0L, denominator: 1L }
  }
}
