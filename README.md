# MoonPost

<p align="right">
<a href="README.en.md">English</a> | 简体中文
</p>

<p align="left">
  <a href="https://github.com/MaoDingA/moonbitpostqc/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/MaoDingA/moonbitpostqc/actions/workflows/ci.yml/badge.svg"></a>
  <a href="README.md"><img alt="简体中文 current" src="https://img.shields.io/badge/%E7%AE%80%E4%BD%93%E4%B8%AD%E6%96%87-current-0f766e?style=flat-square"></a>
  <a href="README.en.md"><img alt="English README" src="https://img.shields.io/badge/English-README-64748b?style=flat-square"></a>
  <img alt="MoonBit native" src="https://img.shields.io/badge/MoonBit-native-8b5cf6?style=flat-square">
  <img alt="license Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-22c55e?style=flat-square">
  <img alt="terminal first" src="https://img.shields.io/badge/terminal-first-475569?style=flat-square">
  <img alt="mode CLI + Wasm" src="https://img.shields.io/badge/mode-CLI%20%2B%20Wasm-2563eb?style=flat-square">
  <img alt="formats SRT + WebVTT" src="https://img.shields.io/badge/formats-SRT%20%2B%20WebVTT-f97316?style=flat-square">
  <img alt="QC ready" src="https://img.shields.io/badge/QC-ready-0ea5e9?style=flat-square">
</p>

MoonPost 是一个用 MoonBit 编写的字幕、时间码与后期质检工具包，面向两类
真实生产流程：创作者发布前字幕清洗，以及影视/OTT 字幕交付验收。

MoonPost 现在按两条能力线组织，而不是把自媒体规则和影视交付规则混在同一个
大而全的检查器里：

- Creator：面向自媒体、口播、短视频和 AI 字幕清洗，默认温和提示，关注文本规范、标点、错别字/术语提示、阅读体验和平台化字幕习惯。
- Delivery：面向影视、OTT、广播和字幕交付 QC，默认严格验收，关注时间轴合法性、帧网格、CPL/CPS、最小间隔、JSON 报告和自动化失败退出码。

底层的 SRT/WebVTT parser、QC rule engine、timecode 和 report formatter
由两条能力线共享。共享底座保持中性，具体平台习惯和交付规范通过 Creator /
Delivery profile 区分。

MoonPost 不做视频解码、转码或 FFmpeg 封装。项目关注的是适合用 MoonBit
确定性实现的后期基础设施层：parser、数据模型、QC 规则、报告、CLI 工具
和 Wasm-ready 核心包。

MoonPost 是原创 MoonBit 项目，不是对特定第三方库的移植；如后续参考或
移植其他开源项目，会在文档中注明来源、许可证和参考范围。

## 功能

共享基础能力：

- 解析和写出 SRT / WebVTT 字幕文件，并支持两种格式相互转换。
- 解析和格式化 SMPTE 风格时间码，支持时间码、帧数、时长和常用帧率之间的精确换算。
- 支持常用帧率：`23.976`、`24`、`25`、`29.97`、`29.97df`、`30`、
  `50`、`59.94`、`59.94df`。
- 支持按整体偏移、帧率转换或帧吸附重定时字幕。
- 在库 API 中提供双语字幕合并和拆分能力。
- 提供浏览器本地 Wasm demo，不上传字幕文件即可运行核心 QC。

Creator 能力：

- 面向抖音、B 站、YouTube、双语字幕等 profile 做发布前检查。
- 默认以 Warning / Info 的温和方式提示文本问题。
- 可显式开启中英双语文本规范检查：混用标点、重复标点、括号/引号配对、
  超长连续字符块、孤立单字行和小型术语词库。
- 支持字幕标点半角/全角规范化转换，适合 AI 字幕和口播字幕清洗。
- 提供 `creator check` 与 `creator clean`，用于发布前检查和安全格式清理。

