#!/bin/bash
# QNET Simple - 一键构建 IPA
# 使用: chmod +x build.sh && ./build.sh
# 需要: macOS + Xcode 13+ + XcodeGen (brew install xcodegen)

set -e

echo "🔨 QNET Simple - 开始构建..."

# 1. 生成 Xcode 项目
if ! command -v xcodegen &> /dev/null; then
    echo "安装 XcodeGen..."
    brew install xcodegen
fi

echo "📁 生成 Xcode 项目..."
cd "$(dirname "$0")"
xcodegen generate

# 2. 清理
rm -rf ./build ./QNET.xcarchive

# 3. 编译 archive（不签名）
echo "🏗️ 编译中..."
xcodebuild archive \
    -project QNET_Simple.xcodeproj \
    -scheme QNET \
    -archivePath ./QNET.xcarchive \
    -destination "generic/platform=iOS" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    DEVELOPMENT_TEAM="" \
    PROVISIONING_PROFILE_SPECIFIER="" \
    2>&1

# 4. 导出 IPA
echo "📦 打包 IPA..."
mkdir -p Payload
cp -R ./QNET.xcarchive/Products/Applications/QNET.app ./Payload/
zip -qr QNET_Simple.ipa Payload/
rm -rf Payload

# 5. 完成
IPA_SIZE=$(ls -lh QNET_Simple.ipa | awk '{print $5}')
echo "✅ 完成! QNET_Simple.ipa ($IPA_SIZE)"
echo ""
echo "📱 安装方法:"
echo "   1. 用 轻松签/AltStore 导入 QNET_Simple.ipa"
echo "   2. 签名时确保选择 支持 Network Extension 的证书"
echo "   3. 安装到 iPhone"
echo "   4. 设置 → 通用 → VPN与设备管理 → 信任证书"
echo "   5. 打开 QNET → 点开关 → VPN 连接"
