///|
fn cue(
  index : Int,
  start_ms : Int,
  end_ms : Int,
  line : String,
) -> @subtitle.Cue {
  {
    index: Some(index),
    identifier: None,
    start_ms,
    end_ms,
    text: [line],
    settings: "",
  }
}

///|
test "bilingual merge combines cues inside tolerance" {
  let merged = merge_bilingual(
    [cue(1, 1000, 3200, "你好，欢迎来到 MoonBit。")],
    [cue(1, 1050, 3150, "Hello, welcome to MoonBit.")],
    tolerance_ms=200,
  )
  assert_eq(merged.length(), 1)
  assert_eq(merged[0].start_ms, 1000)
  assert_eq(merged[0].end_ms, 3200)
  assert_eq(merged[0].text.length(), 2)
  assert_eq(merged[0].text[1], "Hello, welcome to MoonBit.")
}

///|
test "bilingual split separates first and second lines" {
  let merged = cue(1, 1000, 3200, "你好")
  let merged = @subtitle.Cue::{
    index: merged.index,
    identifier: None,
    start_ms: merged.start_ms,
    end_ms: merged.end_ms,
    text: ["你好", "Hello"],
    settings: "",
  }
  let pair = split_bilingual([merged])
  assert_eq(pair.primary[0].text[0], "你好")
  assert_eq(pair.secondary[0].text[0], "Hello")
}

///|
test "bilingual merge keeps unmatched primary cue" {
  let merged = merge_bilingual(
    [cue(1, 1000, 2000, "Primary")],
    [cue(1, 4000, 5000, "Secondary")],
    tolerance_ms=200,
  )
  assert_eq(merged.length(), 1)
  assert_eq(merged[0].text.length(), 1)
  assert_eq(merged[0].text[0], "Primary")
}

///|
test "bilingual split keeps single-line cues only in primary" {
  let pair = split_bilingual([cue(1, 1000, 2000, "Only primary")])
  assert_eq(pair.primary[0].text[0], "Only primary")
  assert_eq(pair.secondary[0].text.length(), 0)
}
