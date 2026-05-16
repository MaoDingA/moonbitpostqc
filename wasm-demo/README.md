# MoonPost Wasm Demo

Browser-local Delivery subtitle QC demo for MoonPost. It uses the shared QC
core and runs entirely in the browser.

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
