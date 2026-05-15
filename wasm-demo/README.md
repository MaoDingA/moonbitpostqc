# MoonPost Wasm Demo

Browser-local subtitle QC demo for MoonPost. It loads the MoonBit
`wasm-gc` build, parses SRT/WebVTT text in the browser, and returns a QC
report without uploading the subtitle file.

## Build

```bash
./wasm-demo/build.sh
```

## Serve

```bash
python3 -m http.server 8765 --directory wasm-demo/public
```

Then open:

```text
http://localhost:8765
```

The demo expects a browser with WebAssembly GC and JS string builtins support.
