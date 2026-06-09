///|
test "creator profiles map self-media names to text-aware qc defaults" {
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      assert_eq(profile.name, "douyin")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 10)
      assert_true(profile.text_style.mode == TextStyleZh)
      assert_true(profile.punctuation_mode == TextStyleZh)
    }
    None => fail("expected douyin profile")
  }
  match creator_profile_by_name("bilingual") {
    Some(profile) => {
      assert_eq(profile.name, "bilingual")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 12)
      assert_true(profile.text_style.mode == TextStyleBilingual)
      assert_true(profile.punctuation_mode == TextStyleBilingual)
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
      assert_true(profile.text_style.mode == TextStyleZh)
      assert_true(profile.punctuation_mode == TextStyleZh)
    }
    None => fail("expected bilibili profile")
  }
  match creator_profile_by_name("bili") {
    Some(profile) => {
      assert_eq(profile.name, "bilibili")
      assert_true(profile.text_style.mode == TextStyleZh)
      assert_true(profile.punctuation_mode == TextStyleZh)
    }
    None => fail("expected bili alias")
  }
  match creator_profile_by_name("youtube") {
    Some(profile) => {
      assert_eq(profile.name, "youtube")
      assert_true(profile.qc_profile.max_cpl is None)
      assert_eq(profile.qc_profile.max_cps, 20)
      assert_true(profile.text_style.mode == TextStyleEn)
      assert_true(profile.punctuation_mode == TextStyleEn)
    }
    None => fail("expected youtube profile")
  }
  match creator_profile_by_name("yt") {
    Some(profile) => {
      assert_eq(profile.name, "youtube")
      assert_true(profile.text_style.mode == TextStyleEn)
      assert_true(profile.punctuation_mode == TextStyleEn)
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
      assert_true(profile.punctuation_mode == TextStyleZh)
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
      assert_true(profile.text_style.mode == TextStyleEn)
      assert_true(profile.punctuation_mode == TextStyleEn)
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
      let issues = check_creator_cues(cues, profile, None)
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
      let issues = check_creator_cues(cues, profile, None)
      assert_false(issues.any(issue => issue.code == "W203"))
    }
    None => fail("expected douyin profile")
  }
}

///|
test "clean creator line fixes repeated words asr and confusion" {
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      let result = clean_creator_line(
        "然后然后我们认真的做 [Music] 你好,世界!",
        profile,
        None,
      )
      assert_eq(result.text, "然后我们认真地做 你好，世界！")
      let codes = result.actions.map(fn(a) { a.code })
      assert_true(codes.contains("C601")) // repeated word
      assert_true(codes.contains("C602")) // ASR marker
      assert_true(codes.contains("C401")) // confusion pair
    }
    None => fail("expected douyin profile")
  }
}

///|
test "clean creator line leaves clean text untouched" {
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      let result = clean_creator_line("今天天气很好", profile, None)
      assert_eq(result.text, "今天天气很好")
      assert_eq(result.actions.length(), 0)
    }
    None => fail("expected douyin profile")
  }
}

///|
test "clean creator cues applies line cleaning to all cues" {
  match creator_profile_by_name("douyin") {
    Some(profile) => {
      let cues = [
        @subtitle.Cue::{
          index: Some(1),
          identifier: None,
          start_ms: 1000,
          end_ms: 3000,
          text: ["然后然后我们认真的做"],
          settings: "",
        },
        @subtitle.Cue::{
          index: Some(2),
          identifier: None,
          start_ms: 4000,
          end_ms: 7000,
          text: ["[Music] 你好,世界!"],
          settings: "",
        },
      ]
      let result = clean_creator_cues(cues, profile, None)
      assert_eq(result.cues[0].text[0], "然后我们认真地做")
      assert_eq(result.cues[1].text[0], "你好，世界！")
      assert_true(result.total_actions() > 0)
      // Timing unchanged
      assert_eq(result.cues[0].start_ms, 1000)
      assert_eq(result.cues[0].end_ms, 3000)
      // Index unchanged
      assert_true(result.cues[0].index == Some(1))
    }
    None => fail("expected douyin profile")
  }
}

///|
test "clean creator line bilingual mode fixes both zh and en" {
  match creator_profile_by_name("bilingual") {
    Some(profile) => {
      let result = clean_creator_line(
        "然后然后 the the quick brown fox",
        profile,
        None,
      )
      assert_false(result.text.contains("然后然后"))
      assert_false(result.text.contains("the the"))
    }
    None => fail("expected bilingual profile")
  }
}
