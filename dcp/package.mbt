///|
pub(all) enum DcpAssetKind {
  AssetMapAsset
  VolumeIndexAsset
  PackingListAsset
  CompositionPlaylistAsset
  PictureAsset
  SoundAsset
  SubtitleAsset
  CaptionAsset
  UnknownAsset
} derive(Eq, Debug)

///|
pub(all) struct DcpAsset {
  id : String
  path : String
  kind : DcpAssetKind
  hash : String
  size : String
  annotation : String
  edit_rate : String
  intrinsic_duration : String
} derive(Eq, Debug)

///|
pub(all) struct DcpComposition {
  id : String
  annotation : String
  assets : Array[DcpAsset]
} derive(Eq, Debug)

///|
pub(all) struct DcpPackage {
  asset_map : Array[DcpAsset]
  packing_list : Array[DcpAsset]
  composition : DcpComposition?
} derive(Eq, Debug)

///|
pub(all) enum DcpIssueSeverity {
  DcpError
  DcpWarning
} derive(Eq, Debug)

///|
pub(all) struct DcpIssue {
  severity : DcpIssueSeverity
  code : String
  asset_id : String?
  message : String
} derive(Eq, Debug)

///|
pub(all) enum DcpParseError {
  XmlError(@timecode.XmlError)
  MissingElement(String)
} derive(Eq, Debug)

///|
fn local_xml_name(name : String) -> String {
  let parts : Array[String] = []
  for part in name.split(":") {
    parts.push(part.to_owned())
  }
  if parts.length() == 0 {
    ""
  } else {
    parts[parts.length() - 1]
  }
}

///|
fn tag_key(name : String) -> String {
  local_xml_name(name).to_lower()
}

///|
fn current_tag(stack : Array[String]) -> String {
  if stack.length() == 0 {
    ""
  } else {
    stack[stack.length() - 1]
  }
}

///|
fn normalize_asset_id(text : String) -> String {
  let trimmed = text.trim().to_owned()
  if trimmed.has_prefix("urn:uuid:") {
    trimmed[9:].to_owned()
  } else {
    trimmed
  }
}

///|
pub fn DcpAssetKind::label(self : DcpAssetKind) -> String {
  match self {
    AssetMapAsset => "asset-map"
    VolumeIndexAsset => "volume-index"
    PackingListAsset => "packing-list"
    CompositionPlaylistAsset => "composition-playlist"
    PictureAsset => "picture"
    SoundAsset => "sound"
    SubtitleAsset => "subtitle"
    CaptionAsset => "caption"
    UnknownAsset => "unknown"
  }
}

///|
pub fn DcpAsset::is_subtitle(self : DcpAsset) -> Bool {
  self.kind == SubtitleAsset || self.kind == CaptionAsset
}

///|
pub fn DcpComposition::asset_count(self : DcpComposition) -> Int {
  self.assets.length()
}

///|
pub fn DcpComposition::subtitle_asset_count(self : DcpComposition) -> Int {
  let mut count = 0
  for asset in self.assets {
    if asset.is_subtitle() {
      count += 1
    }
  }
  count
}

///|
pub fn DcpPackage::asset_count(self : DcpPackage) -> Int {
  self.asset_map.length() + self.packing_list.length()
}

///|
fn kind_from_path(path : String) -> DcpAssetKind {
  let lower = path.to_lower()
  if lower == "assetmap" ||
    lower.has_suffix("/assetmap") ||
    lower.has_suffix("assetmap.xml") {
    AssetMapAsset
  } else if lower == "volindex" ||
    lower.has_suffix("/volindex") ||
    lower.has_suffix("volindex.xml") {
    VolumeIndexAsset
  } else if lower.contains("pkl") {
    PackingListAsset
  } else if lower.contains("cpl") {
    CompositionPlaylistAsset
  } else if lower.contains("subtitle") || lower.contains("sub_") {
    SubtitleAsset
  } else {
    UnknownAsset
  }
}

///|
fn kind_from_pkl_type(raw : String) -> DcpAssetKind {
  let lower = raw.to_lower()
  if lower.contains("cpl") || lower.contains("composition") {
    CompositionPlaylistAsset
  } else if lower.contains("pkl") || lower.contains("packing") {
    PackingListAsset
  } else if lower.contains("subtitle") ||
    lower.contains("timedtext") ||
    lower.contains("timed-text") {
    SubtitleAsset
  } else if lower.contains("caption") {
    CaptionAsset
  } else if lower.contains("picture") {
    PictureAsset
  } else if lower.contains("sound") || lower.contains("audio") {
    SoundAsset
  } else {
    UnknownAsset
  }
}

///|
fn kind_from_cpl_role(role : String) -> DcpAssetKind {
  match role {
    "mainpicture" | "mainstereoscopicpicture" => PictureAsset
    "mainsound" => SoundAsset
    "mainsubtitle" => SubtitleAsset
    "maincaption" | "mainclosedcaption" => CaptionAsset
    _ => UnknownAsset
  }
}

