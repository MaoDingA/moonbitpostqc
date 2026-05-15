# MoonPost

<p align="right">
<a href="README.en.md">English</a> | 简体中文
</p>

MoonPost 是一个用 MoonBit 编写的字幕、时间码与后期交付质检工具包。

它面向文本型媒体交付工作：检查 SRT/WebVTT 字幕文件、转换字幕格式、
计算 SMPTE 风格时间码、重定时字幕 cue，并让同一套核心逻辑可以运行在
native CLI 和浏览器本地 WebAssembly demo 中。

MoonPost 不做视频解码、转码或 FFmpeg 封装。项目关注的是适合用 MoonBit
确定性实现的后期基础设施层：parser、数据模型、QC 规则、报告、CLI 工具
和 Wasm-ready 核心包。

## 功能

- 解析和写出 SRT 字幕文件。
- 解析和写出 WebVTT 字幕文件。
- 支持 SRT 与 WebVTT 相互转换。
- 解析和格式化 SMPTE 风格时间码。
- 支持时间码与帧数互转。
- 支持常用帧率：`23.976`、`24`、`25`、`29.97`、`29.97df`、`30`、
  `50`、`59.94`、`59.94df`。
- 提供字幕 QC 检查：时间重叠、非法时长、空字幕、时长上下限、单行字符数、
  行数、阅读速度、帧网格对齐和最小 cue 间隔。
- 支持按整体偏移、帧率转换或帧吸附重定时字幕。
- 在库 API 中提供双语字幕合并和拆分能力。
- 提供浏览器本地 Wasm demo，不上传字幕文件即可运行 QC。

## 使用场景

MoonPost 适合需要在交付或发布前对字幕、时间码和后期文本数据做稳定检查的
工作流。

常见场景：

- 在交付给流媒体平台或发布平台前检查字幕文件。
- 在创作者工具链中转换 SRT 和 WebVTT。
- 检查字幕 cue 是否存在时间重叠。
- 发现过短、过长、空文本或阅读速度过高的字幕。
- 检查字幕时间点是否对齐目标帧网格。
- 在剪辑变更后整体平移字幕。
- 在不同帧率假设之间转换 cue 时间。
- 在浏览器中本地运行 QC，不把字幕文本发送到服务器。

## 适用人群

MoonPost 面向处理字幕文本、交付检查和时间型后期数据的个人与团队。

| 用户 | MoonPost 能提供什么 |
| --- | --- |
| 字幕编辑 | 在交付前发现重叠、空字幕、超长行、过短时长和阅读速度问题。 |
| 本地化团队 | 在翻译、审校和回传过程中提供可重复的 SRT/WebVTT 检查。 |
| 后期助理 | 转换帧数、验证时间码，并在时间线调整后重定时字幕文件。 |
| 流媒体与媒体 QA 团队 | 生成一致、可读的人类友好型交付 QC 报告。 |
| 创作者与发布者 | 在上传前转换 SRT/WebVTT 并捕获常见字幕问题。 |
| 工具开发者 | 在自定义工作流中复用纯 MoonBit parser、QC、retime 和 Wasm-ready 包。 |
| MoonBit 开发者 | 参考一个覆盖文本解析、CLI、测试和 WebAssembly 集成的实际项目。 |

## 项目状态

MoonPost 目前处于早期阶段。核心包已经可用于本地工具和 demo，但公开 API
在稳定版本前仍可能调整。

当前实现范围：

| 模块 | 状态 |
| --- | --- |
| Timecode | 已实现 |
| SRT parser/writer | 已实现 |
| WebVTT parser/writer | 已实现 |
| 字幕 QC | 已实现 |
| CLI | 已实现 |
| Retime helpers | 已实现 |
| 双语合并/拆分 helpers | 已在库 API 中实现 |
| 浏览器 Wasm demo | 已实现 |
| ASS/SSA | 未实现 |
| TTML/IMSC | 未实现 |
| 媒体容器信息检查 | 未实现 |

## 环境要求

