///|
pub(all) struct BilingualSplit {
  primary : Array[@subtitle.Cue]
  secondary : Array[@subtitle.Cue]
} derive(Eq, Debug)

///|
fn abs_int(value : Int) -> Int {
  if value < 0 {
    -value
  } else {
    value
  }
}

///|
fn min_int(a : Int, b : Int) -> Int {
  if a < b {
    a
  } else {
    b
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a > b {
    a
  } else {
    b
  }
}

///|
fn with_text(cue : @subtitle.Cue, text : Array[String]) -> @subtitle.Cue {
  {
    index: cue.index,
    identifier: cue.identifier,
    start_ms: cue.start_ms,
    end_ms: cue.end_ms,
    text,
    settings: cue.settings,
  }
}

///|
fn merged_cue(
  primary : @subtitle.Cue,
  secondary : @subtitle.Cue,
) -> @subtitle.Cue {
  {
    index: primary.index,
    identifier: primary.identifier,
    start_ms: min_int(primary.start_ms, secondary.start_ms),
    end_ms: max_int(primary.end_ms, secondary.end_ms),
    text: primary.text + secondary.text,
    settings: primary.settings,
  }
}

///|
fn find_match(
  cue : @subtitle.Cue,
  candidates : Array[@subtitle.Cue],
  tolerance_ms : Int,
) -> @subtitle.Cue? {
  for candidate in candidates {
    if abs_int(candidate.start_ms - cue.start_ms) <= tolerance_ms &&
      abs_int(candidate.end_ms - cue.end_ms) <= tolerance_ms {
      return Some(candidate)
    }
  }
  None
}

///|
pub fn merge_bilingual(
  primary : Array[@subtitle.Cue],
  secondary : Array[@subtitle.Cue],
  tolerance_ms~ : Int,
) -> Array[@subtitle.Cue] {
  let merged : Array[@subtitle.Cue] = []
  for cue in primary {
    match find_match(cue, secondary, tolerance_ms) {
      Some(other) => merged.push(merged_cue(cue, other))
      None => merged.push(cue)
    }
  }
  merged
}

///|
pub fn split_bilingual(cues : Array[@subtitle.Cue]) -> BilingualSplit {
  let primary : Array[@subtitle.Cue] = []
  let secondary : Array[@subtitle.Cue] = []
  for cue in cues {
    match cue.text {
      [first, second, .. rest] => {
        primary.push(with_text(cue, [first]))
        secondary.push(with_text(cue, [second, ..rest]))
      }
      [first] => {
        primary.push(with_text(cue, [first]))
        secondary.push(with_text(cue, []))
      }
      [] => {
        primary.push(with_text(cue, []))
        secondary.push(with_text(cue, []))
      }
    }
  }
  { primary, secondary }
}
