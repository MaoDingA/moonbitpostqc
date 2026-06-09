///|
pub(all) struct DeliveryManifest {
  series : String?
  season : String?
  episode : String?
  title : String?
  frame_rate : @timecode.FrameRate?
  duration_ms : Int?
  required_subtitles : Array[String]
  required_assets : Array[AssetKind]
} derive(Eq, Debug)

///|
fn manifest_string(obj : Map[String, Json], key : String) -> String? {
  match obj.get(key) {
    Some(String(value)) => Some(value)
    _ => None
  }
}

///|
fn manifest_string_array(
  obj : Map[String, Json],
  key : String,
) -> Result[Array[String], String] {
  match obj.get(key) {
    Some(Array(values)) => {
      let strings : Array[String] = []
      for value in values {
        match value {
          String(text) => strings.push(text)
          _ => return Err("\{key} must contain only strings")
        }
      }
      Ok(strings)
    }
    Some(_) => Err("\{key} must be an array of strings")
    None => Ok([])
  }
}

///|
fn parse_manifest_frame_rate(raw : String) -> @timecode.FrameRate? {
  match raw {
    "23.976" | "23976" => Some(Fps23976)
    "24" => Some(Fps24)
    "25" => Some(Fps25)
    "29.97df" | "29.97DF" | "29.97-drop" | "2997df" => Some(Fps2997Drop)
    "29.97" | "2997" => Some(Fps2997NonDrop)
    "30" => Some(Fps30)
    "50" => Some(Fps50)
    "59.94df" | "59.94DF" | "59.94-drop" | "5994df" => Some(Fps5994Drop)
    "59.94" | "5994" => Some(Fps5994NonDrop)
    _ => None
  }
}

///|
fn parse_required_asset(raw : String) -> AssetKind? {
  match raw {
    "video" => Some(VideoAsset)
    "subtitle" | "subtitles" => Some(SubtitleAsset)
    "poster" => Some(PosterAsset)
    "metadata" => Some(MetadataAsset)
    "checksum" | "checksums" => Some(ChecksumAsset)
    _ => None
  }
}

///|
fn parse_required_assets(
  raw_assets : Array[String],
) -> Result[Array[AssetKind], String] {
  let assets : Array[AssetKind] = []
  for raw in raw_assets {
    match parse_required_asset(raw) {
      Some(asset) => assets.push(asset)
      None => return Err("unknown required asset: \{raw}")
    }
  }
  Ok(assets)
}

///|
fn parse_duration_ms(
  raw : String?,
  rate : @timecode.FrameRate?,
) -> Result[Int?, String] {
  match raw {
    Some(duration) =>
      match rate {
        Some(rate) =>
          match @timecode.parse_timecode(duration, rate) {
            Some(tc) => Ok(Some(rate.frames_to_ms(tc.to_frames())))
            None => Err("invalid manifest duration: \{duration}")
          }
        None => Err("manifest duration requires a valid frame_rate")
      }
    None => Ok(None)
  }
}

///|
pub fn parse_manifest(raw : String) -> Result[DeliveryManifest, String] {
  let json = @json.parse(raw) catch {
    error => return Err("invalid manifest json: \{error.to_string()}")
  }
  match json {
    Object(obj) => {
      let frame_rate = match manifest_string(obj, "frame_rate") {
        Some(raw_rate) => parse_manifest_frame_rate(raw_rate)
        None => None
      }
      let duration_ms = match
        parse_duration_ms(manifest_string(obj, "duration"), frame_rate) {
        Ok(value) => value
        Err(message) => return Err(message)
      }
      let required_subtitles = match
        manifest_string_array(obj, "required_subtitles") {
        Ok(values) => values
        Err(message) => return Err(message)
      }
      let raw_assets = match manifest_string_array(obj, "required_assets") {
        Ok(values) => values
        Err(message) => return Err(message)
      }
      let required_assets = match parse_required_assets(raw_assets) {
        Ok(values) => values
        Err(message) => return Err(message)
      }
      Ok({
        series: manifest_string(obj, "series"),
        season: manifest_string(obj, "season"),
        episode: manifest_string(obj, "episode"),
        title: manifest_string(obj, "title"),
        frame_rate,
        duration_ms,
        required_subtitles,
        required_assets,
      })
    }
    _ => Err("manifest root must be an object")
  }
}
