///|
/// An XML attribute name-value pair.
pub(all) struct XmlAttr {
  name : String
  value : String
} derive(Eq, Debug)

///|
/// A single XML token produced by the lightweight tokenizer.
pub(all) enum XmlToken {
  /// `<name attrs...>`
  OpenTag(String, Array[XmlAttr])
  /// `</name>`
  CloseTag(String)
  /// `<name attrs... />`
  SelfCloseTag(String, Array[XmlAttr])
  /// Text content between tags.
  Text(String)
} derive(Eq, Debug)

///|
/// Describes why XML tokenization failed.
pub(all) enum XmlError {
  /// Unexpected end of input.
  UnexpectedEof
  /// Malformed tag at the given byte offset.
  MalformedTag(Int)
  /// Unterminated string literal at the given byte offset.
  UnterminatedString(Int)
} derive(Eq, Debug)

///|
/// Unescapes common XML entities in an attribute value.
fn xml_unescape(raw : String) -> String {
  raw
    .replace_all(old="&amp;", new="&")
    .replace_all(old="&lt;", new="<")
    .replace_all(old="&gt;", new=">")
    .replace_all(old="&quot;", new="\"")
    .replace_all(old="&apos;", new="'")
}

///|
/// Returns true for XML name start characters.
fn is_name_start(c : UInt16) -> Bool {
  c == '_' || (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z')
}

///|
/// Returns true for XML name characters (start + digits + hyphens + dots).
fn is_name_char(c : UInt16) -> Bool {
  is_name_start(c) || (c >= '0' && c <= '9') || c == '-' || c == '.'
}

///|
/// Returns true for whitespace characters.
fn is_whitespace(c : UInt16) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

///|
/// Reads characters while `pred` holds, returning the consumed slice.
fn take_while(src : String, start : Int, pred : (UInt16) -> Bool) -> String {
  let mut i = start
  while i < src.length() && pred(src[i]) {
    i += 1
  }
  src[start:i].to_owned()
}

///|
/// Parses a double-quoted attribute value starting after the opening `"`.
/// Returns (value, position_after_closing_quote).
fn parse_attr_value(src : String, start : Int) -> Result[(String, Int), XmlError] {
  let mut i = start
  let parts : Array[String] = []
  let mut seg_start = i
  while i < src.length() {
    let c = src[i]
    if c == '"' {
      if seg_start < i {
        parts.push(src[seg_start:i].to_owned())
      }
      return Ok((xml_unescape(parts.join("")), i + 1))
    }
    if c == '&' {
      if seg_start < i {
        parts.push(src[seg_start:i].to_owned())
      }
      // Parse entity reference.
      let mut entity_end = i + 1
      while entity_end < src.length() && src[entity_end] != ';' {
        entity_end += 1
      }
      if entity_end >= src.length() {
        return Err(UnterminatedString(i))
      }
      parts.push(xml_unescape(src[i:entity_end + 1].to_owned()))
      i = entity_end + 1
      seg_start = i
    } else {
      i += 1
    }
  }
  Err(UnterminatedString(start))
}

///|
/// Parses attributes from the portion of a tag between the tag name and
/// `>` or `/>`. Returns (attributes, position_after_tag, is_self_closing).
fn parse_attributes(
  src : String,
  start : Int,
) -> Result[(Array[XmlAttr], Int, Bool), XmlError] {
  let mut i = start
  let attrs : Array[XmlAttr] = []
  while i < src.length() {
    // Skip whitespace.
    while i < src.length() && is_whitespace(src[i]) {
      i += 1
    }
    if i >= src.length() {
      return Err(UnexpectedEof)
    }
    // Check for end of tag.
    if src[i] == '>' {
      return Ok((attrs, i + 1, false))
    }
    if i + 1 < src.length() && src[i] == '/' && src[i + 1] == '>' {
      return Ok((attrs, i + 2, true))
    }
    // Read attribute name.
    if !is_name_start(src[i]) {
      return Err(MalformedTag(i))
    }
    let name = take_while(src, i, fn(c) { is_name_char(c) })
    i += name.length()
    // Skip whitespace before =.
    while i < src.length() && is_whitespace(src[i]) {
      i += 1
    }
    if i >= src.length() || src[i] != '=' {
      return Err(MalformedTag(i))
    }
    i += 1
    // Skip whitespace after =.
    while i < src.length() && is_whitespace(src[i]) {
      i += 1
    }
    if i >= src.length() || src[i] != '"' {
      return Err(MalformedTag(i))
    }
    i += 1
    match parse_attr_value(src, i) {
      Ok((value, next)) => {
        attrs.push({ name, value })
        i = next
      }
      Err(error) => return Err(error)
    }
  }
  Err(UnexpectedEof)
}

///|
/// Tokenizes an XML string into a flat array of tokens.
///
/// Handles opening tags, closing tags, self-closing tags, and text content.
/// Skips XML declarations (`<? ...?>`), comments (`<!-- -->`), and DOCTYPE
/// declarations. This is sufficient for well-structured formats such as
/// FCPXML.
pub fn tokenize_xml(raw : String) -> Result[Array[XmlToken], XmlError] {
  let tokens : Array[XmlToken] = []
  let mut i = 0
  let mut text_start = 0
  while i < raw.length() {
    if raw[i] == '<' {
      // Flush accumulated text.
      if text_start < i {
        let text = raw[text_start:i].to_owned()
        let trimmed = text.trim().to_owned()
        if !trimmed.is_empty() {
          tokens.push(Text(trimmed))
        }
      }
      // XML declaration or PI: <? ... ?>
      if i + 1 < raw.length() && raw[i + 1] == '?' {
        let mut end = i + 2
        while end + 1 < raw.length() &&
          !(raw[end] == '?' && raw[end + 1] == '>') {
          end += 1
        }
        if end + 1 >= raw.length() {
          return Err(UnexpectedEof)
        }
        i = end + 2
        text_start = i
        continue
      }
      // Comment: <!-- ... -->
      if i + 3 < raw.length() &&
        raw[i + 1] == '!' &&
        raw[i + 2] == '-' &&
        raw[i + 3] == '-' {
        let mut end = i + 4
        while end + 2 < raw.length() &&
          !(raw[end] == '-' && raw[end + 1] == '-' && raw[end + 2] == '>') {
          end += 1
        }
        if end + 2 >= raw.length() {
          return Err(UnexpectedEof)
        }
        i = end + 3
        text_start = i
        continue
      }
      // DOCTYPE: <! ... >
      if i + 1 < raw.length() && raw[i + 1] == '!' {
        let mut end = i + 2
        while end < raw.length() && raw[end] != '>' {
          end += 1
        }
        if end >= raw.length() {
          return Err(UnexpectedEof)
        }
        i = end + 1
        text_start = i
        continue
      }
      // Close tag: </name>
      if i + 1 < raw.length() && raw[i + 1] == '/' {
        let name_start = i + 2
        let mut j = name_start
        while j < raw.length() && is_whitespace(raw[j]) {
          j += 1
        }
        let name_start = j
        let name = take_while(raw, name_start, fn(c) { is_name_char(c) })
        let mut end = name_start + name.length()
        while end < raw.length() && raw[end] != '>' {
          end += 1
        }
        if end >= raw.length() {
          return Err(UnexpectedEof)
        }
        tokens.push(CloseTag(name))
        i = end + 1
        text_start = i
        continue
      }
      // Open or self-closing tag: <name attrs ...> or <name attrs .../>
      let name_start = i + 1
      let name = take_while(raw, name_start, fn(c) { is_name_char(c) })
      if name.is_empty() {
        return Err(MalformedTag(i))
      }
      let after_name = name_start + name.length()
      match parse_attributes(raw, after_name) {
        Ok((attrs, next, self_closing)) => {
          if self_closing {
            tokens.push(SelfCloseTag(name, attrs))
          } else {
            tokens.push(OpenTag(name, attrs))
          }
          i = next
          text_start = i
        }
        Err(error) => return Err(error)
      }
    } else {
      i += 1
    }
  }
  // Flush trailing text.
  if text_start < i {
    let text = raw[text_start:i].to_owned()
    let trimmed = text.trim().to_owned()
    if !trimmed.is_empty() {
      tokens.push(Text(trimmed))
    }
  }
  Ok(tokens)
}

///|
/// Finds the first attribute with the given name in the list.
pub fn xml_attr(attrs : Array[XmlAttr], name : String) -> String? {
  let mut i = 0
  while i < attrs.length() {
    if attrs[i].name == name {
      return Some(attrs[i].value)
    }
    i += 1
  }
  None
}

///|
/// A position-based cursor for navigating a flat XML token array.
struct XmlCursor {
  tokens : Array[XmlToken]
  mut pos : Int
} derive(Debug)

///|
fn XmlCursor::new(tokens : Array[XmlToken]) -> XmlCursor {
  { tokens, pos: 0 }
}

///|
fn XmlCursor::has_next(self : XmlCursor) -> Bool {
  self.pos < self.tokens.length()
}

///|
fn XmlCursor::peek(self : XmlCursor) -> XmlToken? {
  if self.pos < self.tokens.length() {
    Some(self.tokens[self.pos])
  } else {
    None
  }
}

///|
fn XmlCursor::advance(self : XmlCursor) -> XmlToken? {
  if self.pos < self.tokens.length() {
    let token = self.tokens[self.pos]
    self.pos += 1
    Some(token)
  } else {
    None
  }
}

///|
/// Advances past an open tag and all its children until the matching close
/// tag, positioning the cursor just past the close tag.
fn XmlCursor::skip_element(self : XmlCursor) -> Unit {
  let mut depth = 0
  while self.has_next() {
    match self.advance() {
      Some(OpenTag(_, _)) => depth += 1
      Some(CloseTag(_)) => {
        if depth == 0 {
          return ()
        }
        depth -= 1
      }
      _ => ()
    }
  }
}

///|
/// Finds the next open or self-closing tag with the given name, advancing
/// the cursor. Returns the attributes if found.
fn XmlCursor::find_tag(self : XmlCursor, name : String) -> Array[XmlAttr]? {
  while self.has_next() {
    match self.peek() {
      Some(OpenTag(tag_name, attrs)) if tag_name == name => {
        ignore(self.advance())
        return Some(attrs)
      }
      Some(SelfCloseTag(tag_name, attrs)) if tag_name == name => {
        ignore(self.advance())
        return Some(attrs)
      }
      Some(_) => ignore(self.advance())
      None => return None
    }
  }
  None
}
