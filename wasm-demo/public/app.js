const samples = {
  creator: `1
00:00:01,000 --> 00:00:03,500
然后然后我们今天来介绍一下MoonPost

2
00:00:04,000 --> 00:00:07,000
这个工具就是就是用来检查字幕质量的

3
00:00:07,500 --> 00:00:10,000
[Music] 然后呢我们认真的做好每一步

4
00:00:10,500 --> 00:00:13,000
对吧对吧这个moonpost真的很好用

5
00:00:13,500 --> 00:00:16,000
它可以帮助我们登陆账号检查字幕
`,
  delivery: `1
00:00:01,123 --> 00:00:01,500
This line is intentionally far too long for a delivery profile and exceeds the maximum characters per line.

2
00:00:01,450 --> 00:00:04,000
Overlap with the previous cue.

3
00:00:04,500 --> 00:00:04,700

4
00:00:05,000 --> 00:00:10,000
This subtitle is way too long for a normal reading speed test and should trigger the CPS warning
`,
  qc: `1
00:00:01,123 --> 00:00:01,500
Short cue with very long text that exceeds the maximum characters per line limit for delivery.

2
00:00:01,450 --> 00:00:04,000
Overlap with the previous cue.

3
00:00:04,500 --> 00:00:04,700
Empty cue below minimum
`,
};

const profiles = {
  creator: [
    { value: "douyin", label: "抖音" },
    { value: "bilibili", label: "B站" },
    { value: "youtube", label: "YouTube" },
    { value: "bilingual", label: "双语" },
    { value: "xiaohongshu", label: "小红书" },
    { value: "kuaishou", label: "快手" },
    { value: "wechat", label: "视频号" },
    { value: "tiktok", label: "TikTok" },
  ],
  delivery: [
    { value: "ott-zh", label: "OTT 中文" },
    { value: "cinema-zh", label: "影院中文" },
    { value: "broadcast", label: "广播电视" },
    { value: "srt-basic", label: "SRT 基础" },
    { value: "dcp-source-srt", label: "DCP 源 SRT" },
    { value: "dcp-frame-strict", label: "DCP 帧严格" },
  ],
  qc: [
    { value: "default", label: "Default" },
    { value: "streaming", label: "Streaming" },
    { value: "cinema", label: "Cinema" },
    { value: "social-video", label: "Social video" },
  ],
};

const elements = {
  status: document.querySelector("#runtime-status"),
  input: document.querySelector("#subtitle-input"),
  output: document.querySelector("#report-output"),
  profile: document.querySelector("#profile-select"),
  fpsLabel: document.querySelector("#fps-label"),
  fps: document.querySelector("#fps-select"),
  summary: document.querySelector("#summary-label"),
  fileLabel: document.querySelector("#file-label"),
  fileInput: document.querySelector("#file-input"),
  dropZone: document.querySelector("#drop-zone"),
  runButton: document.querySelector("#run-button"),
  cleanButton: document.querySelector("#clean-button"),
  sampleButton: document.querySelector("#sample-button"),
  copyButton: document.querySelector("#copy-button"),
  downloadButton: document.querySelector("#download-button"),
};

let exports = null;
let lastReport = "";
let currentMode = "creator";

function setStatus(text, state = "") {
  elements.status.textContent = text;
  elements.status.className = `status ${state}`.trim();
}

function setReport(text) {
  lastReport = text;
  elements.output.textContent = text;
  elements.copyButton.disabled = text.length === 0;
  elements.downloadButton.disabled = text.length === 0;

  const summaryLine = text.split("\n").find((line) => line.startsWith("summary:"));
  elements.summary.textContent = summaryLine || "Report ready";
}

function updateProfileOptions() {
  const options = profiles[currentMode] || profiles.qc;
  elements.profile.innerHTML = "";
  for (const opt of options) {
    const el = document.createElement("option");
    el.value = opt.value;
    el.textContent = opt.label;
    elements.profile.appendChild(el);
  }
  elements.fpsLabel.style.display = currentMode === "delivery" ? "" : "none";
}

function switchMode(mode) {
  currentMode = mode;
  document.querySelectorAll(".tab").forEach((tab) => {
    tab.classList.toggle("active", tab.dataset.mode === mode);
  });
  updateProfileOptions();
  elements.input.value = samples[mode] || samples.qc;
  elements.fileLabel.textContent = "Sample subtitle";
  runQc();
}

