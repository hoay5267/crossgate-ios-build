# crossgate-ios-build（公开）

Codemagic 免费额度用完后的**备用 iOS 编译通道**：用 GitHub Actions 的 macOS runner 把
Windows 导出的 Xcode 工程编成**未签名 ipa**，供 Windows + Sideloadly 用免费 Apple ID 重签装机。

> 公开仓库的 macOS runner 分钟数免费、不限次数。本仓库**不含任何证书/密钥/游戏源码**。

## 一次性配置（只需 1 分钟，网页操作）

1. 本仓库 → `Add file` → `Create new file`
2. 文件名填：`.github/workflows/build.yml`
3. 内容粘贴：

```yaml
name: iOS unsigned ipa
on:
  workflow_dispatch:
    inputs:
      project_url:
        description: "Xcode 工程 tar.gz URL（留空用默认 OSS 地址）"
        required: false
        default: ""
jobs:
  build:
    runs-on: macos-14
    timeout-minutes: 90
    steps:
      - uses: actions/checkout@v4
      - name: Build unsigned ipa
        env:
          PROJECT_URL: ${{ github.event.inputs.project_url }}
        run: bash scripts/build-unsigned-ipa.sh
      - uses: actions/upload-artifact@v4
        with:
          name: ios-unsigned-ipa
          path: |
            ${{ runner.temp }}/Unity-iPhone-unsigned.ipa
            ${{ runner.temp }}/xcodebuild.log
          retention-days: 14
```

4. Commit 到 `main`

## 用法

Actions → `iOS unsigned ipa` → **Run workflow** → 跑完在 Artifacts 下载 `ios-unsigned-ipa`。

## 注意

- 工程包 224MB，每次构建都会重新下载
- Unity 的 AOT 层（il2cpp / 桥接）必须与热更包**同批次**；换工程时三件套要一起换
- `ENABLE_USER_SCRIPT_SANDBOXING=NO` 不能去掉（Xcode 15+ 的脚本沙箱会打断 Unity 的 `process_symbols.sh`）
