///|
test "delivery classifies common asset filenames" {
  assert_true(classify_asset("E01_final.mp4") == VideoAsset)
  assert_true(classify_asset("E01_final.MOV") == VideoAsset)
  assert_true(classify_asset("E01.zh-Hans.srt") == SubtitleAsset)
  assert_true(classify_asset("E01.en-US.vtt") == SubtitleAsset)
  assert_true(classify_asset("E01.poster.jpg") == PosterAsset)
  assert_true(classify_asset("E01.metadata.json") == MetadataAsset)
  assert_true(classify_asset("checksum.txt") == ChecksumAsset)
  assert_true(classify_asset("SHA256SUMS") == ChecksumAsset)
  assert_true(classify_asset("moonpost.delivery.json") == ManifestAsset)
  assert_true(classify_asset("notes.pdf") == OtherAsset)
}

///|
test "delivery infers conservative subtitle language tokens" {
  assert_true(language_from_subtitle_name("E01.zh-Hans.srt") == Some("zh-Hans"))
  assert_true(language_from_subtitle_name("E01.en-US.vtt") == Some("en-US"))
  assert_true(language_from_subtitle_name("E01.zh.srt") == Some("zh"))
  assert_true(language_from_subtitle_name("E01.subtitle.srt") is None)
  assert_true(language_from_subtitle_name("E01.zh-Hans.txt") is None)
}

///|
test "creator and distribution profiles expose delivery requirements" {
  let creator = creator_profile()
  assert_eq(creator.name, "creator")
  assert_true(creator.require_video)
  assert_true(creator.require_subtitle)
  assert_false(creator.require_metadata)
  assert_false(creator.require_checksum)
  assert_true(creator.warn_missing_poster)
  assert_true(creator.subtitle_qc == @qc.social_video_profile())
  let distribution = distribution_profile()
  assert_eq(distribution.name, "distribution")
  assert_true(distribution.require_video)
  assert_true(distribution.require_subtitle)
  assert_true(distribution.require_metadata)
  assert_true(distribution.require_checksum)
  assert_true(distribution.warn_missing_poster)
  assert_true(distribution.subtitle_qc == @qc.streaming_profile())
}

///|
test "delivery manifest parses strict delivery metadata" {
  let raw =
    #|{
    #|  "series": "Moon Drama",
    #|  "season": "S01",
    #|  "episode": "E01",
    #|  "title": "Episode 1",
    #|  "frame_rate": "25",
    #|  "duration": "00:08:12:00",
    #|  "required_subtitles": ["zh-Hans", "en-US"],
    #|  "required_assets": ["video", "subtitle", "metadata", "checksum"]
    #|}
  match parse_manifest(raw) {
    Ok(manifest) => {
      assert_true(manifest.series == Some("Moon Drama"))
      assert_true(manifest.season == Some("S01"))
      assert_true(manifest.episode == Some("E01"))
      assert_true(manifest.title == Some("Episode 1"))
      assert_true(manifest.duration_ms == Some(492000))
      assert_true(manifest.required_subtitles == ["zh-Hans", "en-US"])
      assert_true(manifest.required_assets.contains(VideoAsset))
      assert_true(manifest.required_assets.contains(SubtitleAsset))
      assert_true(manifest.required_assets.contains(MetadataAsset))
      assert_true(manifest.required_assets.contains(ChecksumAsset))
    }
    Err(message) => fail(message)
  }
}

///|
test "delivery manifest reports malformed json and unknown assets" {
  match parse_manifest("{") {
    Err(message) => assert_true(message.contains("invalid manifest json"))
    Ok(_) => fail("expected parse error")
  }
  let bad_asset =
    #|{"required_assets":["codec"]}
  match parse_manifest(bad_asset) {
    Err(message) => assert_true(message.contains("unknown required asset"))
    Ok(_) => fail("expected unknown asset error")
  }
}

///|
test "delivery subtitle profiles map film and ott qc defaults" {
  match delivery_subtitle_profile_by_name("ott-zh") {
    Some(profile) => {
      assert_eq(profile.name, "ott-zh")
      assert_true(profile.qc_profile == @qc.streaming_profile())
      assert_true(profile.text_style.mode == @qc.TextStyleNone)
      assert_true(profile.srt_policy is None)
    }
    None => fail("expected ott-zh profile")
  }
  match delivery_subtitle_profile_by_name("cinema-zh") {
    Some(profile) => {
      assert_eq(profile.name, "cinema-zh")
      assert_true(profile.qc_profile == @qc.cinema_profile())
      assert_true(profile.srt_policy is None)
    }
    None => fail("expected cinema-zh profile")
  }
  match delivery_subtitle_profile_by_name("srt-basic") {
    Some(profile) => {
      assert_eq(profile.name, "srt-basic")
      assert_true(profile.qc_profile == @qc.default_profile())
      assert_true(profile.text_style == @qc.no_text_style_profile())
      assert_true(profile.srt_policy is Some(_))
    }
    None => fail("expected srt-basic profile")
  }
  match delivery_subtitle_profile_by_name("dcp-source-srt") {
    Some(profile) => {
      assert_eq(profile.name, "dcp-source-srt")
      assert_true(profile.qc_profile == @qc.cinema_profile())
      assert_true(profile.srt_policy is Some(_))
    }
    None => fail("expected dcp-source-srt profile")
  }
  assert_true(delivery_subtitle_profile_by_name("douyin") is None)
}

