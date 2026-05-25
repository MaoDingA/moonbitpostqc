///|
/// Namespace for Apple delivery-package timecode format strings.
pub(all) struct AppleDeliveryTimecodeFormat {} derive(Eq, Debug)

///|
fn normalize_apple_delivery_format(raw : String) -> String {
  raw.trim().to_owned().to_lower()
}

///|
/// Parses an Apple delivery-package timecode format string.
pub fn AppleDeliveryTimecodeFormat::parse(raw : String) -> FrameRate? {
  match normalize_apple_delivery_format(raw) {
    "24/1 1/nondrop" => Some(Fps24)
    "25/1 1/nondrop" => Some(Fps25)
    "30/1000 1001/dropntsc" => Some(Fps2997Drop)
    "30/1000 1001/nondrop" => Some(Fps2997NonDrop)
    "30/1 1/nondrop" => Some(Fps30)
    "50/1 1/nondrop" => Some(Fps50)
    "60/1000 1001/dropntsc" => Some(Fps5994Drop)
    "60/1000 1001/nondrop" => Some(Fps5994NonDrop)
    "60/1 1/nondrop" => Some(Fps60)
    _ => None
  }
}

///|
/// Formats supported frame rates as Apple delivery-package timecode strings.
pub fn AppleDeliveryTimecodeFormat::format(rate : FrameRate) -> String? {
  match rate {
    Fps24 => Some("24/1 1/nonDrop")
    Fps25 => Some("25/1 1/nonDrop")
    Fps2997Drop => Some("30/1000 1001/dropNTSC")
    Fps2997NonDrop => Some("30/1000 1001/nonDrop")
    Fps30 => Some("30/1 1/nonDrop")
    Fps50 => Some("50/1 1/nonDrop")
    Fps5994Drop => Some("60/1000 1001/dropNTSC")
    Fps5994NonDrop => Some("60/1000 1001/nonDrop")
    Fps60 => Some("60/1 1/nonDrop")
    _ => None
  }
}