async function loadWasm() {
  const compileOptions = {
    builtins: ["js-string"],
    importedStringConstants: "_",
  };
  const response = await fetch("./moonpost_qc.wasm");

  if ("instantiateStreaming" in WebAssembly) {
    try {
      const { instance } = await WebAssembly.instantiateStreaming(
        response.clone(),
        {},
        compileOptions,
      );
      return instance.exports;
    } catch {
      const bytes = await response.arrayBuffer();
      const { instance } = await WebAssembly.instantiate(
        bytes,
        {},
        compileOptions,
      );
      return instance.exports;
    }
  }

  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {}, compileOptions);
  return instance.exports;
}

function runQc() {
  if (!exports) {
    setReport("MoonPost Wasm runtime is not ready.");
    return;
  }

  const input = elements.input.value.trim();
  if (!input) {
    setReport(
      "uploaded subtitle\nsummary: 1 error, 0 warnings\n\nERROR E000 | subtitle text is empty",
    );
    return;
  }

  const profileName = elements.profile.value;
  const fps = elements.fps.value;

  let result;
  switch (currentMode) {
    case "creator":
      result = exports.creator_check(input, profileName);
      break;
    case "delivery":
      result = exports.delivery_check(input, profileName, fps || "0");
      break;
    default:
      result = exports.qc_subtitle(input, profileName);
  }

  setReport(result);
}

function runClean() {
  if (!exports) {
    setReport("MoonPost Wasm runtime is not ready.");
    return;
  }

  const input = elements.input.value.trim();
  if (!input) {
    setReport("ERROR: subtitle text is empty");
    return;
  }

  const profileName = elements.profile.value;

  if (currentMode !== "creator") {
    setReport("Clean is only available in Creator mode.");
    return;
  }

  const result = exports.creator_clean(input, profileName);
  setReport(result);
}

async function loadFile(file) {
  const text = await file.text();
  elements.input.value = text;
  elements.fileLabel.textContent = file.name;
  runQc();
}

function downloadReport() {
  const blob = new Blob([lastReport], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = "moonpost-qc-report.txt";
  anchor.click();
  URL.revokeObjectURL(url);
}

// Tab switching
document.querySelectorAll(".tab").forEach((tab) => {
  tab.addEventListener("click", () => switchMode(tab.dataset.mode));
});

elements.runButton.addEventListener("click", runQc);
elements.cleanButton.addEventListener("click", runClean);
elements.profile.addEventListener("change", runQc);
elements.fps.addEventListener("change", runQc);
elements.sampleButton.addEventListener("click", () => {
  elements.input.value = samples[currentMode] || samples.qc;
  elements.fileLabel.textContent = "Sample subtitle";
  runQc();
});
elements.fileInput.addEventListener("change", (event) => {
  const file = event.target.files?.[0];
  if (file) {
    loadFile(file);
  }
});
elements.copyButton.addEventListener("click", async () => {
  await navigator.clipboard.writeText(lastReport);
});
elements.downloadButton.addEventListener("click", downloadReport);

for (const eventName of ["dragenter", "dragover"]) {
  elements.dropZone.addEventListener(eventName, (event) => {
    event.preventDefault();
    elements.dropZone.classList.add("active");
  });
}

for (const eventName of ["dragleave", "drop"]) {
  elements.dropZone.addEventListener(eventName, (event) => {
    event.preventDefault();
    elements.dropZone.classList.remove("active");
  });
}

elements.dropZone.addEventListener("drop", (event) => {
  const file = event.dataTransfer.files?.[0];
  if (file) {
    loadFile(file);
  }
});

// Initialize with creator mode
updateProfileOptions();
elements.input.value = samples.creator;

try {
  exports = await loadWasm();
  setStatus("Wasm ready", "ready");
  runQc();
} catch (error) {
  setStatus("Wasm unavailable", "error");
  setReport(
    [
      "MoonPost Wasm could not start in this browser.",
      "",
      "This demo requires WebAssembly GC and JS string builtins support.",
      String(error?.message || error),
    ].join("\n"),
  );
}