///|
test "delivery subtitle profile aliases resolve public defaults" {
  match delivery_subtitle_profile_by_name("ott") {
    Some(profile) => {
      assert_eq(profile.name, "ott-zh")
      assert_true(profile.qc_profile == @qc.streaming_profile())
      assert_true(profile.text_style == @qc.no_text_style_profile())
    }
    None => fail("expected ott alias profile")
  }
  match delivery_subtitle_profile_by_name("cinema") {
    Some(profile) => {
      assert_eq(profile.name, "cinema-zh")
      assert_true(profile.qc_profile == @qc.cinema_profile())
    }
    None => fail("expected cinema alias profile")
  }
  match delivery_subtitle_profile_by_name("broadcast") {
    Some(profile) => {
      assert_eq(profile.name, "broadcast")
      assert_true(profile.qc_profile == @qc.streaming_profile())
      assert_true(profile.text_style == @qc.no_text_style_profile())
    }
    None => fail("expected broadcast profile")
  }
  match delivery_subtitle_profile_by_name("dcp-srt") {
    Some(profile) => assert_eq(profile.name, "dcp-source-srt")
    None => fail("expected dcp-srt alias profile")
  }
}

///|
test "delivery subtitle profiles expose stable metadata" {
  let ott = ott_zh_subtitle_profile()
  assert_eq(ott.name, "ott-zh")
  assert_eq(ott.version, "v1")
  assert_true(ott.description.contains("OTT"))
  assert_true(ott.qc_profile == @qc.streaming_profile())
  assert_true(ott.text_style == @qc.no_text_style_profile())
  let cinema = cinema_zh_subtitle_profile()
  assert_eq(cinema.name, "cinema-zh")
  assert_eq(cinema.version, "v1")
  assert_true(cinema.description.to_lower().contains("cinema"))
  assert_true(cinema.qc_profile == @qc.cinema_profile())
  assert_true(cinema.text_style == @qc.no_text_style_profile())
  let broadcast = broadcast_subtitle_profile()
  assert_eq(broadcast.name, "broadcast")
  assert_eq(broadcast.version, "v1")
  assert_true(broadcast.description.to_lower().contains("broadcast"))
  assert_true(broadcast.qc_profile == @qc.streaming_profile())
  assert_true(broadcast.text_style == @qc.no_text_style_profile())
  assert_true(broadcast.srt_policy is None)
  let basic = srt_basic_subtitle_profile()
  assert_eq(basic.name, "srt-basic")
  assert_eq(basic.version, "v1")
  assert_true(basic.description.contains("SRT"))
  assert_true(basic.qc_profile == @qc.default_profile())
  assert_true(basic.srt_policy is Some(_))
  let dcp = dcp_source_srt_subtitle_profile()
  assert_eq(dcp.name, "dcp-source-srt")
  assert_eq(dcp.version, "v1")
  assert_true(dcp.description.contains("DCP"))
  assert_true(dcp.qc_profile == @qc.cinema_profile())
  assert_true(dcp.srt_policy is Some(_))
}

///|
test "delivery subtitle profiles can be listed for help output" {
  let profiles = delivery_subtitle_profiles()
  assert_eq(profiles.length(), 5)
  assert_true(profiles.any(profile => profile.name == "ott-zh"))
  assert_true(profiles.any(profile => profile.name == "cinema-zh"))
  assert_true(profiles.any(profile => profile.name == "broadcast"))
  assert_true(profiles.any(profile => profile.name == "srt-basic"))
  assert_true(profiles.any(profile => profile.name == "dcp-source-srt"))
}

///|
test "delivery package assets retain kind and subtitle language" {
  let assets = package_assets_from_names([
    "E01.mxf", "E01.zh-Hans.srt", "E01.en-US.vtt", "E01.poster.jpg", "E01.metadata.json",
    "checksum.txt",
  ])
  assert_eq(assets.length(), 6)
  assert_true(
    assets.any(asset => {
      asset.name == "E01.zh-Hans.srt" &&
      asset.kind == SubtitleAsset &&
      asset.language == Some("zh-Hans")
    }),
  )
  assert_true(
    assets.any(asset => {
      asset.name == "checksum.txt" && asset.kind == ChecksumAsset
    }),
  )
}

