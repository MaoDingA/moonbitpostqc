///|
/// Controls how text separators are validated during timecode parsing.
pub(all) enum TimecodeSeparatorMode {
  /// Require `:` for non-drop-frame and `;` for drop-frame rates.
  StrictByRate
  /// Allow metadata to define drop-frame mode even when the visible label uses
  /// a generic `:` separator.
  IgnoreForInterop
  /// Accept `:` for drop-frame metadata, but do not accept `;` for
  /// non-drop-frame metadata.
  InferFromSeparator
} derive(Eq, Debug)

///|
/// Controls whether frame-to-label conversion wraps at 24 hours.
pub(all) enum TimecodeWrapMode {
  /// Preserve labels beyond 24 hours.
  NoWrap
  /// Wrap labels into the 00:00:00:00 through 23:59:59:FF range.
  Wrap24Hour
} derive(Eq, Debug)

///|
/// Options for parsing timecode labels from interop formats.
pub(all) struct TimecodeParsePolicy {
  separator_mode : TimecodeSeparatorMode
} derive(Eq, Debug)