Delivery 能力：

- 面向影视、OTT、影院和广播字幕交付 profile 做严格 QC。
- 检查时间重叠、非法时长、空字幕、时长上下限、单行字符数、行数、阅读速度、
  帧网格对齐和最小 cue 间隔。
- 支持 JSON report 和 `--fail-on-error`，适合自动化交付检查。
- 提供 `delivery check` 目录级交付预检和 `delivery subtitle-check` 单字幕文件
  QC，可检查交付包资产、manifest、metadata、SHA-256 checksum 和字幕问题。

## 两条生产线

| 方向 | 目标 | 默认策略 | 典型入口 |
| --- | --- | --- | --- |
| Creator | 自媒体、短视频、口播、AI 字幕发布前清洗 | 温和提示，安全清理，不默认失败 | `creator check`、`creator clean` |
| Delivery | 影视、OTT、广播、本地化字幕交付验收 | 严格 QC，Error 可触发非零退出码 | `delivery check`、`delivery subtitle-check` |

## 使用场景

Creator 场景：

- AI 字幕、口播字幕和短视频字幕发布前清洗。
- 检查中英混排、标点风格、重复标点、括号/引号配对、孤立单字行。
- 在不改变语义的前提下做半角/全角标点规范化。
- 按平台习惯检查字幕行长、阅读速度和视觉密度。

Delivery 场景：

- 交付前检查 SRT/WebVTT 字幕的重叠、时长、行长、行数和阅读速度问题。
- 检查帧率假设、帧网格对齐和 cue 最小间隔。
- 在剪辑或版本变更后平移字幕、转换帧率或吸附到目标帧网格。
- 输出 JSON report，并用 `--fail-on-error` 接入自动化交付流程。

共享场景：

- 在创作者和本地化流程中完成 SRT/WebVTT 转换与基础质检。
- 通过浏览器本地 Wasm demo 运行核心 QC，字幕文本不上传服务器。

## 适用人群

MoonPost 主要面向会直接处理字幕文件、发布前检查和交付验收的用户。

| 用户 | MoonPost 能提供什么 |
| --- | --- |
| 创作者与发布者 | 上传前检查 AI 字幕、口播字幕、标点、行长、阅读速度和平台化字幕习惯。 |
| 剪辑师与字幕编辑 | 在交付或发布前发现重叠、空字幕、超长行、过短时长和阅读速度问题。 |
| 本地化团队 | 在翻译、审校和回传过程中做可重复的 SRT/WebVTT 检查与双语字幕处理。 |
| 后期与媒体 QA | 检查时间码、帧网格、cue 间隔，并生成可读且可自动化消费的 QC 报告。 |
| 交付工程与平台运营 | 使用 JSON report 和失败退出码，把字幕 QC 接入批处理或 CI 流程。 |

## 环境要求

- MoonBit 工具链。
- 可运行 `moon` 命令的 shell 环境。
- 如果要用示例命令启动本地 Wasm demo，需要 Python 3。

开发过程中测试过的本地 MoonBit 工具链：

```text
moon 0.1.20260512
moonc v0.9.2
```

## 安装