///|
test "delivery package check reports missing required assets and poster warning" {
  let pkg = DeliveryPackage::{
    name: "bad-package",
    assets: package_assets_from_names(["E01.mp4", "E01.zh.srt"]),
    manifest: None,
  }
  let issues = check_package(pkg, distribution_profile())
  assert_true(
    issues.any(issue => {
      issue.code == "D101" && issue.message.contains("metadata")
    }),
  )
  assert_true(
    issues.any(issue => {
      issue.code == "D101" && issue.message.contains("checksum")
    }),
  )
  assert_true(
    issues.any(issue => issue.code == "D102" && issue.message.contains("poster")),
  )
}

///|
test "delivery package check reports manifest required subtitle languages" {
  let raw_manifest =
    #|{
    #|  "required_subtitles": ["zh", "en"],
    #|  "required_assets": ["video", "subtitle", "metadata", "checksum"]
    #|}
  let manifest = match parse_manifest(raw_manifest) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  let pkg = DeliveryPackage::{
    name: "manifest-package",
    assets: package_assets_from_names([
      "E01.mp4", "E01.zh.srt", "E01.metadata.json", "checksum.txt", "E01.poster.jpg",
    ]),
    manifest: Some(manifest),
  }
  let issues = check_package(pkg, distribution_profile())
  assert_true(
    issues.any(issue => issue.code == "D202" && issue.message.contains("en")),
  )
  assert_false(
    issues.any(issue => {
      issue.code == "D101" && issue.message.contains("metadata")
    }),
  )
}

///|
test "delivery package check accepts complete distribution package" {
  let raw_manifest =
    #|{
    #|  "required_subtitles": ["zh", "en"],
    #|  "required_assets": ["video", "subtitle", "metadata", "checksum"]
    #|}
  let manifest = match parse_manifest(raw_manifest) {
    Ok(value) => value
    Err(message) => fail(message)
  }
  let pkg = DeliveryPackage::{
    name: "good-package",
    assets: package_assets_from_names([
      "E01.mp4", "E01.zh.srt", "E01.en.vtt", "E01.metadata.json", "checksum.txt",
      "E01.poster.jpg",
    ]),
    manifest: Some(manifest),
  }
  let issues = check_package(pkg, distribution_profile())
  assert_eq(issues.length(), 0)
}

///|
test "delivery sha256 matches standard vectors" {
  assert_eq(
    sha256_hex(b""),
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )
  assert_eq(
    sha256_hex(b"abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  assert_eq(
    sha256_hex(b"hello world"),
    "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9",
  )
}

///|
test "delivery sha256 supports chunked updates" {
  let state = Sha256State::new()
  state.update(b"hello ")
  state.update(b"world")
  assert_eq(
    state.final_hex(),
    "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9",
  )
}

///|
test "delivery checksum manifest parses sha256sum entries" {
  let video_hash = sha256_hex(b"video")
  let subtitle_hash = sha256_hex(b"subtitle")
  let manifest = parse_checksum_manifest(
    "# generated by MoonPost\n\{video_hash}  E01.mp4\n\{subtitle_hash} *E01.zh.srt\n",
  )
  assert_eq(manifest.issues.length(), 0)
  assert_eq(manifest.entries.length(), 2)
  assert_eq(manifest.entries[0].expected_sha256, video_hash)
  assert_eq(manifest.entries[0].target, "E01.mp4")
  assert_eq(manifest.entries[1].expected_sha256, subtitle_hash)
  assert_eq(manifest.entries[1].target, "E01.zh.srt")
}

///|
test "delivery checksum manifest reports malformed entries" {
  let metadata_hash = sha256_hex(b"metadata")
  let poster_hash = sha256_hex(b"poster")
  let manifest = parse_checksum_manifest(
    "abcd  E01.mp4\n\{metadata_hash}  /tmp/E01.metadata.json\n\{poster_hash}  ../poster.jpg\n",
  )
  assert_eq(manifest.entries.length(), 0)
  assert_eq(manifest.issues.length(), 3)
  assert_true(manifest.issues.all(issue => issue.code == "D401"))
}

///|
test "delivery checksum check reports missing unreadable and mismatched targets" {
  let video_hash = sha256_hex(b"video")
  let entries = [
    ChecksumEntry::{ expected_sha256: video_hash, target: "E01.mp4" },
    ChecksumEntry::{ expected_sha256: video_hash, target: "E01.missing.mp4" },
    ChecksumEntry::{ expected_sha256: video_hash, target: "E01.unreadable.srt" },
  ]
  let issues = check_checksum_entries(
    entries,
    ["E01.mp4", "E01.unreadable.srt"],
    Map([("E01.mp4", sha256_hex(b"other"))]),
  )
  assert_true(
    issues.any(issue => {
      issue.code == "D403" && issue.message.contains("E01.mp4")
    }),
  )
  assert_true(
    issues.any(issue => {
      issue.code == "D402" && issue.message.contains("E01.missing.mp4")
    }),
  )
  assert_true(
    issues.any(issue => {
      issue.code == "D404" && issue.message.contains("E01.unreadable.srt")
    }),
  )
}
