///|
test "tokenize_xml parses simple open and close tags" {
  let raw = "<root><child>text</child></root>"
  match tokenize_xml(raw) {
    Ok(tokens) => {
      assert_eq(tokens.length(), 5)
      match tokens[0] {
        OpenTag(name, attrs) => {
          assert_eq(name, "root")
          assert_eq(attrs.length(), 0)
        }
        _ => fail("expected OpenTag(root)")
      }
      match tokens[1] {
        OpenTag(name, attrs) => {
          assert_eq(name, "child")
          assert_eq(attrs.length(), 0)
        }
        _ => fail("expected OpenTag(child)")
      }
      match tokens[2] {
        Text(content) => assert_eq(content, "text")
        _ => fail("expected Text")
      }
      match tokens[3] {
        CloseTag(name) => assert_eq(name, "child")
        _ => fail("expected CloseTag(child)")
      }
      match tokens[4] {
        CloseTag(name) => assert_eq(name, "root")
        _ => fail("expected CloseTag(root)")
      }
    }
    Err(_) => fail("expected tokenized XML")
  }
}

///|
test "tokenize_xml parses self-closing tags" {
  let raw = "<root><item name=\"test\"/></root>"
  match tokenize_xml(raw) {
    Ok(tokens) => {
      assert_eq(tokens.length(), 3)
      match tokens[1] {
        SelfCloseTag(name, attrs) => {
          assert_eq(name, "item")
          assert_eq(attrs.length(), 1)
          assert_eq(attrs[0].name, "name")
          assert_eq(attrs[0].value, "test")
        }
        _ => fail("expected SelfCloseTag(item)")
      }
    }
    Err(_) => fail("expected tokenized XML")
  }
}

///|
test "tokenize_xml parses attributes with entity references" {
  let raw = "<tag val=\"a&amp;b\"/>"
  match tokenize_xml(raw) {
    Ok(tokens) => {
      assert_eq(tokens.length(), 1)
      match tokens[0] {
        SelfCloseTag(_, attrs) => {
          assert_eq(attrs[0].value, "a&b")
        }
        _ => fail("expected SelfCloseTag")
      }
    }
    Err(_) => fail("expected tokenized XML")
  }
}

///|
test "tokenize_xml skips XML declaration and comments" {
  let raw =
    #|<?xml version="1.0" encoding="UTF-8"?>
    #|<!-- This is a comment -->
    #|<root><child/></root>
  match tokenize_xml(raw) {
    Ok(tokens) => {
      // Should only have root open, child self-close, root close
      assert_eq(tokens.length(), 3)
      match tokens[0] {
        OpenTag(name, _) => assert_eq(name, "root")
        _ => fail("expected OpenTag(root)")
      }
    }
    Err(_) => fail("expected tokenized XML with skips")
  }
}

///|
test "tokenize_xml skips DOCTYPE declarations" {
  let raw = "<!DOCTYPE fcpxml><root/>"
  match tokenize_xml(raw) {
    Ok(tokens) => {
      assert_eq(tokens.length(), 1)
      match tokens[0] {
        SelfCloseTag(name, _) => assert_eq(name, "root")
        _ => fail("expected SelfCloseTag(root)")
      }
    }
    Err(_) => fail("expected tokenized XML")
  }
}

///|
test "tokenize_xml handles FCPXML-like content" {
  let raw =
    #|<fcpxml version="1.9">
    #|  <resources>
    #|    <format id="r1" name="FFVideoFormat1080p25" frameDuration="100/2500s"/>
    #|  </resources>
    #|  <library>
    #|    <event name="My Event">
    #|      <project name="My Project">
    #|        <sequence format="r1" tcStart="0s" tcFormat="NDF">
    #|          <spine>
    #|            <asset-clip name="Clip" ref="r2" offset="0s" duration="100/2500s" start="0s"/>
    #|          </spine>
    #|        </sequence>
    #|      </project>
    #|    </event>
    #|  </library>
    #|</fcpxml>
  match tokenize_xml(raw) {
    Ok(tokens) => {
      // Verify we can find key tokens
      let mut has_sequence = false
      let mut has_clip = false
      for token in tokens {
        match token {
          OpenTag("sequence", _) => has_sequence = true
          SelfCloseTag("asset-clip", _) => has_clip = true
          _ => ()
        }
      }
      assert_true(has_sequence)
      assert_true(has_clip)
    }
    Err(_) => fail("expected tokenized FCPXML")
  }
}

///|
test "xml_attr finds attribute by name" {
  let attrs = [
    { name: "id", value: "r1" },
    { name: "name", value: "test" },
    { name: "duration", value: "100s" },
  ]
  assert_true(xml_attr(attrs, "name") == Some("test"))
  assert_true(xml_attr(attrs, "missing") == None)
}

///|
test "tokenize_xml returns error on unclosed tag" {
  let raw = "<root><unclosed"
  match tokenize_xml(raw) {
    Err(UnexpectedEof) => ()
    Ok(_) => fail("expected error for unclosed tag")
    Err(_) => ()
  }
}
