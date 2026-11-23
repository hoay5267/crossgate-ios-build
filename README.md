# crossgate-ios-build（公开）

Codemagic 免费额度用完后的**备用 iOS 编译通道**。公开仓库的 GitHub Actions macOS 分钟数免费、不限次数。

## 用途

把 Windows 上导出的 Xcode 工程（`Unity-iPhone.tar.gz`，托管在 OSS）编成**未签名 ipa**，
供 Windows + Sideloadly 用免费 Apple ID 重签后装到 iPhone。

**不需要任何证书 / 密钥**（纯未签名构建），所以可以公开。

## 用法

1. Actions → `iOS unsigned ipa` → Run workflow
2. 可改 `project_url`（默认指向 OSS 上的最新工程）
3. 跑完在 Artifacts 下载 `ios-unsigned-ipa`

## 注意

- 本仓库只有 workflow，不含游戏源码
- 工程包体积 224MB，每次构建都会重新下载
- Unity 工程的 AOT 层（il2cpp/桥接）必须与热更包同批次，更新工程时三件套要一起换
