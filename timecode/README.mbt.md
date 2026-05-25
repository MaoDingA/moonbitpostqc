# MoonPost Timecode

`phenom8010/moonpost/timecode` is a small SMPTE-style timecode foundation for
MoonBit media tooling. It keeps three concepts separate:

- `Timecode`: a position label such as `01:00:00;00`
- `Duration`: a frame span at one explicit frame rate
- `TimecodeRange`: a half-open `[start, end)` interval on one frame-rate
  timeline

The package supports common production frame rates, drop-frame labels for
29.97/59.94, exact numerator/denominator conversion, explicit same-rate
arithmetic, 24-hour wrapping policy, and small metadata adapters for FCPXML,
IMF, and Apple delivery-package timecode fields.

## Import

Add the module and import the package:

```text
moon add phenom8010/moonpost
```

```json
{
  "import": [
    "phenom8010/moonpost/timecode"
  ]
}
```

## Parse And Format

Non-drop-frame labels use `HH:MM:SS:FF`; drop-frame labels use
`HH:MM:SS;FF`.

```mbt check
///|
test "parse and format a 25fps label" {
  match @timecode.parse_timecode_result("01:00:00:00", Fps25) {
    Ok(tc) => {
      assert_eq(tc.to_frames(), 90000)
      assert_eq(tc.format(), "01:00:00:00")
    }
    Err(_) => fail("expected valid 25fps timecode")
  }
}
```

`parse_timecode` keeps the older convenience API and returns `None` on any
parse error:

```mbt check
///|
test "option parser stays compact" {
  assert_true(@timecode.parse_timecode("00:00:01:25", Fps25) is None)
}
```

Use `parse_timecode_result` when callers need precise diagnostics:

```mbt check
///|
test "result parser reports drop-frame label errors" {
  match @timecode.parse_timecode_result("00:01:00;00", Fps2997Drop) {
    Err(InvalidDropFrameLabel) => ()
    _ => fail("expected skipped drop-frame label")
  }
}
```

## Frame Rates

Frame-rate labels can be parsed from common CLI and metadata spelling variants.
Plain `29.97` and `59.94` mean non-drop-frame; drop-frame needs `df` or
`drop`.

```mbt check
///|
test "parse frame-rate aliases" {
  assert_true(@timecode.FrameRate::parse("23.98") == Some(Fps23976))
  assert_true(@timecode.FrameRate::parse("29.97 drop") == Some(Fps2997Drop))
  assert_true(@timecode.FrameRate::parse("59.94ndf") == Some(Fps5994NonDrop))
  assert_eq(@timecode.Fps2997Drop.label(), "29.97df")
}
```

Exact rates expose their numerator and denominator:

```mbt check
///|
test "inspect exact NTSC rate ratios" {
  assert_eq(@timecode.Fps23976.fps_numerator(), 24000)
  assert_eq(@timecode.Fps23976.fps_denominator(), 1001)
  assert_eq(@timecode.Fps2997Drop.nominal_fps(), 30)
}
```

## Convert

`convert_timecode` converts through exact frame-rate ratios and nearest-integer
rounding, not through an integer millisecond hop.

```mbt check
///|
test "convert 23.976 to 25fps" {
  let source = @timecode.Fps23976.frames_to_timecode(24000)
  let converted = @timecode.convert_timecode(source, Fps25)
  assert_eq(converted.to_frames(), 25025)
  assert_eq(converted.format(), "00:16:41:00")
}
```

## Duration

`Duration` is a span, not a label. Duration arithmetic is same-rate only and
returns `None` for mismatched frame rates.

```mbt check
///|
test "add durations at one frame rate" {
  let left = @timecode.Duration::from_frames(48, Fps24)
  let right = @timecode.Duration::from_frames(12, Fps24)
  match left.add(right) {
    Some(total) => assert_eq(total.to_frames(), 60)
    None => fail("expected same-rate duration add")
  }
  assert_true(left.add(@timecode.Duration::from_frames(12, Fps25)) is None)
}
```

Negative durations format with a leading sign:

```mbt check
///|
test "format negative durations" {
  let duration = @timecode.Duration::from_frames(-50, Fps25)
  assert_eq(duration.format(), "-00:00:02:00")
}
```

## Timecode Arithmetic

Timecode arithmetic converts labels to frame counts, applies arithmetic, then
formats back through the frame-rate rules. Positions before zero saturate to
`00:00:00:00`.

