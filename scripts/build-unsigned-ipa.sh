#!/usr/bin/env bash
# 把 Windows 导出的 Xcode 工程（OSS 上的 Unity-iPhone.tar.gz）编成未签名 ipa。
# 由 .github/workflows/build.yml 在 macOS runner 上调用；不需要任何证书/密钥。
set -euo pipefail

URL="${PROJECT_URL:-https://crossgate-assets.oss-cn-shanghai.aliyuncs.com/ios-xcode/Unity-iPhone.tar.gz}"

echo "== 环境 =="
xcodebuild -version || true
ls -d /Applications/Xcode*.app 2>/dev/null || true
sw_vers
df -h /

echo "== 下载工程 =="
mkdir -p "$RUNNER_TEMP/proj"
curl -fSL --retry 3 -o "$RUNNER_TEMP/proj.tar.gz" "$URL"
ls -lh "$RUNNER_TEMP/proj.tar.gz"
tar -xzf "$RUNNER_TEMP/proj.tar.gz" -C "$RUNNER_TEMP/proj"
test -d "$RUNNER_TEMP/proj/Unity-iPhone/Unity-iPhone.xcodeproj" || { echo "工程缺失"; exit 1; }

echo "== 编译（关闭签名）=="
cd "$RUNNER_TEMP/proj/Unity-iPhone"
OUT="$RUNNER_TEMP/out"; mkdir -p "$OUT"
xcodebuild \
  -project Unity-iPhone.xcodeproj \
  -target Unity-iPhone \
  -configuration Release \
  -sdk iphoneos \
  -jobs 4 \
  CONFIGURATION_BUILD_DIR="$OUT" \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=NO \
  IPHONEOS_DEPLOYMENT_TARGET=13.0 \
  CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO CODE_SIGN_IDENTITY="" \
  ENABLE_USER_SCRIPT_SANDBOXING=NO \
  COMPILER_INDEX_STORE_ENABLE=NO \
  build 2>&1 | tee "$RUNNER_TEMP/xcodebuild.log" | tail -40

APP="$(find "$OUT" -maxdepth 1 -name '*.app' -type d | head -1)"
test -n "$APP" || { echo "没有产出 .app"; ls -la "$OUT"; exit 1; }
du -sh "$APP"
test -f "$APP/Info.plist"
test -f "$APP/Frameworks/UnityFramework.framework/UnityFramework"
test -d "$APP/Data/Managed"

echo "== 打包未签名 ipa =="
cd "$RUNNER_TEMP"
rm -rf Payload && mkdir Payload
cp -R "$APP" Payload/
APPNAME="$(basename "$APP")"
rm -rf "Payload/$APPNAME/_CodeSignature" || true
rm -f  "Payload/$APPNAME/embedded.mobileprovision" || true
/usr/bin/zip -qry Unity-iPhone-unsigned.ipa Payload
ls -lh Unity-iPhone-unsigned.ipa
shasum -a 256 Unity-iPhone-unsigned.ipa
