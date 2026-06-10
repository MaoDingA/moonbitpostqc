///|
test "parse_edl parses a minimal two-event EDL with title" {
  let raw =
    #|TITLE: Test Program
    #|001  AX       V     C        01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
    #|002  AX       V     C        01:00:10:00 01:00:20:00 00:00:10:00 00:00:20:00
  match parse_edl(raw, Fps25) {
    Ok(timeline) => {
      assert_eq(timeline.title, "Test Program")
      assert_true(timeline.frame_rate == Fps25)
      assert_eq(timeline.events.length(), 2)
      assert_eq(timeline.events[0].event_number, 1)
      assert_eq(timeline.events[1].event_number, 2)
    }
    Err(_) => fail("expected parsed EDL timeline")
  }
}

///|
test "parse_edl parses events with remark lines" {
  let raw =
    #|TITLE: With Remarks
    #|001  AX       V     C        01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
    #|* FROM CLIP NAME: MyClip.mov
    #|* COMMENT: Opening shot
    #|* SOURCE FILE: /path/to/MyClip.mov
    #|002  AX       V     C        01:00:10:00 01:00:20:00 00:00:10:00 00:00:20:00
    #|* FROM CLIP NAME: OtherClip.mov
  match parse_edl(raw, Fps25) {
    Ok(timeline) => {
      assert_eq(timeline.events.length(), 2)
      let e0 = timeline.events[0]
      assert_true(e0.clip_name == Some("MyClip.mov"))
      assert_true(e0.comment == Some("Opening shot"))
      assert_true(e0.source_file == Some("/path/to/MyClip.mov"))
      let e1 = timeline.events[1]
      assert_true(e1.clip_name == Some("OtherClip.mov"))
      assert_true(e1.comment == None)
      assert_true(e1.source_file == None)
    }
    Err(_) => fail("expected parsed EDL timeline with remarks")
  }
}

///|
test "parse_edl handles FCM header and blank lines" {
  let raw =
    #|TITLE: Mixed
    #|FCM: NON-DROP FRAME
    #|
    #|001  AX       V     C        01:00:00:00 01:00:05:00 00:00:00:00 00:00:05:00
    #|
    #|002  AX       V     C        01:00:05:00 01:00:10:00 00:00:05:00 00:00:10:00
  match parse_edl(raw, Fps25) {
    Ok(timeline) => {
      assert_eq(timeline.title, "Mixed")
      assert_eq(timeline.events.length(), 2)
    }
    Err(_) => fail("expected parsed EDL with headers")
  }
}

///|
test "parse_edl handles 9-field dissolve transition lines" {
  let raw =
    #|001  REEL1  V  D 050  01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
    #|002  REEL1  V  C  01:00:10:00 01:00:20:00 00:00:10:00 00:00:20:00
  match parse_edl(raw, Fps25) {
    Ok(timeline) => {
      assert_eq(timeline.events.length(), 2)
      assert_eq(timeline.events[0].transition, "D050")
      assert_eq(timeline.events[1].transition, "C")
    }
    Err(_) => fail("expected parsed EDL with dissolve")
  }
}

///|
test "parse_edl returns EmptyEdl for blank input" {
  match parse_edl("", Fps25) {
    Err(EmptyEdl) => ()
    _ => fail("expected EmptyEdl")
  }
}

///|
test "parse_edl returns EmptyEdl for title-only input" {
  match parse_edl("TITLE: No Events", Fps25) {
    Err(EmptyEdl) => ()
    _ => fail("expected EmptyEdl for title-only")
  }
}

///|
test "parse_edl returns EventError for malformed event line" {
  let raw = "001  AX  V  C  bad_timecode  01:00:10:00  00:00:00:00  00:00:10:00"
  match parse_edl(raw, Fps25) {
    Err(EventError(line, _)) => assert_eq(line, 1)
    Err(EmptyEdl) => fail("expected EventError, got EmptyEdl")
    Ok(_) => fail("expected EventError for bad timecode")
  }
}

///|
test "parse_edl parses without title" {
  let raw =
    #|001  AX       V     C        01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
  match parse_edl(raw, Fps25) {
    Ok(timeline) => {
      assert_eq(timeline.title, "")
      assert_eq(timeline.events.length(), 1)
    }
    Err(_) => fail("expected parsed EDL without title")
  }
}

///|
test "format_edl round-trips a simple timeline" {
  let raw =
    #|TITLE: Round Trip
    #|001  AX       V     C        01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
    #|* FROM CLIP NAME: Clip1.mov
    #|002  AX       V     C        01:00:10:00 01:00:20:00 00:00:10:00 00:00:20:00
  match parse_edl(raw, Fps25) {
    Ok(timeline) => {
      let formatted = format_edl(timeline)
      match parse_edl(formatted, Fps25) {
        Ok(rt) => {
          assert_eq(rt.title, timeline.title)
          assert_eq(rt.events.length(), timeline.events.length())
          assert_true(rt.events[0].clip_name == Some("Clip1.mov"))
        }
        Err(_) => fail("expected round-trip to parse")
      }
    }
    Err(_) => fail("expected initial parse")
  }
}
