# MoonPost 用户体验指南

> 面向真实字幕处理、交付 QC 和工程集成流程的本地体验路径。

## 30 秒理解

MoonPost 是一个用 MoonBit 编写的字幕、时间码与后期质检工具包。它把常见用户
分成三类，而不是把所有规则塞进一个单一检查器：

- **创作者**：清理 AI 字幕、口播字幕、短视频字幕中的重复词、ASR 标记、标点和术语问题。
- **本地化/交付人员**：检查 SRT/WebVTT/ASS 的时间轴、阅读速度、行长、帧网格和平台 profile。
- **工程集成者**：在 CI 或批处理里使用 JSON report、失败退出码和 MoonBit library API。

底层能力包括 SRT/WebVTT/ASS parser、QC rule engine、creator clean、delivery check、
SMPTE timecode、FCPXML/EDL helpers、DCP package 起步模型和本地 Wasm demo。

## 5 分钟用户路径

```bash
moon build cmd/main --target native
./scripts/e2e-acceptance.sh
_build/native/debug/build/cmd/main/main.exe subtitle convert user-experience/samples/good.srt --to ass
_build/native/debug/build/cmd/main/main.exe creator clean user-experience/samples/ai-clean-bad.srt --verbose
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check user-experience/samples/delivery-bad.srt --profile nrta
```

这条路径覆盖：CLI 构建、端到端用户流程、SRT 到 ASS 转换、AI 字幕自动清理、
国内长视频交付 profile。浏览器端体验可继续运行本地 Wasm demo。

本目录自带 SRT 样例，见 `samples/`：

- `samples/good.srt`：干净字幕，用于转换和重定时。
- `samples/ai-clean-bad.srt`：AI/口播字幕问题样例，用于清理。
- `samples/delivery-bad.srt`：交付 QC 问题样例，用于 profile 检查。

## 浏览器本地体验

```bash
./wasm-demo/build.sh
python3 -m http.server 8765 -d wasm-demo/public
# 打开 http://localhost:8765/
```

需要支持 WebAssembly GC 的浏览器，例如 Chrome 119+、Firefox 120+ 或 Edge 119+。
Demo 全程本地运行，不上传字幕文本。

## 用户流程

### 创作者字幕清理

```bash
_build/native/debug/build/cmd/main/main.exe creator check user-experience/samples/ai-clean-bad.srt --profile douyin
_build/native/debug/build/cmd/main/main.exe creator clean user-experience/samples/ai-clean-bad.srt --profile douyin --verbose -o fixed.srt
```

适合处理 AI 转写残留、重复词、口癖、术语不一致和标点风格问题。

### 交付字幕检查

```bash
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check user-experience/samples/delivery-bad.srt --profile iqiyi
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check user-experience/samples/delivery-bad.srt --profile nrta
```

适合按 OTT、长视频平台、广电送审或影院/DCP 源文件要求做可重复检查。

### 交付目录预检

```bash
_build/native/debug/build/cmd/main/main.exe delivery check examples/delivery-package/good --profile distribution --subtitle-profile ott-zh
```

检查 video、subtitle、metadata、manifest、checksum，并对目录内字幕运行对应
subtitle profile。

### 格式转换

```bash
_build/native/debug/build/cmd/main/main.exe subtitle convert user-experience/samples/good.srt --to webvtt
_build/native/debug/build/cmd/main/main.exe subtitle convert user-experience/samples/good.srt --to ass
_build/native/debug/build/cmd/main/main.exe subtitle convert examples/anime.ass --to srt
```

### 时间码和重定时

```bash
_build/native/debug/build/cmd/main/main.exe timecode convert 01:00:00:00 --from 23.976 --to 25
_build/native/debug/build/cmd/main/main.exe retime user-experience/samples/good.srt --offset +1200ms -o shifted.srt
```

## 能力覆盖

| 方向 | 用户价值 |
|---|---|
| 字幕格式 | SRT、WebVTT、ASS/SSA 解析、写出和互转 |
| Creator | AI 字幕清理、术语检查、平台化 profile |
| Delivery | 单字幕 QC、交付目录检查、checksum、JSON report |
| 国内平台 | `iqiyi`、`youku`、`tencent`、`nrta` profile |
| Timecode | SMPTE、drop-frame、IMF、EDL、FCPXML helpers |
| DCP | AssetMap、PKL、CPL 轻量解析和引用一致性检查 |
| Wasm | 浏览器本地 QC / Clean demo |

## 自动化信心

```bash
moon test --target native
moon test --target wasm-gc
moon check --target native
moon check --target wasm-gc
moon fmt --check
./scripts/e2e-acceptance.sh
```

当前用户体验回归覆盖 8 个场景、35 个检查，包括格式转换、profile QC、Creator
clean、交付包、时间码、双语字幕、新 QC 规则和诊断码解释。
