///|
test "creator profiles map self-media names to text-aware qc defaults" {
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      assert_eq(profile.name, "douyin")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 10)
      assert_true(profile.text_style.mode == @qc.TextStyleZh)
      assert_true(profile.punctuation_mode == @qc.TextStyleZh)
    }
    None => fail("expected douyin profile")
  }
  match creator_profile_by_name("bilingual") {
    Some(profile) => {
      assert_eq(profile.name, "bilingual")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 12)
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
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 9)
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
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 20)
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
test "new creator profiles cover additional platforms" {
  match creator_profile_by_name("xiaohongshu") {
    Some(profile) => {
      assert_eq(profile.name, "xiaohongshu")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 8)
      assert_eq(profile.qc_profile.min_duration_ms, 800)
      assert_eq(profile.qc_profile.max_duration_ms, 5000)
      assert_true(profile.punctuation_mode == @qc.TextStyleZh)
    }
    None => fail("expected xiaohongshu profile")
  }
  match creator_profile_by_name("xhs") {
    Some(profile) => assert_eq(profile.name, "xiaohongshu")
    None => fail("expected xhs alias")
  }
  match creator_profile_by_name("rednote") {
    Some(profile) => assert_eq(profile.name, "xiaohongshu")
    None => fail("expected rednote alias")
  }
  match creator_profile_by_name("kuaishou") {
    Some(profile) => {
      assert_eq(profile.name, "kuaishou")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 10)
      assert_eq(profile.qc_profile.min_duration_ms, 500)
      assert_eq(profile.qc_profile.max_duration_ms, 5000)
    }
    None => fail("expected kuaishou profile")
  }
  match creator_profile_by_name("ks") {
    Some(profile) => assert_eq(profile.name, "kuaishou")
    None => fail("expected ks alias")
  }
  match creator_profile_by_name("wechat") {
    Some(profile) => {
      assert_eq(profile.name, "wechat")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 10)
      assert_eq(profile.qc_profile.min_duration_ms, 800)
      assert_eq(profile.qc_profile.max_duration_ms, 6000)
    }
    None => fail("expected wechat profile")
  }
  match creator_profile_by_name("channels") {
    Some(profile) => assert_eq(profile.name, "wechat")
    None => fail("expected channels alias")
  }
  match creator_profile_by_name("tiktok") {
    Some(profile) => {
      assert_eq(profile.name, "tiktok")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 20)
      assert_eq(profile.qc_profile.min_duration_ms, 500)
      assert_eq(profile.qc_profile.max_duration_ms, 5000)
      assert_true(profile.text_style.mode == @qc.TextStyleEn)
      assert_true(profile.punctuation_mode == @qc.TextStyleEn)
    }
    None => fail("expected tiktok profile")
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

///|
test "creator profiles skip cpl check regardless of line length" {
  let long_line = "这是一个非常长的字幕行用来测试Creator配置是否跳过CPL检查因为不知道分辨率和字号所以CPL检查不可靠"
  let cues = [
    @subtitle.Cue::{
      index: Some(1),
      identifier: None,
      start_ms: 1000,
      end_ms: 3000,
      text: [long_line],
      settings: "",
    },
  ]
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      let issues = check_creator_cues(cues, profile)
      assert_false(issues.any(issue => issue.code == "W203"))
    }
    None => fail("expected douyin profile")
  }
}