- MoonBit 工具链。
- 可运行 `moon` 命令的 shell 环境。
- 如果要用示例命令启动本地 Wasm demo，需要 Python 3。

开发过程中测试过的本地 MoonBit 工具链：

```text
moon 0.1.20260512
moonc v0.9.2
```

## 快速开始

克隆仓库后运行测试：

```bash
moon test --target native
moon test --target wasm-gc
```

从源码运行 CLI：

```bash
moon run cmd/main --target native -- --help
```

源码运行前缀是：

```bash
moon run cmd/main --target native --
```

下面的示例都会使用这个前缀。如果之后发布独立二进制，可以把该前缀替换为
`moonpost`。

## CLI 概览

```text
MoonPost - subtitle, timecode and post-production QC toolkit

Usage:
  moonpost <command> [options]

Commands:
  qc          Check subtitle delivery quality
  timecode    Convert SMPTE-style timecode and frame counts
  subtitle    Convert subtitle formats
  retime      Shift, speed-convert, or snap subtitle timing
```

## 字幕 QC

检查 SRT 或 WebVTT 文件：

```bash
moon run cmd/main --target native -- qc examples/bad.srt --fps 25 --profile streaming
```

示例报告：

```text
examples/bad.srt
summary: 3 errors, 7 warnings

WARN W201 cue#1 | duration 377ms below minimum 800ms
WARN W310 cue#1 | 225 cps exceeds max 20
WARN W203 cue#1 | line 1: 85 chars, max 42
WARN W401 cue#1 | cue timing is not aligned to 40ms frame grid
WARN W202 cue#2 | duration 7600ms above maximum 7000ms
WARN W203 cue#2 | line 1: 49 chars, max 42
ERROR E102 cue#3 | end time must be after start time
ERROR E201 cue#3 | empty cue text
WARN W401 cue#3 | cue timing is not aligned to 40ms frame grid
ERROR E101 cue#1 | overlaps cue#2 by 100ms
```

### QC Profiles

Profiles 为不同交付上下文提供实用默认值。

| Profile | 最大 CPL | 最大 CPS | 最大行数 | 最小时长 | 最大时长 | 最小间隔 | 帧网格 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| `default` | 42 | 20 | 2 | 800ms | 7000ms | 2 frames | 无 |
| `streaming` | 42 | 20 | 2 | 800ms | 7000ms | 2 frames | 25fps |
| `cinema` | 32 | 17 | 2 | 1000ms | 6000ms | 2 frames | 24fps |
| `social-video` | 30 | 24 | 2 | 500ms | 5000ms | 1 frame | 30fps |

CLI 也支持通过 `--fps <rate>` 覆盖当前 profile 的帧网格。

### QC 规则代码

| Code | 级别 | 含义 |
| --- | --- | --- |
| `E101` | Error | 当前 cue 与下一个 cue 时间重叠。 |
| `E102` | Error | cue 结束时间不晚于开始时间。 |
| `E201` | Error | cue 文本为空。 |
| `W201` | Warning | cue 时长短于当前 profile 允许值。 |
| `W202` | Warning | cue 时长长于当前 profile 允许值。 |
| `W203` | Warning | 某一行文本超过当前 CPL 限制。 |
| `W204` | Warning | cue 行数超过当前 profile 允许值。 |
| `W310` | Warning | 阅读速度超过当前 CPS 限制。 |
| `W401` | Warning | cue 时间未对齐当前帧网格。 |
| `W402` | Warning | 与下一个 cue 的间隔低于当前帧间隔限制。 |

## 时间码

把 SMPTE 风格时间码转换为帧数：

```bash
moon run cmd/main --target native -- timecode to-frames 01:00:00:00 --fps 25
```

输出：

```text
01:00:00:00 @25fps = 90000 frames
```

把帧数转换回时间码：

```bash
moon run cmd/main --target native -- timecode from-frames 90000 --fps 25
```

输出：

```text
90000 frames @25fps = 01:00:00:00
```

在不同帧率假设之间转换时间码：

