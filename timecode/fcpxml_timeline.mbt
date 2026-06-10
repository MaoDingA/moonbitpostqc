///|
/// Describes a media resource in an FCPXML `<resources>` section.
pub(all) struct FcpxmlResource {
  /// Resource identifier (e.g. "r1").
  id : String
  /// Display name of the format or asset.
  name : String
  /// Frame duration as a rational seconds string (e.g. "100/2500s"),
  /// or empty if not applicable (e.g. for assets).
  frame_duration : String
  /// Video width in pixels (0 if not a format resource).
  width : Int
  /// Video height in pixels (0 if not a format resource).
  height : Int
  /// Source file URI for asset resources, or empty.
  src : String
} derive(Eq, Debug)

///|
/// An asset-clip or title clip on the FCPXML timeline spine.
pub(all) struct FcpxmlClip {
  /// Clip name.
  name : String
  /// Resource reference ID (e.g. "r2").
  ref_id : String
  /// Offset from timeline start as rational seconds.
  offset : RationalSeconds
  /// Clip duration as rational seconds.
  duration : RationalSeconds
  /// Source media start time as rational seconds.
  start : RationalSeconds
} derive(Eq, Debug)

///|
/// A gap placeholder on the FCPXML timeline spine.
pub(all) struct FcpxmlGap {
  /// Gap name (usually "Gap").
  name : String
  /// Offset from timeline start as rational seconds.
  offset : RationalSeconds
  /// Gap duration as rational seconds.
  duration : RationalSeconds
} derive(Eq, Debug)

///|
/// An ordered item on the FCPXML timeline spine.
pub(all) enum FcpxmlTimelineItem {
  Clip(FcpxmlClip)
  Gap(FcpxmlGap)
} derive(Eq, Debug)

///|
/// A parsed FCPXML timeline with resources and ordered spine items.
pub(all) struct FcpxmlTimeline {
  /// Referenced format resource ID (e.g. "r1").
  format_id : String
  /// Timeline start time as rational seconds.
  tc_start : RationalSeconds
  /// Timecode format flag.
  tc_format : FcpXmlTcFormat
  /// Total sequence duration as rational seconds.
  duration : RationalSeconds
  /// All resources found in the `<resources>` section.
  resources : Array[FcpxmlResource]
  /// Ordered spine items (clips and gaps).
  items : Array[FcpxmlTimelineItem]
} derive(Eq, Debug)

///|
/// Describes why an FCPXML timeline could not be parsed.
pub(all) enum FcpxmlParseError {
  /// XML tokenization failed.
  XmlError(XmlError)
  /// Required element was not found (e.g. missing `<sequence>`).
  MissingElement(String)
  /// A required attribute is missing or empty.
  MissingAttribute(String, String)
  /// A rational-seconds attribute value could not be parsed.
  InvalidRationalSeconds(String)
} derive(Eq, Debug)

///|
/// A zero-value rational seconds constant.
fn zero_seconds() -> RationalSeconds {
  { numerator: 0L, denominator: 1L }
}

///|
/// Parses a required rational-seconds attribute, returning an error if the
/// attribute is absent or malformed.
fn require_rational(
  attrs : Array[XmlAttr],
  attr_name : String,
  context : String,
) -> Result[RationalSeconds, FcpxmlParseError] {
  match xml_attr(attrs, attr_name) {
    Some(raw) =>
      match RationalSeconds::parse(raw) {
        Some(value) => Ok(value)
        None => Err(InvalidRationalSeconds("\{context}@\{attr_name}=\{raw}"))
      }
    None => Err(MissingAttribute(context, attr_name))
  }
}

///|
/// Parses an optional rational-seconds attribute, returning `None` if the
/// attribute is absent.
fn optional_rational(
  attrs : Array[XmlAttr],
  attr_name : String,
) -> Result[RationalSeconds?, FcpxmlParseError] {
  match xml_attr(attrs, attr_name) {
    Some(raw) =>
      match RationalSeconds::parse(raw) {
        Some(value) => Ok(Some(value))
        None => Err(InvalidRationalSeconds("\{attr_name}=\{raw}"))
      }
    None => Ok(None)
  }
}

