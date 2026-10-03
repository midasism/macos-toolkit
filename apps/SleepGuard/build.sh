#!/usr/bin/env bash
# ==============================================================================
# SleepGuard - 构建与安装脚本
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="SleepGuard"
APP_BUNDLE="${DIR}/${APP_NAME}.app"
MACOS_DIR="${APP_BUNDLE}/Contents/MacOS"
TARGET_DIR="/Applications"

do_build() {
    echo "🔨 正在编译 ${APP_NAME}..."
    mkdir -p "${MACOS_DIR}"

    swiftc "${DIR}/main.swift" -o "${MACOS_DIR}/${APP_NAME}" -O

    cat <<EOF > "${APP_BUNDLE}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.midas.${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

    echo "✅ 编译成功！应用已生成: ${APP_BUNDLE}"
}

do_install() {
    do_build
    echo "📦 正在安装到 ${TARGET_DIR}/${APP_NAME}.app..."
    pkill -x "${APP_NAME}" 2>/dev/null || true
    rm -rf "${TARGET_DIR}/${APP_NAME}.app"
    cp -R "${APP_BUNDLE}" "${TARGET_DIR}/"
    echo "🚀 正在启动应用..."
    open "${TARGET_DIR}/${APP_NAME}.app"
    echo "🎉 安装完成并已启动！可在右上角菜单栏查看。"
}

do_clean() {
    echo "🧹 清理编译产物..."
    rm -rf "${APP_BUNDLE}"
    echo "完成。"
}

case "${1:-}" in
    install)
        do_install
        ;;
    clean)
        do_clean
        ;;
    build|"")
        do_build
        ;;
    *)
        echo "用法: $0 [build|install|clean]"
        exit 1
        ;;
esac
