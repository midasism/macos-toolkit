#!/usr/bin/env bash
# ==============================================================================
# macOS Toolkit - 一键安装部署脚本
# ==============================================================================

set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "          macOS Toolkit 一键安装部署              "
echo "=================================================="
echo "1) 安装全部 (SleepGuard + ClipGuard)"
echo "2) 仅安装 SleepGuard (菜单栏外接屏防休眠排查工具)"
echo "3) 仅安装 ClipGuard (通用剪贴板自愈与守护工具)"
echo "q) 退出"
echo "=================================================="
read -r -p "请选择安装选项 [1/2/3/q]: " choice

install_sleepguard() {
    echo ""
    echo "▶ 正在安装 SleepGuard..."
    "${DIR}/apps/SleepGuard/build.sh" install
}

install_clipguard() {
    echo ""
    echo "▶ 正在安装 ClipGuard..."
    mkdir -p "$HOME/.local/bin"
    cp "${DIR}/scripts/ClipGuard/clipguard" "$HOME/.local/bin/clipguard"
    chmod +x "$HOME/.local/bin/clipguard"
    ln -sf "$HOME/.local/bin/clipguard" "$HOME/.local/bin/clipfix"
    "$HOME/.local/bin/clipguard" install
}

case "$choice" in
    1)
        install_sleepguard
        install_clipguard
        echo ""
        echo "🎉 全部工具安装完成！"
        ;;
    2)
        install_sleepguard
        ;;
    3)
        install_clipguard
        ;;
    q|Q)
        echo "已取消安装。"
        exit 0
        ;;
    *)
        echo "无效选项，安装终止。"
        exit 1
        ;;
esac