///|
/// Parses a required string attribute, returning an error if absent or empty.
fn require_string(
  attrs : Array[XmlAttr],
  attr_name : String,
  context : String,
) -> Result[String, FcpxmlParseError] {
  match xml_attr(attrs, attr_name) {
    Some(value) if !value.is_empty() => Ok(value)
    Some(_) => Err(MissingAttribute(context, attr_name))
    None => Err(MissingAttribute(context, attr_name))
  }
}

///|
/// Parses an integer attribute, returning `default_val` if absent or
/// unparseable.
fn int_attr_or(attrs : Array[XmlAttr], name : String, default_val : Int) -> Int {
  match xml_attr(attrs, name) {
    Some(raw) =>
      match parse_int(raw) {
        Some(value) => value
        None => default_val
      }
    None => default_val
  }
}

///|
/// Parses a tcFormat attribute into `FcpXmlTcFormat`.
fn parse_tc_format(
  attrs : Array[XmlAttr],
) -> Result[FcpXmlTcFormat, FcpxmlParseError] {
  match xml_attr(attrs, "tcFormat") {
    Some("DF") => Ok(DF)
    Some(_) => Ok(NDF)
    None => Ok(NDF)
  }
}

///|
/// Collects all `<format>` and `<asset>` elements from the `<resources>`
/// section using the cursor, returning when `</resources>` is reached.
fn parse_resources(cursor : XmlCursor) -> Array[FcpxmlResource] {
  let resources : Array[FcpxmlResource] = []
  while cursor.has_next() {
    match cursor.peek() {
      Some(SelfCloseTag("format", attrs)) => {
        ignore(cursor.advance())
        resources.push({
          id: xml_attr(attrs, "id").unwrap_or(""),
          name: xml_attr(attrs, "name").unwrap_or(""),
          frame_duration: xml_attr(attrs, "frameDuration").unwrap_or(""),
          width: int_attr_or(attrs, "width", 0),
          height: int_attr_or(attrs, "height", 0),
          src: "",
        })
      }
      Some(OpenTag("asset", attrs)) => {
        let id = xml_attr(attrs, "id").unwrap_or("")
        let name = xml_attr(attrs, "name").unwrap_or("")
        let src = xml_attr(attrs, "src").unwrap_or("")
        cursor.skip_element()
        resources.push({
          id,
          name,
          frame_duration: "",
          width: 0,
          height: 0,
          src,
        })
      }
      Some(CloseTag("resources")) => {
        ignore(cursor.advance())
        return resources
      }
      Some(_) => ignore(cursor.advance())
      None => return resources
    }
  }
  resources
}

///|
/// Parses `<spine>` children (`asset-clip`, `gap`, `title`) into timeline
/// items.
fn parse_spine_items(cursor : XmlCursor) -> Array[FcpxmlTimelineItem] {
  let items : Array[FcpxmlTimelineItem] = []
  while cursor.has_next() {
    match cursor.peek() {
      Some(SelfCloseTag("asset-clip", attrs)) => {
        ignore(cursor.advance())
        let name = xml_attr(attrs, "name").unwrap_or("")
        let ref_id = xml_attr(attrs, "ref").unwrap_or("")
        let offset = match require_rational(attrs, "offset", "asset-clip") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let duration = match require_rational(attrs, "duration", "asset-clip") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let start = match optional_rational(attrs, "start") {
          Ok(Some(v)) => v
          _ => zero_seconds()
        }
        items.push(Clip({ name, ref_id, offset, duration, start }))
      }
      Some(SelfCloseTag("title-clip", attrs)) => {
        ignore(cursor.advance())
        let name = xml_attr(attrs, "name").unwrap_or("")
        let ref_id = ""
        let offset = match require_rational(attrs, "offset", "title-clip") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let duration = match require_rational(attrs, "duration", "title-clip") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let start = zero_seconds()
        items.push(Clip({ name, ref_id, offset, duration, start }))
      }
      Some(SelfCloseTag("gap", attrs)) => {
        ignore(cursor.advance())
        let name = xml_attr(attrs, "name").unwrap_or("Gap")
        let offset = match require_rational(attrs, "offset", "gap") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let duration = match require_rational(attrs, "duration", "gap") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        items.push(Gap({ name, offset, duration }))
      }
      // Handle non-self-closing variants (e.g. <asset-clip> ... </asset-clip>)
      Some(OpenTag("asset-clip", attrs)) => {
        ignore(cursor.advance())
        let name = xml_attr(attrs, "name").unwrap_or("")
        let ref_id = xml_attr(attrs, "ref").unwrap_or("")
        let offset = match require_rational(attrs, "offset", "asset-clip") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let duration = match require_rational(attrs, "duration", "asset-clip") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let start = match optional_rational(attrs, "start") {
          Ok(Some(v)) => v
          _ => zero_seconds()
        }
        cursor.skip_element()
        items.push(Clip({ name, ref_id, offset, duration, start }))
      }
      Some(OpenTag("gap", attrs)) => {
        ignore(cursor.advance())
        let name = xml_attr(attrs, "name").unwrap_or("Gap")
        let offset = match require_rational(attrs, "offset", "gap") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        let duration = match require_rational(attrs, "duration", "gap") {
          Ok(v) => v
          Err(_) => zero_seconds()
        }
        cursor.skip_element()
        items.push(Gap({ name, offset, duration }))
      }
      Some(CloseTag("spine")) => {
        ignore(cursor.advance())
        return items
      }
      Some(_) => ignore(cursor.advance())
      None => return items
    }
  }
  items
}

