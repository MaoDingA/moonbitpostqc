///|
test "EDL event parses and formats four timecode fields" {
  let line = "001  AX       V     C        01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00"
  match EdlEvent::parse(line, Fps25) {
    Ok(event) => {
      assert_eq(event.event_number, 1)
      assert_eq(event.reel, "AX")
      assert_eq(event.track, "V")
      assert_eq(event.transition, "C")
      match event.source.duration() {
        Some(duration) => assert_eq(duration.to_frames(), 250)
        None => fail("expected source duration")
      }
      match event.record.duration() {
        Some(duration) => assert_eq(duration.to_frames(), 250)
        None => fail("expected record duration")
      }
      assert_eq(
        event.format(),
        "001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00",
      )
    }
    Err(_) => fail("expected parsed EDL event")
  }
}

///|
test "EDL event honors drop-frame separators and rejects invalid ranges" {
  let line = "002 A001 V C 01:00:00;00 01:00:10;00 00:00:00;00 00:00:10;00"
  match EdlEvent::parse(line, Fps2997Drop) {
    Ok(event) => {
      assert_eq(event.source.start.format(), "01:00:00;00")
      assert_eq(event.record.end.format(), "00:00:10;00")
    }
    Err(_) => fail("expected parsed drop-frame EDL event")
  }

  let invalid = "003 A001 V C 00:00:10:00 00:00:00:00 00:00:00:00 00:00:10:00"
  match EdlEvent::parse(invalid, Fps25) {
    Err(InvalidEdlEvent) => ()
    _ => fail("expected invalid EDL event range")
  }
}
