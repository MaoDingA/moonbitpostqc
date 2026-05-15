///|
test "wasm api returns qc report for subtitle text" {
  let report = qc_subtitle(
    "1\n00:00:01,123 --> 00:00:01,500\nThis line is intentionally far too long for a delivery profile.\n",
    "streaming",
  )
  assert_true(report.contains("summary:"))
  assert_true(report.contains("W203"))
}

///|
test "wasm api reports parse failures" {
  let report = qc_subtitle("not a subtitle", "streaming")
  assert_true(report.contains("ERROR E000"))
}
