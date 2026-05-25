///|
/// Describes why a SMPTE-style timecode string could not be parsed.
pub(all) enum TimecodeParseError {
  /// The value does not have `HH:MM:SS:FF` or `HH:MM:SS;FF` shape.
  InvalidFormat
  /// One or more numeric fields could not be parsed as integers.
  InvalidNumber
  /// The separator does not match the frame rate's drop-frame mode.
  InvalidSeparator
  /// A numeric field is outside the valid range for the frame rate.
  OutOfRange(String)
  /// A drop-frame label uses one of the skipped frame numbers.
  InvalidDropFrameLabel
} derive(Eq, Debug)