///|
fn is_cpl_asset_role(tag : String) -> Bool {
  match tag {
    "mainpicture"
    | "mainstereoscopicpicture"
    | "mainsound"
    | "mainsubtitle"
    | "maincaption"
    | "mainclosedcaption" => true
    _ => false
  }
}

///|
fn issue(
  severity : DcpIssueSeverity,
  code : String,
  asset_id : String?,
  message : String,
) -> DcpIssue {
  { severity, code, asset_id, message }
}

///|
fn tokenize_dcp_xml(
  raw : String,
) -> Result[Array[@timecode.XmlToken], DcpParseError] {
  match @timecode.tokenize_xml(raw) {
    Ok(tokens) => Ok(tokens)
    Err(error) => Err(XmlError(error))
  }
}

///|
pub fn classify_dcp_path(path : String) -> DcpAssetKind {
  kind_from_path(path)
}

///|
pub fn parse_asset_map(raw : String) -> Result[Array[DcpAsset], DcpParseError] {
  let tokens = match tokenize_dcp_xml(raw) {
    Ok(tokens) => tokens
    Err(error) => return Err(error)
  }
  let assets : Array[DcpAsset] = []
  let stack : Array[String] = []
  let mut in_asset = false
  let mut depth = 0
  let mut id = ""
  let mut path = ""
  for token in tokens {
    match token {
      OpenTag(name, _) => {
        let tag = tag_key(name)
        stack.push(tag)
        if tag == "asset" && !in_asset {
          in_asset = true
          depth = 1
          id = ""
          path = ""
        } else if in_asset {
          depth += 1
        }
      }
      SelfCloseTag(_, _) => ()
      Text(text) =>
        if in_asset {
          match current_tag(stack) {
            "id" => if id.is_empty() { id = normalize_asset_id(text) }
            "path" => if path.is_empty() { path = text.trim().to_owned() }
            _ => ()
          }
        }
      CloseTag(name) => {
        let tag = tag_key(name)
        if in_asset && tag == "asset" && depth == 1 {
          assets.push({
            id,
            path,
            kind: kind_from_path(path),
            hash: "",
            size: "",
            annotation: "",
            edit_rate: "",
            intrinsic_duration: "",
          })
          in_asset = false
          depth = 0
        } else if in_asset {
          depth -= 1
        }
        ignore(stack.pop())
      }
    }
  }
  if assets.length() == 0 {
    Err(MissingElement("AssetMap/AssetList/Asset"))
  } else {
    Ok(assets)
  }
}

///|
pub fn parse_packing_list(
  raw : String,
) -> Result[Array[DcpAsset], DcpParseError] {
  let tokens = match tokenize_dcp_xml(raw) {
    Ok(tokens) => tokens
    Err(error) => return Err(error)
  }
  let assets : Array[DcpAsset] = []
  let stack : Array[String] = []
  let mut in_asset = false
  let mut depth = 0
  let mut id = ""
  let mut annotation = ""
  let mut hash = ""
  let mut size = ""
  let mut raw_type = ""
  for token in tokens {
    match token {
      OpenTag(name, _) => {
        let tag = tag_key(name)
        stack.push(tag)
        if tag == "asset" && !in_asset {
          in_asset = true
          depth = 1
          id = ""
          annotation = ""
          hash = ""
          size = ""
          raw_type = ""
        } else if in_asset {
          depth += 1
        }
      }
      SelfCloseTag(_, _) => ()
      Text(text) =>
        if in_asset {
          let value = text.trim().to_owned()
          match current_tag(stack) {
            "id" => if id.is_empty() { id = normalize_asset_id(value) }
            "annotationtext" => if annotation.is_empty() { annotation = value }
            "hash" => if hash.is_empty() { hash = value }
            "size" => if size.is_empty() { size = value }
            "type" => if raw_type.is_empty() { raw_type = value }
            _ => ()
          }
        }
      CloseTag(name) => {
        let tag = tag_key(name)
        if in_asset && tag == "asset" && depth == 1 {
          assets.push({
            id,
            path: "",
            kind: kind_from_pkl_type(raw_type),
            hash,
            size,
            annotation,
            edit_rate: "",
            intrinsic_duration: "",
          })
          in_asset = false
          depth = 0
        } else if in_asset {
          depth -= 1
        }
        ignore(stack.pop())
      }
    }
  }
  if assets.length() == 0 {
    Err(MissingElement("PackingList/AssetList/Asset"))
  } else {
    Ok(assets)
  }
}

