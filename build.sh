#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="EyeRest"
BUILD_DIR="$PROJECT_DIR/.build"
APP_BUNDLE="$PROJECT_DIR/$APP_NAME.app"

echo "=== 编译 $APP_NAME ==="
cd "$PROJECT_DIR"
swift build -c release --arch arm64 --arch x86_64 2>/dev/null || swift build -c release

BINARY=$(find "$BUILD_DIR" -name "$APP_NAME" -type f | grep -i release | head -1)
if [ -z "$BINARY" ]; then
    echo "❌ 找不到编译产物"
    exit 1
fi
echo "✅ 编译完成: $BINARY"

echo "=== 创建 .app 包 ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Info.plist — LSUIElement=true 让 App 不出现在 Dock
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>EyeRest</string>
    <key>CFBundleExecutable</key>
    <string>EyeRest</string>
    <key>CFBundleIdentifier</key>
    <string>com.eyerest.app</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "✅ .app 创建完成: $APP_BUNDLE"
echo ""
echo "👉 双击 $APP_NAME.app 即可运行（菜单栏会出现 👁 图标）"
echo "👉 或拖入 /Applications 目录长期使用"
