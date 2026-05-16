///|
test "creator profiles map self-media names to text-aware qc defaults" {
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      assert_eq(profile.name, "douyin")
      assert_true(profile.qc_profile == @qc.social_video_profile())
      assert_true(profile.text_style.mode == @qc.TextStyleZh)
      assert_true(profile.punctuation_mode == @qc.TextStyleZh)
    }
    None => fail("expected douyin profile")
  }
  match creator_profile_by_name("bilingual") {
    Some(profile) => {
      assert_eq(profile.name, "bilingual")
      assert_true(profile.text_style.mode == @qc.TextStyleBilingual)
      assert_true(profile.punctuation_mode == @qc.TextStyleBilingual)
    }
    None => fail("expected bilingual profile")
  }
  assert_true(creator_profile_by_name("unknown") is None)
}

///|
test "creator profile aliases cover exported platform defaults" {
  match creator_profile_by_name("bilibili") {
    Some(profile) => {
      assert_eq(profile.name, "bilibili")
      assert_true(profile.text_style.mode == @qc.TextStyleZh)
      assert_true(profile.punctuation_mode == @qc.TextStyleZh)
    }
    None => fail("expected bilibili profile")
  }
  match creator_profile_by_name("bili") {
    Some(profile) => {
      assert_eq(profile.name, "bilibili")
      assert_true(profile.text_style.mode == @qc.TextStyleZh)
      assert_true(profile.punctuation_mode == @qc.TextStyleZh)
    }
    None => fail("expected bili alias")
  }
  match creator_profile_by_name("youtube") {
    Some(profile) => {
      assert_eq(profile.name, "youtube")
      assert_true(profile.text_style.mode == @qc.TextStyleEn)
      assert_true(profile.punctuation_mode == @qc.TextStyleEn)
    }
    None => fail("expected youtube profile")
  }
  match creator_profile_by_name("yt") {
    Some(profile) => {
      assert_eq(profile.name, "youtube")
      assert_true(profile.text_style.mode == @qc.TextStyleEn)
      assert_true(profile.punctuation_mode == @qc.TextStyleEn)
    }
    None => fail("expected yt alias")
  }
  match creator_profile_by_name("short-video") {
    Some(profile) => assert_eq(profile.name, "douyin")
    None => fail("expected short-video alias")
  }
  match creator_profile_by_name("zh-en") {
    Some(profile) => assert_eq(profile.name, "bilingual")
    None => fail("expected zh-en alias")
  }
}

///|
test "creator check combines structural qc and text style warnings" {
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: ["你好, world！！"],
      settings: "",
    },
  ]
  match creator_profile_by_name("bilingual") {
    Some(profile) => {
      let issues = check_creator_cues(cues, profile)
      let mut saw_mixed = false
      let mut saw_repeated = false
      for issue in issues {
        if issue.code == "W501" {
          saw_mixed = true
        }
        if issue.code == "W502" {
          saw_repeated = true
        }
      }
      assert_true(saw_mixed)
      assert_true(saw_repeated)
    }
    None => fail("expected bilingual profile")
  }
}

///|
test "creator normalization uses profile punctuation mode" {
  match creator_profile_by_name("douyin") {
    Some(profile) =>
      assert_eq(
        normalize_creator_line("你好,世界!", profile),
        "你好，世界！",
      )
    None => fail("expected douyin profile")
  }
}