```bash
moon run cmd/main --target native -- timecode convert 01:00:00:00 --from 23.976 --to 25
```

输出：

```text
01:00:00:00 @23.976fps = 00:00:24:12 @25fps
```

支持的 CLI 帧率值：

| Value | 含义 |
| --- | --- |
| `23.976`, `23976` | 23.976fps |
| `24` | 24fps |
| `25` | 25fps |
| `29.97`, `2997` | 29.97 non-drop |
| `29.97df`, `29.97DF`, `29.97-drop`, `2997df` | 29.97 drop-frame |
| `30` | 30fps |
| `50` | 50fps |
| `59.94`, `5994` | 59.94 non-drop |
| `59.94df`, `59.94DF`, `59.94-drop`, `5994df` | 59.94 drop-frame |

## 字幕转换

SRT 转 WebVTT：

```bash
moon run cmd/main --target native -- subtitle convert examples/good.srt --to webvtt
```

写出到文件：

```bash
moon run cmd/main --target native -- subtitle convert examples/good.srt --to webvtt -o output.vtt
```

WebVTT 转 SRT：

```bash
moon run cmd/main --target native -- subtitle convert examples/good.vtt --to srt -o output.srt
```

已实现的 parser 行为：

- SRT cue 可以包含数字序号。
- SRT cue 没有数字序号时也可解析。
- WebVTT 文件必须包含 `WEBVTT` header。
- WebVTT cue identifier 会被保留。
- 写出 WebVTT 时会保留 cue settings。
- WebVTT `NOTE`、`STYLE`、`REGION` metadata block 会被 parser 跳过。
- 可处理文件开头的 UTF-8 BOM。
- 可处理 CRLF 行尾。

## Retime

整体平移所有 cue：

```bash
moon run cmd/main --target native -- retime examples/good.srt --offset +1200ms
```

输出：

```text
1
00:00:02,200 --> 00:00:04,400
Hello, welcome to MoonBit.

2
00:00:05,200 --> 00:00:06,700
This subtitle is ready for QC.
```

把重定时结果写入文件：

```bash
moon run cmd/main --target native -- retime examples/good.srt --offset -500ms -o shifted.srt
```

在不同帧率假设之间转换 cue 时间：

```bash
moon run cmd/main --target native -- retime examples/good.srt --from-fps 23.976 --to-fps 25 -o converted.srt
```

把 cue 时间吸附到帧网格：

```bash
moon run cmd/main --target native -- retime examples/good.srt --snap-fps 25 -o snapped.srt
```

## 浏览器本地 Wasm Demo

MoonPost 包含一个本地字幕 QC 浏览器 demo。该 demo 加载 MoonBit `wasm-gc`
构建产物，并在浏览器中运行 QC。字幕文本保留在本地浏览器会话中。

构建 Wasm 产物：

```bash
./wasm-demo/build.sh
```

启动本地服务：

```bash
python3 -m http.server 8765 --directory wasm-demo/public
```

打开：

```text
http://localhost:8765
```

该 demo 需要浏览器支持 WebAssembly GC 和 JS string builtins。

## Library Packages

MoonPost 由多个小型 MoonBit package 组成。公开 API 可参考生成的
`pkg.generated.mbti` 文件。

| Package | 用途 |
| --- | --- |
| `phenom8010/moonpost/timecode` | 帧率、时间码解析、帧数转换、drop-frame 计算。 |
| `phenom8010/moonpost/subtitle` | SRT/WebVTT 解析、时间戳格式化、字幕写出。 |
| `phenom8010/moonpost/qc` | QC profiles、issue 模型、cue 检查、报告格式化。 |
| `phenom8010/moonpost/retime` | cue 的整体偏移、帧率转换和帧吸附。 |
| `phenom8010/moonpost/align` | 双语字幕合并和拆分 helpers。 |
| `phenom8010/moonpost/cli` | CLI 参数解析。 |
| `phenom8010/moonpost/wasm_demo/core` | demo 使用的 Wasm 导出 `qc_subtitle`。 |