```mbt check
///|
test "add frames across a drop-frame minute boundary" {
  let start = @timecode.Fps2997Drop.frames_to_timecode(1797)
  let end = start.add_frames(5)
  assert_eq(end.format(), "00:01:00;04")
  assert_true(start.frame_distance(end) == Some(5))
}
```

## Ranges

`TimecodeRange` is half-open: `start` is included and `end` is excluded.

```mbt check
///|
test "measure and shift a half-open timecode range" {
  let start = @timecode.Fps25.frames_to_timecode(100)
  let end = @timecode.Fps25.frames_to_timecode(160)
  match @timecode.TimecodeRange::new(start, end) {
    Some(range) => {
      assert_true(
        range.contains(@timecode.Fps25.frames_to_timecode(120)) == Some(true),
      )
      assert_true(range.contains(end) == Some(false))
      match range.duration() {
        Some(duration) => assert_eq(duration.to_frames(), 60)
        None => fail("expected same-rate duration")
      }
    }
    None => fail("expected valid range")
  }
}
```

## Metadata Policies

Some file formats store the drop-frame flag outside the visible label. Use
`parse_timecode_with_policy` for those metadata-driven cases.

```mbt check
///|
test "parse metadata-driven drop-frame text" {
  let policy = @timecode.TimecodeParsePolicy::{
    separator_mode: IgnoreForInterop,
  }
  match
    @timecode.parse_timecode_with_policy("01:00:00:00", Fps2997Drop, policy) {
    Ok(tc) => assert_eq(tc.format(), "01:00:00;00")
    Err(_) => fail("expected metadata-driven drop-frame parse")
  }
}
```

Frame-to-label conversion can preserve hours beyond 24 or wrap into a 24-hour
day.

```mbt check
///|
test "wrap labels at 24 hours" {
  assert_eq(
    @timecode.Fps25
    .frames_to_timecode_with_wrap(25 * 3600 * 24, Wrap24Hour)
    .format(),
    "00:00:00:00",
  )
}
```

## Rational Seconds

Interop metadata often stores media time as rational seconds, for example
FCPXML `frameDuration="1001/30000s"`.

```mbt check
///|
test "convert rational seconds to frames" {
  match @timecode.RationalSeconds::parse("1001/30000s") {
    Some(frame_duration) => assert_eq(frame_duration.to_frames(Fps2997Drop), 1)
    None => fail("expected rational frame duration")
  }
}
```

## FCPXML

FCPXML stores `frameDuration`, `tcStart`, and `tcFormat` separately.

```mbt check
///|
test "convert FCPXML timecode attributes" {
  let attrs = @timecode.FcpXmlTimecodeAttrs::{
    frame_duration: { numerator: 1001L, denominator: 30000L },
    tc_start: { numerator: 3600L, denominator: 1L },
    tc_format: DF,
  }
  match attrs.to_timecode() {
    Ok(tc) => assert_eq(tc.format(), "01:00:00;00")
    Err(_) => fail("expected FCPXML timecode")
  }
}
```

## IMF

IMF-style fields keep the nominal rate, drop-frame flag, and visible start
address separate.

```mbt check
///|
test "convert IMF timecode fields" {
  let imf = @timecode.ImfTimecode::{
    rate: 30,
    drop_frame: true,
    start_address: "01:00:00:00",
  }
  match imf.to_timecode() {
    Ok(tc) => assert_eq(tc.format(), "01:00:00;00")
    Err(_) => fail("expected IMF timecode")
  }
}
```

## Apple Delivery

Apple delivery packages use compact frame-rate mode strings.

```mbt check
///|
test "parse Apple delivery timecode format" {
  assert_true(
    @timecode.AppleDeliveryTimecodeFormat::parse("30/1000 1001/dropNTSC") ==
    Some(Fps2997Drop),
  )
}
```

## Boundaries

This first public version intentionally keeps cross-rate behavior explicit:

- `Timecode::frame_distance`, `is_before`, `is_after`, and range methods return
  `None` when frame rates differ.
- `Duration::add` and `Duration::sub` return `None` when frame rates differ.
- Negative `Timecode` positions saturate to zero.
- `FrameRate::frames_to_timecode` does not wrap at 24 hours unless
  `frames_to_timecode_with_wrap(..., Wrap24Hour)` is used.
- FCPXML, IMF, and Apple delivery helpers cover timecode metadata fields, not
  full file parsing.
- LTC/VITC/ATC transport, ST 12 user bits, binary packing, EDL, and full
  FCPXML/IMF document parsing are future extension points.
