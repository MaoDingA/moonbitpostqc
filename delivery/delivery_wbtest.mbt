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
