# MoonPost 评委验收指南

> 纯 MoonBit 字幕、时间码与后期质检工具包

## 30 秒理解项目

MoonPost 是一个用 MoonBit 编写的字幕/时间码/后期质检 CLI + WASM 工具包，面向两条
真实生产流程：

- **Creator 线**：自媒体、短视频、AI 字幕发布前清洗（抖音/B站/小红书/快手等）
- **Delivery 线**：影视、OTT、广播字幕交付 QC（爱奇艺/优酷/腾讯/广电送审/DCP/OTT）

底层的 SRT/WebVTT/ASS parser、QC rule engine、timecode 和 report formatter
由两条能力线共享，浏览器 WASM demo 全程本地运行。

---

## 浏览器 Demo（本地运行）

```bash
./wasm-demo/build.sh
python3 -m http.server 8765 -d wasm-demo/public
# 浏览器打开 http://localhost:8765/
```

> 需要支持 WebAssembly GC 的浏览器（Chrome 119+ / Firefox 120+ / Edge 119+）

### 场景 1：Creator 字幕清洗

1. 打开 http://localhost:8765/
2. 选择 **Creator** 标签页，Profile 选"抖音"
3. 点击 **Sample** 加载 AI 字幕示例
4. 点击 **Check** 查看问题，再点 **Clean** 查看自动修复结果

### 场景 2：Delivery 字幕验收

1. 选择 **Delivery** 标签页
2. Profile 选"爱奇艺"或"广电送审"
3. 点击 **Sample** 加载交付示例
4. 点击 **Check** 查看严格 QC 报告

### 场景 3：通用 QC

1. 选择 **QC** 标签页
2. Profile 选"Streaming"或"Cinema"
3. 粘贴任意 SRT/WebVTT/ASS 文本
4. 点击 **Check** 查看完整 QC 诊断

---

## CLI 一行命令演示

```bash
# 克隆并构建
git clone https://github.com/MaoDingA/moonbitpostqc.git
cd moonbitpostqc
moon build cmd/main --target native

# SRT → ASS 格式转换
_build/native/debug/build/cmd/main/main.exe subtitle convert examples/good.srt --to ass

# 用爱奇艺 profile 做交付 QC
_build/native/debug/build/cmd/main/main.exe delivery subtitle-check examples/bad.srt --profile iqiyi

# AI 字幕自动清洗
_build/native/debug/build/cmd/main/main.exe creator clean examples/creator/ai-clean-bad.srt --verbose

# 交付包验收
_build/native/debug/build/cmd/main/main.exe delivery check examples/delivery-package/good --profile distribution

# 时间码帧率转换
_build/native/debug/build/cmd/main/main.exe timecode convert 01:00:00:00 --from 23.976 --to 25
```

### 一键端到端验收（本地可跑）

```bash
# 8 个场景，35 个检查，覆盖格式转换、全 profile QC、AI 清洗、
# 交付包验收、时间码、双语字幕、新 QC 规则、explain 全覆盖
./scripts/e2e-acceptance.sh
```

---

## 测试与 CI

| 指标 | 数值 |
|---|---|
| 单元测试 (native) | 335 个，全部通过 |
| 单元测试 (wasm-gc) | 286 个，全部通过 |
| 端到端验收测试 | 8 个场景，35 个检查（`./scripts/e2e-acceptance.sh` 本地一键运行） |
| CLI 冒烟测试 | 覆盖所有子命令（[ci.yml](.github/workflows/ci.yml)） |
| WASM Demo 构建 | CI 自动验证（`wasm-demo` job in [ci.yml](.github/workflows/ci.yml)） |
| 代码行数 | ~15,600 行 MoonBit |
| 源文件 | 76 个 .mbt 文件 |

CI 状态：[![CI](https://github.com/MaoDingA/moonbitpostqc/actions/workflows/ci.yml/badge.svg)](https://github.com/MaoDingA/moonbitpostqc/actions/workflows/ci.yml)

---

## 竞赛验收对照

| # | 验收要求 | 状态 | 证据 |
|---|---|---|---|
| 1 | MoonBit 为主要语言 | ✅ | 76 个 .mbt 文件，~15,600 行 |
| 2 | GitHub 公开，提交记录清晰 | ✅ | 47+ 有意义提交 |
| 3 | 源码结构清晰 | ✅ | 11 个包，分层架构 |
| 4 | README 完整 | ✅ | 双语 README ~800 行 |
| 5 | CI 覆盖 check/build/test | ✅ | 4-job CI + e2e 验收 |
| 6 | 至少一个可运行示例 | ✅ | 37 个示例文件 + 本地 Wasm Demo |
| 7 | 测试覆盖核心功能 | ✅ | 621 个测试 |
| 8 | 发布到 mooncakes.io | ✅ | `moon add MaoDingA/moonpost` |
| 9 | OSI 许可证 | ✅ | Apache-2.0 |

---

## 功能覆盖一览

### 字幕格式

| 格式 | 解析 | 写出 | 互转 |
|---|---|---|---|
| SRT | ✅ | ✅ | ✅ |
| WebVTT | ✅ | ✅ | ✅ |
| ASS (v4.00+) | ✅ | ✅ | ✅ |
| SSA (v4.00) | ✅ | ✅ | ✅ |

### QC 规则（24 条）

| 范围 | 规则 | 说明 |
|---|---|---|
| E1xx | E101, E102 | 时间重叠、时长倒序 |
| E2xx | E201 | 空字幕 |
| W2xx | W201-W208 | 时长、行数、CPL、空白、行平衡 |
| W3xx | W310, W311 | CPS（每秒字符）、WPS（每秒单词） |
| W4xx | W401, W402 | 帧网格对齐、最小间隔 |
| W5xx | W501-W520 | 标点风格、配对符号、术语 |
| W6xx | W601-W603 | SRT 源文件风险 |
| W7xx | W701 | DCP 源预检 |
| C4xx | C401-C403 | 混淆字、术语一致性、用户术语 |
| C6xx | C601-C603 | AI 清洗（重复词、ASR 标记、填充词） |
| D1xx-D4xx | D101-D404 | 交付包资产、元数据、校验 |

### Profile 体系（18 个）

| 类别 | Profile |
|---|---|
| 通用 QC | default, streaming, cinema, social-video |
| 国内短视频 | douyin, bilibili, xiaohongshu, kuaishou, wechat, tiktok, youtube, bilingual |
| 国内长视频交付 | iqiyi, youku, tencent, nrta |
| 影院/广播/DCP | ott-zh, cinema-zh, broadcast, srt-basic, dcp-source-srt, dcp-frame-strict |

### 其他能力

- **时间码**：SMPTE 解析、帧数换算、帧率转换、drop-frame、IMF、EDL、FCPXML
- **重定时**：整体偏移、帧率转换、帧吸附
- **双语字幕**：合并 + 拆分
- **交付包**：资产检查、manifest、SHA-256 校验、JSON 报告
- **WASM Demo**：浏览器本地 QC + Clean

---

## 架构亮点

1. **纯 MoonBit 实现**：无 C/FFI 依赖，WASM GC 原生支持
2. **共享核心**：QC engine 被 Creator/Delivery/QC 三条线复用
3. **Profile 驱动**：所有平台规范通过数据配置，不硬编码逻辑
4. **双 target 验证**：每个测试在 native + wasm-gc 两个后端都跑
5. **CI 全覆盖**：格式检查 + 双 target 构建 + 测试 + WASM demo + CLI 冒烟 + e2e 验收