///|
/// Parses an FCPXML string into a structured timeline.
///
/// Extracts the first `<sequence>` element, its referenced resources, and
/// the ordered clips and gaps on the spine. Returns a `FcpxmlTimeline` with
/// frame-level timing information.
pub fn parse_fcpxml_timeline(
  raw : String,
) -> Result[FcpxmlTimeline, FcpxmlParseError] {
  let tokens = match tokenize_xml(raw) {
    Ok(tokens) => tokens
    Err(error) => return Err(XmlError(error))
  }
  let cursor = XmlCursor::new(tokens)
  // Skip to <fcpxml> root if present.
  match cursor.find_tag("fcpxml") {
    Some(_) => ()
    None => ()
  }
  // Parse <resources> section.
  let resources = match cursor.find_tag("resources") {
    Some(_) => parse_resources(cursor)
    None => []
  }
  // Find <sequence>.
  let seq_attrs = match cursor.find_tag("sequence") {
    Some(attrs) => attrs
    None => return Err(MissingElement("sequence"))
  }
  let format_id = match require_string(seq_attrs, "format", "sequence") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let tc_start = match require_rational(seq_attrs, "tcStart", "sequence") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let tc_format = match parse_tc_format(seq_attrs) {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  let duration = match require_rational(seq_attrs, "duration", "sequence") {
    Ok(v) => v
    Err(e) => return Err(e)
  }
  // Find <spine>.
  let _spine_attrs = match cursor.find_tag("spine") {
    Some(attrs) => attrs
    None => return Err(MissingElement("spine"))
  }
  let items = parse_spine_items(cursor)
  Ok({ format_id, tc_start, tc_format, duration, resources, items })
}

///|
/// Returns the total number of clips on the timeline spine.
pub fn FcpxmlTimeline::clip_count(self : FcpxmlTimeline) -> Int {
  let mut count = 0
  for item in self.items {
    match item {
      Clip(_) => count += 1
      Gap(_) => ()
    }
  }
  count
}

///|
/// Returns the total number of gaps on the timeline spine.
pub fn FcpxmlTimeline::gap_count(self : FcpxmlTimeline) -> Int {
  let mut count = 0
  for item in self.items {
    match item {
      Clip(_) => ()
      Gap(_) => count += 1
    }
  }
  count
}

///|
/// Looks up a resource by its ID.
pub fn FcpxmlTimeline::resource_by_id(
  self : FcpxmlTimeline,
  id : String,
) -> FcpxmlResource? {
  let mut i = 0
  while i < self.resources.length() {
    if self.resources[i].id == id {
      return Some(self.resources[i])
    }
    i += 1
  }
  None
}

///|
/// Returns the frame duration rational seconds from the format resource
/// referenced by this timeline, or `None` if the format is not found.
pub fn FcpxmlTimeline::format_frame_duration(
  self : FcpxmlTimeline,
) -> RationalSeconds? {
  match self.resource_by_id(self.format_id) {
    Some(resource) if !resource.frame_duration.is_empty() =>
      RationalSeconds::parse(resource.frame_duration)
    _ => None
  }
}
