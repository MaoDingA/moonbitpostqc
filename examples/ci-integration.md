# CI Integration Examples

MoonPost can be integrated into CI pipelines for automated subtitle QC.

## GitHub Actions

### Basic: Fail on errors

```yaml
name: Subtitle QC

on: [push, pull_request]

jobs:
  subtitle-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install MoonBit
        run: |
          curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
          echo "$HOME/.moon/bin" >> $GITHUB_PATH

      - name: Build MoonPost CLI
        run: moon build cmd/main --target native

      - name: Run subtitle QC
        run: |
          _build/native/debug/build/cmd/main/main.exe \
            delivery subtitle-check subtitles/zh.srt \
            --profile ott-zh --fps 25 \
            --fail-on-error
```

### Strict: Fail on warnings

```yaml
      - name: Strict subtitle QC
        run: |
          _build/native/debug/build/cmd/main/main.exe \
            delivery subtitle-check subtitles/zh.srt \
            --profile cinema-zh --fps 24 \
            --fail-on-error --fail-on-warning
```

### JSON report + artifact upload

```yaml
      - name: QC with JSON report
        run: |
          _build/native/debug/build/cmd/main/main.exe \
            delivery subtitle-check subtitles/zh.srt \
            --profile ott-zh --fps 25 --json \
            > qc-report.json

      - name: Upload QC report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: subtitle-qc-report
          path: qc-report.json
```

### Delivery package check

```yaml
      - name: Delivery package preflight
        run: |
          _build/native/debug/build/cmd/main/main.exe \
            delivery check delivery/EP01 \
            --profile distribution \
            --subtitle-profile ott-zh \
            --fps 25 \
            --fail-on-error
```

### Creator pre-publish check

```yaml
      - name: Creator subtitle check
        run: |
          _build/native/debug/build/cmd/main/main.exe \
            creator check subtitles/output.srt \
            --profile douyin \
            --fail-on-error
```

## GitLab CI

```yaml
subtitle-qc:
  image: debian:bookworm-slim
  stage: test
  before_script:
    - apt-get update && apt-get install -y curl
    - curl -fsSL https://cli.moonbitlang.cn/install/unix.sh | bash
    - export PATH="$HOME/.moon/bin:$PATH"
    - moon build cmd/main --target native
  script:
    - |
      _build/native/debug/build/cmd/main/main.exe \
        delivery subtitle-check subtitles/*.srt \
        --profile ott-zh --fps 25 \
        --fail-on-error
  artifacts:
    when: always
    paths:
      - qc-report.json
```

## Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Check staged SRT/WebVTT files with MoonPost
MOONPOST="moon run cmd/main --target native --"

for file in $(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(srt|vtt)$'); do
  if [ -f "$file" ]; then
    echo "Checking $file..."
    $MOONPOST delivery subtitle-check "$file" --profile srt-basic --fail-on-error
    if [ $? -ne 0 ]; then
      echo "FAILED: $file has subtitle QC errors"
      exit 1
    fi
  fi
done
```

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks passed (or only Info-level findings) |
| `1` | `--fail-on-error` triggered by Error-level issues |
| `1` | `--fail-on-warning` triggered by Warning-level issues |
