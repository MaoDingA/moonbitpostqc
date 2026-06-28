///|
let sample_asset_map =
  #|<?xml version="1.0" encoding="UTF-8"?>
  #|<AssetMap xmlns="http://www.smpte-ra.org/schemas/429-9/2007/AM">
  #|  <AssetList>
  #|    <Asset>
  #|      <Id>urn:uuid:cpl-1</Id>
  #|      <ChunkList><Chunk><Path>CPL_main.xml</Path></Chunk></ChunkList>
  #|    </Asset>
  #|    <Asset>
  #|      <Id>urn:uuid:sub-1</Id>
  #|      <ChunkList><Chunk><Path>subtitles/subtitle_zh.mxf</Path></Chunk></ChunkList>
  #|    </Asset>
  #|  </AssetList>
  #|</AssetMap>

///|
let sample_pkl =
  #|<?xml version="1.0" encoding="UTF-8"?>
  #|<PackingList xmlns="http://www.smpte-ra.org/schemas/429-8/2007/PKL" xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
  #|  <AssetList>
  #|    <Asset>
  #|      <Id>urn:uuid:cpl-1</Id>
  #|      <AnnotationText>Main CPL</AnnotationText>
  #|      <Hash>abc</Hash>
  #|      <Size>123</Size>
  #|      <Type>text/xml;asdcpKind=CPL</Type>
  #|    </Asset>
  #|    <Asset>
  #|      <Id>urn:uuid:sub-1</Id>
  #|      <AnnotationText>Chinese subtitle</AnnotationText>
  #|      <Hash>def</Hash>
  #|      <Size>456</Size>
  #|      <Type>application/mxf;asdcpKind=Subtitle</Type>
  #|    </Asset>
  #|  </AssetList>
  #|  <dsig:Signature><dsig:SignedInfo /></dsig:Signature>
  #|</PackingList>

///|
let sample_cpl =
  #|<?xml version="1.0" encoding="UTF-8"?>
  #|<CompositionPlaylist xmlns="http://www.smpte-ra.org/schemas/429-7/2006/CPL">
  #|  <Id>urn:uuid:cpl-1</Id>
  #|  <AnnotationText>Feature Reel</AnnotationText>
  #|  <ReelList>
  #|    <Reel>
  #|      <AssetList>
  #|        <MainPicture>
  #|          <Id>urn:uuid:pic-1</Id>
  #|          <EditRate>24 1</EditRate>
  #|          <IntrinsicDuration>240</IntrinsicDuration>
  #|        </MainPicture>
  #|        <MainSubtitle>
  #|          <Id>urn:uuid:sub-1</Id>
  #|          <AnnotationText>Chinese subtitle</AnnotationText>
  #|          <EditRate>24 1</EditRate>
  #|          <IntrinsicDuration>240</IntrinsicDuration>
  #|        </MainSubtitle>
  #|      </AssetList>
  #|    </Reel>
  #|  </ReelList>
  #|</CompositionPlaylist>

///|
test "parse AssetMap assets" {
  match parse_asset_map(sample_asset_map) {
    Ok(assets) => {
      assert_eq(assets.length(), 2)
      assert_eq(assets[0].id, "cpl-1")
      assert_true(assets[0].kind == CompositionPlaylistAsset)
      assert_eq(assets[1].path, "subtitles/subtitle_zh.mxf")
      assert_true(assets[1].is_subtitle())
    }
    Err(_) => fail("expected parsed AssetMap")
  }
}

///|
test "parse PackingList assets with namespace prefixes" {
  match parse_packing_list(sample_pkl) {
    Ok(assets) => {
      assert_eq(assets.length(), 2)
      assert_true(assets[0].kind == CompositionPlaylistAsset)
      assert_eq(assets[0].hash, "abc")
      assert_true(assets[1].kind == SubtitleAsset)
      assert_eq(assets[1].size, "456")
    }
    Err(_) => fail("expected parsed PKL")
  }
}

///|
test "parse CPL referenced assets" {
  match parse_composition_playlist(sample_cpl) {
    Ok(cpl) => {
      assert_eq(cpl.id, "cpl-1")
      assert_eq(cpl.annotation, "Feature Reel")
      assert_eq(cpl.asset_count(), 2)
      assert_eq(cpl.subtitle_asset_count(), 1)
      assert_eq(cpl.assets[1].edit_rate, "24 1")
      assert_eq(cpl.assets[1].intrinsic_duration, "240")
    }
    Err(_) => fail("expected parsed CPL")
  }
}

///|
test "check DCP package detects missing CPL references" {
  let asset_map = match parse_asset_map(sample_asset_map) {
    Ok(assets) => {
      let all = assets
      all.push({
        id: "pic-1",
        path: "picture/main_picture.mxf",
        kind: PictureAsset,
        hash: "",
        size: "",
        annotation: "",
        edit_rate: "",
        intrinsic_duration: "",
      })
      all
    }
    Err(_) => fail("expected AssetMap")
  }
  let packing_list = match parse_packing_list(sample_pkl) {
    Ok(assets) => assets
    Err(_) => fail("expected PKL")
  }
  let composition = match parse_composition_playlist(sample_cpl) {
    Ok(cpl) => cpl
    Err(_) => fail("expected CPL")
  }
  let issues = check_dcp_package({
    asset_map,
    packing_list,
    composition: Some(composition),
  })
  assert_true(has_dcp_errors(issues))
  assert_true(issues.any(fn(issue) { issue.code == "DCP401" }))
}

///|
test "check DCP package passes matching subtitle references" {
  let asset_map = match parse_asset_map(sample_asset_map) {
    Ok(assets) => {
      let all = assets
      all.push({
        id: "pic-1",
        path: "picture/main_picture.mxf",
        kind: PictureAsset,
        hash: "",
        size: "",
        annotation: "",
        edit_rate: "",
        intrinsic_duration: "",
      })
      all
    }
    Err(_) => fail("expected AssetMap")
  }
  let packing_list = match parse_packing_list(sample_pkl) {
    Ok(assets) => {
      let all = assets
      all.push({
        id: "pic-1",
        path: "",
        kind: PictureAsset,
        hash: "ghi",
        size: "789",
        annotation: "Picture",
        edit_rate: "",
        intrinsic_duration: "",
      })
      all
    }
    Err(_) => fail("expected PKL")
  }
  let composition = match parse_composition_playlist(sample_cpl) {
    Ok(cpl) => cpl
    Err(_) => fail("expected CPL")
  }
  let issues = check_dcp_package({
    asset_map,
    packing_list,
    composition: Some(composition),
  })
  assert_false(has_dcp_errors(issues))
}
