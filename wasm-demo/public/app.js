const sampleSubtitle = `1
00:00:01,123 --> 00:00:01,500
This line is intentionally far too long for a delivery profile.

2
00:00:01,450 --> 00:00:04,000
Overlap with the previous cue.
`;

const elements = {
  status: document.querySelector("#runtime-status"),
  input: document.querySelector("#subtitle-input"),
  output: document.querySelector("#report-output"),
  profile: document.querySelector("#profile-select"),
  summary: document.querySelector("#summary-label"),
  fileLabel: document.querySelector("#file-label"),
  fileInput: document.querySelector("#file-input"),
  dropZone: document.querySelector("#drop-zone"),
  runButton: document.querySelector("#run-button"),
  sampleButton: document.querySelector("#sample-button"),
  copyButton: document.querySelector("#copy-button"),
  downloadButton: document.querySelector("#download-button"),
};

let qcSubtitle = null;
let lastReport = "";

function setStatus(text, state = "") {
  elements.status.textContent = text;
  elements.status.className = `status ${state}`.trim();
}

function setReport(text) {
  lastReport = text;
  elements.output.textContent = text;
  elements.copyButton.disabled = text.length === 0;
  elements.downloadButton.disabled = text.length === 0;

  const summaryLine = text.split("\n").find(line => line.startsWith("summary:"));
  elements.summary.textContent = summaryLine || "Report ready";
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
      return instance.exports.qc_subtitle;
    } catch {
      const bytes = await response.arrayBuffer();
      const { instance } = await WebAssembly.instantiate(
        bytes,
        {},
        compileOptions,
      );
      return instance.exports.qc_subtitle;
    }
  }

  const bytes = await response.arrayBuffer();
  const { instance } = await WebAssembly.instantiate(bytes, {}, compileOptions);
  return instance.exports.qc_subtitle;
}

function runQc() {
  if (!qcSubtitle) {
    setReport("MoonPost Wasm runtime is not ready.");
    return;
  }

  const input = elements.input.value.trim();
  if (!input) {
    setReport("uploaded subtitle\nsummary: 1 error, 0 warnings\n\nERROR E000 | subtitle text is empty");
    return;
  }

  setReport(qcSubtitle(input, elements.profile.value));
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

elements.runButton.addEventListener("click", runQc);
elements.profile.addEventListener("change", runQc);
elements.sampleButton.addEventListener("click", () => {
  elements.input.value = sampleSubtitle;
  elements.fileLabel.textContent = "Sample subtitle";
  runQc();
});
elements.fileInput.addEventListener("change", event => {
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
  elements.dropZone.addEventListener(eventName, event => {
    event.preventDefault();
    elements.dropZone.classList.add("active");
  });
}

for (const eventName of ["dragleave", "drop"]) {
  elements.dropZone.addEventListener(eventName, event => {
    event.preventDefault();
    elements.dropZone.classList.remove("active");
  });
}

elements.dropZone.addEventListener("drop", event => {
  const file = event.dataTransfer.files?.[0];
  if (file) {
    loadFile(file);
  }
});

elements.input.value = sampleSubtitle;

try {
  qcSubtitle = await loadWasm();
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
