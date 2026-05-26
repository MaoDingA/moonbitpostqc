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

///|
/// Describes why metadata-level timecode interop could not be converted.
pub(all) enum TimecodeInteropError {
  /// The metadata describes a frame duration this package cannot map to a
  /// supported `FrameRate`.
  UnsupportedFrameDuration
  /// Drop-frame mode was requested for a rate that cannot use drop-frame
  /// labels.
  InvalidDropFrameRate
  /// A metadata field contains an invalid or unsupported timecode label.
  InvalidTimecode(TimecodeParseError)
  /// ST 12 user bits are not exactly eight hexadecimal digits.
  InvalidUserBits
  /// Packed timecode bytes are malformed or fail structural validation.
  InvalidPackedTimecode
  /// An EDL event line is malformed or describes an invalid range.
  InvalidEdlEvent
} derive(Eq, Debug)