///|
pub fn parse_composition_playlist(
  raw : String,
) -> Result[DcpComposition, DcpParseError] {
  let tokens = match tokenize_dcp_xml(raw) {
    Ok(tokens) => tokens
    Err(error) => return Err(error)
  }
  let assets : Array[DcpAsset] = []
  let stack : Array[String] = []
  let mut composition_id = ""
  let mut composition_annotation = ""
  let mut in_role = false
  let mut role_depth = 0
  let mut role = ""
  let mut asset_id = ""
  let mut annotation = ""
  let mut edit_rate = ""
  let mut intrinsic_duration = ""
  for token in tokens {
    match token {
      OpenTag(name, _) => {
        let tag = tag_key(name)
        stack.push(tag)
        if is_cpl_asset_role(tag) && !in_role {
          in_role = true
          role_depth = 1
          role = tag
          asset_id = ""
          annotation = ""
          edit_rate = ""
          intrinsic_duration = ""
        } else if in_role {
          role_depth += 1
        }
      }
      SelfCloseTag(_, _) => ()
      Text(text) => {
        let value = text.trim().to_owned()
        if in_role {
          match current_tag(stack) {
            "id" =>
              if asset_id.is_empty() {
                asset_id = normalize_asset_id(value)
              }
            "annotationtext" => if annotation.is_empty() { annotation = value }
            "editrate" => if edit_rate.is_empty() { edit_rate = value }
            "intrinsicduration" =>
              if intrinsic_duration.is_empty() {
                intrinsic_duration = value
              }
            _ => ()
          }
        } else {
          match current_tag(stack) {
            "id" =>
              if composition_id.is_empty() {
                composition_id = normalize_asset_id(value)
              }
            "annotationtext" =>
              if composition_annotation.is_empty() {
                composition_annotation = value
              }
            _ => ()
          }
        }
      }
      CloseTag(name) => {
        let tag = tag_key(name)
        if in_role && tag == role && role_depth == 1 {
          assets.push({
            id: asset_id,
            path: "",
            kind: kind_from_cpl_role(role),
            hash: "",
            size: "",
            annotation,
            edit_rate,
            intrinsic_duration,
          })
          in_role = false
          role_depth = 0
        } else if in_role {
          role_depth -= 1
        }
        ignore(stack.pop())
      }
    }
  }
  if composition_id.is_empty() && assets.length() == 0 {
    Err(MissingElement("CompositionPlaylist"))
  } else {
    Ok({ id: composition_id, annotation: composition_annotation, assets })
  }
}

///|
fn has_asset_id(assets : Array[DcpAsset], id : String) -> Bool {
  if id.is_empty() {
    return false
  }
  for asset in assets {
    if asset.id == id {
      return true
    }
  }
  false
}

///|
fn push_duplicate_id_issues(
  issues : Array[DcpIssue],
  assets : Array[DcpAsset],
  source : String,
) -> Unit {
  for i in 0..<assets.length() {
    if assets[i].id.is_empty() {
      issues.push(
        issue(DcpError, "DCP101", None, "\{source} asset is missing Id"),
      )
      continue
    }
    for j in (i + 1)..<assets.length() {
      if assets[i].id == assets[j].id {
        issues.push(
          issue(
            DcpError,
            "DCP102",
            Some(assets[i].id),
            "duplicate \{source} asset id",
          ),
        )
      }
    }
  }
}

///|
pub fn check_dcp_package(pkg : DcpPackage) -> Array[DcpIssue] {
  let issues : Array[DcpIssue] = []
  if pkg.asset_map.length() == 0 {
    issues.push(issue(DcpError, "DCP001", None, "AssetMap has no assets"))
  }
  if pkg.packing_list.length() == 0 {
    issues.push(issue(DcpError, "DCP002", None, "PackingList has no assets"))
  }
  push_duplicate_id_issues(issues, pkg.asset_map, "AssetMap")
  push_duplicate_id_issues(issues, pkg.packing_list, "PackingList")
  for asset in pkg.packing_list {
    if !has_asset_id(pkg.asset_map, asset.id) {
      issues.push(
        issue(
          DcpError,
          "DCP201",
          Some(asset.id),
          "PackingList asset is not present in AssetMap",
        ),
      )
    }
    if asset.hash.is_empty() {
      issues.push(
        issue(
          DcpWarning,
          "DCP301",
          Some(asset.id),
          "PackingList asset has no hash",
        ),
      )
    }
    if asset.size.is_empty() {
      issues.push(
        issue(
          DcpWarning,
          "DCP302",
          Some(asset.id),
          "PackingList asset has no size",
        ),
      )
    }
  }
  match pkg.composition {
    Some(composition) => {
      for asset in composition.assets {
        if !has_asset_id(pkg.packing_list, asset.id) {
          issues.push(
            issue(
              DcpError,
              "DCP401",
              Some(asset.id),
              "CPL referenced asset is not present in PackingList",
            ),
          )
        }
      }
      if composition.subtitle_asset_count() == 0 {
        issues.push(
          issue(
            DcpWarning,
            "DCP501",
            Some(composition.id),
            "CPL has no subtitle or caption assets",
          ),
        )
      }
    }
    None => ()
  }
  issues
}

///|
pub fn has_dcp_errors(issues : Array[DcpIssue]) -> Bool {
  for issue in issues {
    if issue.severity == DcpError {
      return true
    }
  }
  false
}