### 核心公开 API

Timecode:

```text
parse_timecode(String, FrameRate) -> Timecode?
Timecode::to_frames() -> Int
Timecode::format() -> String
FrameRate::frames_to_timecode(Int) -> Timecode
convert_timecode(Timecode, FrameRate) -> Timecode
rescale_ms_between_rates(Int, FrameRate, FrameRate) -> Int
```

Subtitle:

```text
parse_srt(String) -> SubtitleTrack?
parse_webvtt(String) -> SubtitleTrack?
write_srt(SubtitleTrack) -> String
write_webvtt(SubtitleTrack) -> String
parse_timestamp_ms(String) -> Int?
format_srt_timestamp(Int) -> String
format_vtt_timestamp(Int) -> String
```

QC:

```text
default_profile() -> QcProfile
streaming_profile() -> QcProfile
cinema_profile() -> QcProfile
social_video_profile() -> QcProfile
profile_by_name(String) -> QcProfile?
check_cues(Array[Cue], QcProfile) -> Array[QcIssue]
format_report(String, Array[QcIssue]) -> Array[String]
```

Retime:

```text
offset_cues(Array[Cue], Int) -> Array[Cue]
convert_fps_cues(Array[Cue], FrameRate, FrameRate) -> Array[Cue]
snap_cues_to_frames(Array[Cue], FrameRate) -> Array[Cue]
```

Align:

```text
merge_bilingual(Array[Cue], Array[Cue], tolerance_ms~ : Int) -> Array[Cue]
split_bilingual(Array[Cue]) -> BilingualSplit
```

Wasm demo core:

```text
qc_subtitle(String, String) -> String
```

## 仓库结构

```text
moonpost/
├── timecode/        SMPTE 风格时间码和帧率 helpers
├── subtitle/        SRT/WebVTT parser 和 writer
├── qc/              字幕交付 QC 规则和报告格式化
├── retime/          整体偏移、帧率转换和帧吸附
├── align/           双语字幕 helpers
├── cli/             命令解析
├── cmd/main/        Native CLI 入口
├── wasm_demo/core/  MoonBit Wasm 导出包
├── wasm-demo/       浏览器 demo shell 和构建脚本
└── examples/        示例字幕文件
```

## 开发

运行 native 测试：

```bash
moon test --target native
```

运行 Wasm-GC 兼容测试：

```bash
moon test --target wasm-gc
```

检查 native 和 Wasm-GC target：

```bash
moon check --target native
moon check --target wasm-gc
```

格式化源码：

```bash
moon fmt
```

重新生成公开接口摘要：

```bash
moon info
```

构建 Wasm demo core：

```bash
moon build wasm_demo/core --target wasm-gc --release
```

## 设计原则

- 核心逻辑保持纯 MoonBit。
- 优先实现确定性检查，而不是媒体解码。
- 默认让字幕文本保留在本地。
- CLI 输出需要对剪辑、字幕、QA 和开发者都可读。
- 保持各 library package 足够小，方便独立复用。
- 生成文件和本地缓存视为构建产物，而不是源文件。

## 限制

- 暂未实现 ASS/SSA、TTML 和 IMSC。
- CLI 当前聚焦文件操作和人类可读输出。
- WebAssembly demo 依赖浏览器对 WebAssembly GC 和 JS string builtins 的支持。
- QC profiles 当前是内置的；暂未实现外部 profile 文件。
- 项目不检查视频、音频、MP4、MOV、WAV 或 BWF 容器元数据。

## Roadmap

后续版本计划方向：

- 从 JSON 或 TOML 读取自定义 QC profiles。
- 输出机器可读 JSON report。
- ASS/SSA parser 和 writer。
- TTML/IMSC 子集支持。
- CMX3600 EDL 解析。
- BWF/iXML 声音元数据检查。
- 发布 native binary。
- 发布到 Mooncakes。

## 许可证

Apache-2.0。见 [LICENSE](LICENSE)。