MoonPost 已发布到 [mooncakes.io](https://mooncakes.io/MaoDingA/moonpost)，可以在任何 MoonBit 项目中作为依赖使用：

```bash
moon add MaoDingA/moonpost
```

安装后在代码中按需导入子包：

```moonbit
// 字幕解析与写出
let track = parse_srt(input)
// 时间码与帧率
let tc = parse_timecode("01:00:00:00", FrameRate::fps_25())
// QC 校验
let issues = check_cues(track.cues, default_profile())
```

可用的子包包括 `MaoDingA/moonpost/subtitle`、`MaoDingA/moonpost/timecode`、`MaoDingA/moonpost/qc`、`MaoDingA/moonpost/creator`、`MaoDingA/moonpost/delivery`、`MaoDingA/moonpost/retime` 和 `MaoDingA/moonpost/align`。完整 API 参考 README 中的"核心公开 API"章节。

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

### Creator / Delivery 示例

```bash
moon run cmd/main --target native -- creator check examples/bilingual.srt --profile bilingual
moon run cmd/main --target native -- creator clean examples/good.srt --profile douyin -o fixed.srt
moon run cmd/main --target native -- delivery check examples/delivery-package/good --json
moon run cmd/main --target native -- delivery subtitle-check examples/bad.srt --profile ott-zh --fps 25
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-source-srt --fail-on-warning
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-frame-strict --fail-on-warning
```

### Creator AI 字幕清洗示例

检查包含 AI 转写产物的字幕：

```bash
moon run cmd/main --target native -- creator check examples/creator/ai-clean-bad.srt --profile douyin
```

输出示例：

```text
examples/creator/ai-clean-bad.srt
summary: 0 errors, 15 warnings

WARN C601 cue#1 | repeated word: '然后'
WARN C601 cue#2 | repeated word: '就是'
WARN C602 cue#3 | ASR marker: ASR music marker '[Music]'
WARN C401 cue#3 | possible confusion: '认真的做' should be '认真地做'
WARN C402 | inconsistent term: 'moonpost' vs canonical 'MoonPost'
WARN C402 | inconsistent term: 'webvtt' vs canonical 'WebVTT'
```

### explain 和 profile

查看诊断码说明：

```bash
moon run cmd/main --target native -- explain C601
moon run cmd/main --target native -- explain E101
```

查看所有 profile 配置：

```bash
moon run cmd/main --target native -- profile list
moon run cmd/main --target native -- profile show creator --name douyin
moon run cmd/main --target native -- profile show delivery --name ott-zh
```

CI 集成示例见 [`examples/ci-integration.md`](examples/ci-integration.md)。

`creator clean` 示例中的 profile 应匹配实际语言和平台习惯；这里的
`douyin` 命令仅用于展示调用形状。

依赖 `--fail-on-error` 退出码做自动化时，请使用构建后的 native 可执行文件。

### Delivery 第一阶段目标

当前第一阶段把 `delivery check <folder>` 作为可展示的目录级交付预检能力：

```bash
moon run cmd/main --target native -- delivery check examples/delivery-package/good --json
moon run cmd/main --target native -- delivery check examples/delivery-package/checksum-bad --fail-on-error
moon run cmd/main --target native -- delivery check examples/delivery-package/bad --profile distribution --subtitle-profile ott-zh --fps 25
moon run cmd/main --target native -- delivery check examples/delivery-package/srt-source-bad --profile distribution --subtitle-profile dcp-source-srt --fail-on-warning
moon run cmd/main --target native -- delivery check examples/delivery-package/srt-source-bad --profile distribution --subtitle-profile dcp-frame-strict --fail-on-warning
```

`delivery check` 会扫描交付目录第一层，识别 video、subtitle、poster、
metadata、checksum 和 `moonpost.delivery.json`，根据 package profile 与
manifest 检查缺失资产和必需字幕语言，解析 `checksum.txt` / `checksums.txt` /
`SHA256SUMS` 中的 SHA-256 条目校验文件内容，并对目录内 SRT/WebVTT 运行字幕
QC。checksum 当前支持标准 `sha256sum` 风格的 `<64hex>  filename` 和
`<64hex> *filename` 行；checksum 指向目录外路径会报错。

单个字幕文件仍可用 `delivery subtitle-check` 独立检查：

```bash
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/ott-good.srt --profile ott-zh --json
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/srt-basic-good.srt --profile srt-basic --fail-on-error
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-source-srt --fail-on-warning
moon run cmd/main --target native -- delivery subtitle-check examples/delivery/dcp-source-srt-bad.srt --profile dcp-frame-strict --fail-on-warning
moon build cmd/main --target native
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check examples/delivery/ott-bad.srt --profile ott-zh --fps 25 --fail-on-error
```

`--fail-on-error` 适合接入自动化流程；如果希望 Warning 也阻塞交付，可使用
`--fail-on-warning`。依赖退出码时请使用构建后的 native 可执行文件。

字幕交付 profile 目前包括 `ott-zh`、`cinema-zh`、`broadcast`、`srt-basic`、
`dcp-source-srt` 和 `dcp-frame-strict`。

| Profile | 适用场景 | 时长/阅读速度 | 帧网格 |
| --- | --- | --- | --- |
| `srt-basic` | 普通 SRT 源文件预检，检查格式、序号、WebVTT settings 混入和样式标记风险。 | 500ms 到 7000ms，42 CPL / 20 CPS。 | 默认不开启。 |
| `dcp-source-srt` | DCP 制作前的 SRT 源文件风险预检，额外提示首条字幕过早出现等转制风险。 | 500ms 到 6000ms，32 CPL / 17 CPS。 | 默认不开启，不报 W401/W402。 |
| `dcp-frame-strict` | 最终制版前需要主动打开的 DCP 帧网格和最小间隔严格检查。 | 1000ms 到 6000ms，32 CPL / 17 CPS。 | 24fps，最小 2 帧间隔。 |

边界也要说清：这些 profile 检查的是 SRT 文本源文件，不是 DCP XML/MXF
Timed Text validator，也不是 IMF IMSC validator；内嵌字幕流和烧录字幕的字体、
字号、安全区、实际渲染位置需要在相应容器、DCP/IMF 包或视频画面里验证。

## CLI 概览

```text
MoonPost - subtitle, timecode and post-production QC toolkit

Usage:
  moonpost <command> [options]

Commands:
  creator     Check and clean creator-platform subtitle files with gentle hints
  delivery    Run strict delivery-profile subtitle checks
  subtitle    Convert subtitle formats
  timecode    Convert SMPTE-style timecode and frame counts
  retime      Shift, speed-convert, or snap subtitle timing
  merge       Merge two subtitle tracks into bilingual cues
  split-bilingual
              Split bilingual cues into two subtitle tracks
  qc          Compatibility alias for subtitle delivery QC
  explain     Explain a QC diagnostic code
  profile     List or show profile configurations
```

## 字幕 QC

检查 SRT 或 WebVTT 文件：

```bash
moon run cmd/main --target native -- qc examples/bad.srt --fps 25 --profile streaming
```

输出 JSON report：

```bash
moon run cmd/main --target native -- qc examples/good.srt --json
```

显式开启中英双语文本规范检查：

```bash
moon run cmd/main --target native -- qc examples/good.srt --text-style bilingual
```

`--text-style` 默认关闭，不会改变普通 `qc` 结果。可选值包括 `bilingual`、
`zh` 和 `en`。

构建 native CLI 后，可以用 `--fail-on-error` 在发现 Error 级问题时返回非零退出码：

```bash
moon build cmd/main --target native
_build/native/debug/build/cmd/main/main.exe qc examples/bad.srt --fail-on-error
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
| `W100` | Warning | SRT 源文件 profile 收到 WebVTT 输入。 |
| `W101` | Warning | SRT cue 缺少数字序号。 |
| `W102` | Warning | SRT cue 数字序号不连续。 |
| `W201` | Warning | cue 时长短于当前 profile 允许值。 |
| `W202` | Warning | cue 时长长于当前 profile 允许值。 |
| `W203` | Warning | 某一行文本超过当前 CPL 限制。 |
| `W204` | Warning | cue 行数超过当前 profile 允许值。 |
| `W310` | Warning | 阅读速度超过当前 CPS 限制。 |
| `W401` | Warning | cue 时间未对齐当前帧网格。 |
| `W402` | Warning | 与下一个 cue 的间隔低于当前帧间隔限制。 |
| `W501` | Warning | 显式开启文本规范检查后，发现混用标点风格。 |
| `W502` | Warning | 显式开启文本规范检查后，发现重复标点。 |
| `W503` | Warning | 显式开启文本规范检查后，发现可疑括号或引号配对。 |
| `W510` | Warning | 显式开启文本规范检查后，发现超长连续字符块。 |
| `W511` | Warning | 显式开启文本规范检查后，发现孤立单字行。 |
| `W520` | Warning | 显式开启文本规范检查后，发现词库中的疑似错别字或术语问题。 |
| `W601` | Warning | SRT 源文件包含字体或颜色标记，转制时可能不被保留。 |
| `W602` | Warning | SRT 源文件包含 ASS/SSA 样式覆盖，转制时可能不被保留。 |
| `W603` | Warning | SRT 时间行包含 WebVTT-style settings。 |
| `W701` | Warning | DCP-source SRT profile 下首条字幕离节目开头太近。 |

## 时间码

`MaoDingA/moonpost/timecode` 是 MoonPost 的通用 SMPTE 时间码基础包。它把
时间码标签、帧数、时长和半开时间码区间分开建模，支持 drop-frame 边界计算、
同帧率时间码算术、显式比较，以及基于精确帧率分子/分母的 23.976 / 29.97 /
59.94 换算。它还提供 24 小时 wrap policy、rational seconds、ST 12 logical
word/user bits/packed LTC bytes（限 24h 内、nominal <= 30fps 的 LTC codeword）、
以及 FCPXML、IMF、Apple delivery-package 和 EDL timecode 字段的轻量 interop helpers。包级可测试示例见
`timecode/README.mbt.md`。

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
01:00:00:00 @23.976fps = 01:00:03:15 @25fps
```

生成 IMF composition 风格的精确 edit-rate timecode 字段：

```bash
moon run cmd/main --target native -- timecode imf-from '01:00:00;00' --fps 29.97df
```

输出：

```text
01:00:00;00 @29.97df = editRate 30000/1001 timecodeRate 30 dropFrame true startAddress 01:00:00:00
```

规范化一个 CMX 风格 EDL event 行：

```bash
moon run cmd/main --target native -- timecode edl-event '001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00' --fps 25
```

输出：

```text
001 AX V C 01:00:00:00 01:00:10:00 00:00:00:00 00:00:10:00
```

支持的 CLI 帧率值：

| Value | 含义 |
| --- | --- |
| `23.976`, `23.98`, `23976`, `2398` | 23.976fps |
| `24` | 24fps |
| `25` | 25fps |
| `47.952`, `47.95`, `47952`, `4795` | 47.952fps |
| `48` | 48fps |
| `29.97`, `29.97ndf`, `2997`, `2997ndf` | 29.97 non-drop |
| `29.97df`, `29.97DF`, `29.97-drop`, `29.97 drop`, `2997df`, `2997drop` | 29.97 drop-frame |
| `30` | 30fps |
| `50` | 50fps |
| `59.94`, `59.94ndf`, `5994`, `5994ndf` | 59.94 non-drop |
| `59.94df`, `59.94DF`, `59.94-drop`, `59.94 drop`, `5994df`, `5994drop` | 59.94 drop-frame |
| `60` | 60fps |
| `72` | 72fps |
| `96` | 96fps |
| `100` | 100fps |
| `119.88`, `11988` | 119.88fps |
| `120` | 120fps |

库 API 还提供 `Duration` 类型、`Timecode::add_frames`、
`Timecode::frame_distance`、`Timecode::add_duration`、`TimecodeRange` 和
`parse_timecode_result` 等显式同帧率操作。跨帧率比较、区间和时长运算不会隐式
换算，会返回 `None`，调用方可以先选择目标帧率再转换。FCPXML、IMF、Apple
delivery 和 EDL helpers 只处理时间码相关 metadata 字段，不解析完整文件。

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

标点半角/全角规范化转换：

```bash
moon run cmd/main --target native -- subtitle normalize examples/good.srt --punctuation bilingual -o fixed.srt
```

`--punctuation` 可选值包括 `bilingual`、`zh` 和 `en`。该命令只改 cue 文本中的
常见标点，不会重写词语、重排字幕行或改变时间码。

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
| `MaoDingA/moonpost/timecode` | 帧率、时间码解析、帧数/时长/区间转换、同帧率算术和 drop-frame 计算。 |
| `MaoDingA/moonpost/subtitle` | SRT/WebVTT 解析、时间戳格式化、字幕写出。 |
| `MaoDingA/moonpost/qc` | QC profiles、issue 模型、cue 检查、报告格式化。 |
| `MaoDingA/moonpost/creator` | 创作者字幕 profile、文本检查和清洗流程。 |
| `MaoDingA/moonpost/retime` | cue 的整体偏移、帧率转换和帧吸附。 |
| `MaoDingA/moonpost/align` | 双语字幕合并和拆分 helpers。 |
| `MaoDingA/moonpost/cli` | CLI 参数解析。 |
| `MaoDingA/moonpost/wasm_demo/core` | demo 使用的 Wasm 导出 `qc_subtitle`。 |

### 核心公开 API

Timecode:

```text
parse_timecode(String, FrameRate) -> Timecode?
parse_timecode_result(String, FrameRate) -> Result[Timecode, TimecodeParseError]
parse_timecode_with_policy(String, FrameRate, TimecodeParsePolicy) -> Result[Timecode, TimecodeParseError]
Timecode::to_frames() -> Int
Timecode::format() -> String
Timecode::add_frames(Int) -> Timecode
Timecode::sub_frames(Int) -> Timecode
Timecode::add_duration(Duration) -> Timecode?
Timecode::sub_duration(Duration) -> Timecode?
Timecode::frame_distance(Timecode) -> Int?
Timecode::is_before(Timecode) -> Bool?
Timecode::is_after(Timecode) -> Bool?
FrameRate::frames_to_timecode(Int) -> Timecode
FrameRate::frames_to_timecode_with_wrap(Int, TimecodeWrapMode) -> Timecode
FrameRate::parse(String) -> FrameRate?
FrameRate::label() -> String
FrameRate::nominal_fps() -> Int
FrameRate::fps_numerator() -> Int
FrameRate::fps_denominator() -> Int
convert_timecode(Timecode, FrameRate) -> Timecode
rescale_ms_between_rates(Int, FrameRate, FrameRate) -> Int
Duration::from_frames(Int, FrameRate) -> Duration
Duration::from_ms(Int, FrameRate) -> Duration
Duration::to_frames() -> Int
Duration::to_ms() -> Int
Duration::format() -> String
Duration::add(Duration) -> Duration?
Duration::sub(Duration) -> Duration?
Duration::scale(Int) -> Duration
TimecodeRange::new(Timecode, Timecode) -> TimecodeRange?
TimecodeRange::duration() -> Duration?
TimecodeRange::contains(Timecode) -> Bool?
TimecodeRange::overlaps(TimecodeRange) -> Bool?
TimecodeRange::shift(Duration) -> TimecodeRange?
RationalSeconds::parse(String) -> RationalSeconds?
RationalSeconds::format() -> String
RationalSeconds::to_frames(FrameRate) -> Int
RationalSeconds::from_frames(Int, FrameRate) -> RationalSeconds
FcpXmlTimecodeAttrs::to_timecode() -> Result[Timecode, TimecodeInteropError]
FcpXmlTimecodeAttrs::from_timecode(Timecode) -> FcpXmlTimecodeAttrs
ImfTimecode::to_timecode() -> Result[Timecode, TimecodeInteropError]
ImfTimecode::from_timecode(Timecode) -> ImfTimecode
ImfEditRate::from_frame_rate(FrameRate) -> ImfEditRate
ImfEditRate::to_frame_rate(Bool) -> Result[FrameRate, TimecodeInteropError]
ImfCompositionTimecode::to_timecode() -> Result[Timecode, TimecodeInteropError]
ImfCompositionTimecode::from_timecode(Timecode) -> ImfCompositionTimecode
SmpteUserBits::from_hex(String) -> Result[SmpteUserBits, TimecodeInteropError]
SmpteUserBits::format_hex() -> String
SmpteTimecodeWord::from_timecode(Timecode) -> SmpteTimecodeWord
SmpteTimecodeWord::to_timecode() -> Result[Timecode, TimecodeInteropError]
SmpteTimecodeWord::pack_ltc_bytes() -> Result[Bytes, TimecodeInteropError]
SmpteTimecodeWord::unpack_ltc_bytes(Bytes, FrameRate) -> Result[SmpteTimecodeWord, TimecodeInteropError]
EdlEvent::parse(String, FrameRate) -> Result[EdlEvent, TimecodeInteropError]
EdlEvent::format() -> String
AppleDeliveryTimecodeFormat::parse(String) -> FrameRate?
AppleDeliveryTimecodeFormat::format(FrameRate) -> String?
AppleDeliveryTimecodeFormat::supported_rates() -> Array[FrameRate]
AppleDeliveryTimecodeFormat::is_supported(FrameRate) -> Bool
```

Subtitle:

```text
parse_srt(String) -> SubtitleTrack?
parse_srt_detailed(String) -> Result[SubtitleTrack, ParseError]
parse_webvtt(String) -> SubtitleTrack?
parse_webvtt_detailed(String) -> Result[SubtitleTrack, ParseError]
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
check_srt_source_track(SubtitleTrack, SrtSourcePolicy) -> Array[QcIssue]
srt_basic_source_policy() -> SrtSourcePolicy
dcp_source_srt_policy() -> SrtSourcePolicy
format_report(String, Array[QcIssue]) -> Array[String]
format_json_report(String, Array[QcIssue]) -> String
has_errors(Array[QcIssue]) -> Bool
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

更完整的层级说明见 [`docs/project-structure.md`](docs/project-structure.md)。

```text
moonpost/
├── timecode/        SMPTE 风格时间码和帧率 helpers
├── subtitle/        SRT/WebVTT parser、timestamp 和 writer
├── qc/              字幕 QC、报告、双语文本规范和标点规范化
├── retime/          整体偏移、帧率转换和帧吸附
├── align/           双语字幕 merge/split helpers
├── delivery/        单集交付预检模型和 manifest 解析
├── cli/             CLI 参数模型和命令解析
├── cmd/main/        Native CLI 入口和文件系统 I/O
├── wasm_demo/core/  MoonBit Wasm 导出包
├── wasm-demo/       浏览器 demo shell、构建脚本和静态资源
├── examples/        示例字幕文件
├── docs/            项目结构、设计文档和实施计划
└── .github/         CI workflow
```

## CI

仓库包含 GitHub Actions 工作流
[`.github/workflows/ci.yml`](.github/workflows/ci.yml)，会在 push、pull
request 和手动触发时运行。

CI 覆盖：

- `moon fmt` 后检查是否产生未提交 diff。
- `moon info` 后检查 `pkg.generated.mbti` 等生成接口摘要是否同步。
- `moon check --target native` 和 `moon check --target wasm-gc`。
- `moon build --target native` 和 `moon build --target wasm-gc`。
- `moon test --target native` 和 `moon test --target wasm-gc`。
- Wasm demo release 构建和 `wasm-demo/public/moonpost_qc.wasm` 产物检查。
- CLI 冒烟测试：timecode、subtitle convert、QC report。

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

## 许可证

Apache-2.0。见 [LICENSE](LICENSE)。
