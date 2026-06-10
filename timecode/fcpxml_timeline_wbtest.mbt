///|
test "parse_fcpxml_timeline parses a simple one-clip timeline" {
  let raw =
    #|<?xml version="1.0" encoding="UTF-8"?>
    #|<!DOCTYPE fcpxml>
    #|<fcpxml version="1.9">
    #|  <resources>
    #|    <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s" width="1920" height="1080"/>
    #|    <asset id="r2" name="MyClip.mov" src="file:///path/MyClip.mov">
    #|      <media-representation kind="original"/>
    #|    </asset>
    #|  </resources>
    #|  <library>
    #|    <event name="Test Event">
    #|      <project name="Test Project">
    #|        <sequence format="r1" tcStart="0s" tcFormat="NDF" duration="100/2500s">
    #|          <spine>
    #|            <asset-clip name="MyClip" ref="r2" offset="0s" duration="100/2500s" start="0s"/>
    #|          </spine>
    #|        </sequence>
    #|      </project>
    #|    </event>
    #|  </library>
    #|</fcpxml>
  match parse_fcpxml_timeline(raw) {
    Ok(timeline) => {
      assert_eq(timeline.format_id, "r1")
      assert_eq(timeline.resources.length(), 2)
      assert_eq(timeline.clip_count(), 1)
      assert_eq(timeline.gap_count(), 0)
      // Check format resource.
      let fmt = timeline.resources[0]
      assert_eq(fmt.id, "r1")
      assert_eq(fmt.name, "FFVideoFormat1080p25")
      assert_eq(fmt.frame_duration, "100/2500s")
      assert_eq(fmt.width, 1920)
      assert_eq(fmt.height, 1080)
      // Check asset resource.
      let asset = timeline.resources[1]
      assert_eq(asset.id, "r2")
      assert_eq(asset.name, "MyClip.mov")
      assert_eq(asset.src, "file:///path/MyClip.mov")
      // Check clip.
      match timeline.items[0] {
        Clip(clip) => {
          assert_eq(clip.name, "MyClip")
          assert_eq(clip.ref_id, "r2")
        }
        Gap(_) => fail("expected Clip, got Gap")
      }
    }
    Err(_) => fail("expected parsed FCPXML timeline")
  }
}

///|
test "parse_fcpxml_timeline handles clips and gaps" {
  let raw =
    #|<fcpxml version="1.9">
    #|  <resources>
    #|    <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s"/>
    #|  </resources>
    #|  <sequence format="r1" tcStart="0s" tcFormat="NDF" duration="7200/2500s">
    #|    <spine>
    #|      <asset-clip name="Clip1" ref="r2" offset="0s" duration="3600/2500s" start="3600/2500s"/>
    #|      <gap name="Gap" offset="3600/2500s" duration="3600/2500s"/>
    #|    </spine>
    #|  </sequence>
    #|</fcpxml>
  match parse_fcpxml_timeline(raw) {
    Ok(timeline) => {
      assert_eq(timeline.items.length(), 2)
      assert_eq(timeline.clip_count(), 1)
      assert_eq(timeline.gap_count(), 1)
      match timeline.items[0] {
        Clip(clip) => {
          assert_eq(clip.name, "Clip1")
          assert_eq(clip.ref_id, "r2")
        }
        Gap(_) => fail("expected Clip")
      }
      match timeline.items[1] {
        Gap(gap) => assert_eq(gap.name, "Gap")
        Clip(_) => fail("expected Gap")
      }
    }
    Err(_) => fail("expected parsed FCPXML timeline")
  }
}

///|
test "parse_fcpxml_timeline returns MissingElement for no sequence" {
  let raw =
    #|<fcpxml version="1.9">
    #|  <resources>
    #|    <format id="r1" name="test" frameDuration="100/2500s"/>
    #|  </resources>
    #|</fcpxml>
  match parse_fcpxml_timeline(raw) {
    Err(MissingElement(name)) => assert_eq(name, "sequence")
    Ok(_) => fail("expected MissingElement error")
    Err(_) => fail("expected MissingElement")
  }
}

///|
test "FcpxmlTimeline::resource_by_id looks up resources" {
  let timeline : FcpxmlTimeline = {
    format_id: "r1",
    tc_start: zero_seconds(),
    tc_format: NDF,
    duration: zero_seconds(),
    resources: [
      {
        id: "r1",
        name: "format",
        frame_duration: "100/2500s",
        width: 1920,
        height: 1080,
        src: "",
      },
      {
        id: "r2",
        name: "asset",
        frame_duration: "",
        width: 0,
        height: 0,
        src: "file.mov",
      },
    ],
    items: [],
  }
  match timeline.resource_by_id("r1") {
    Some(r) => {
      assert_eq(r.id, "r1")
      assert_eq(r.width, 1920)
    }
    None => fail("expected resource r1")
  }
  match timeline.resource_by_id("r2") {
    Some(r) => assert_eq(r.src, "file.mov")
    None => fail("expected resource r2")
  }
  assert_true(timeline.resource_by_id("r99") == None)
}

///|
test "FcpxmlTimeline::format_frame_duration resolves format resource" {
  let timeline : FcpxmlTimeline = {
    format_id: "r1",
    tc_start: zero_seconds(),
    tc_format: NDF,
    duration: zero_seconds(),
    resources: [
      {
        id: "r1",
        name: "format",
        frame_duration: "100/2500s",
        width: 1920,
        height: 1080,
        src: "",
      },
    ],
    items: [],
  }
  match timeline.format_frame_duration() {
    Some(fd) => {
      let expected = match RationalSeconds::new(100L, 2500L) {
        Some(v) => v
        None => fail("expected rational seconds")
      }
      assert_true(fd == expected)
    }
    None => fail("expected frame duration")
  }
}

///|
test "FcpxmlTimeline::format_frame_duration returns None for missing format" {
  let timeline : FcpxmlTimeline = {
    format_id: "r99",
    tc_start: zero_seconds(),
    tc_format: NDF,
    duration: zero_seconds(),
    resources: [],
    items: [],
  }
  assert_true(timeline.format_frame_duration() == None)
}

///|
test "parse_fcpxml_timeline handles drop-frame tcFormat" {
  let raw =
    #|<fcpxml version="1.9">
    #|  <resources>
    #|    <format id="r1" name="FFVideoFormat1080i2997" frameDuration="1001/30000s"/>
    #|  </resources>
    #|  <sequence format="r1" tcStart="0s" tcFormat="DF" duration="3600/30000s">
    #|    <spine>
    #|      <asset-clip name="Clip" ref="r2" offset="0s" duration="3600/30000s" start="0s"/>
    #|    </spine>
    #|  </sequence>
    #|</fcpxml>
  match parse_fcpxml_timeline(raw) {
    Ok(timeline) => assert_true(timeline.tc_format == DF)
    Err(_) => fail("expected parsed FCPXML timeline with DF")
  }
}
