# 📋 ClipGuard

macOS 系统通用剪贴板（Universal Clipboard）健康监控、异常自愈与跨设备分发工具。

---

## 🎯 痛点背景

macOS 的跨设备剪贴板同步（Universal Clipboard / 接力 Handoff）是一个极其实用的功能，但在日常使用中经常遭遇“断连假死”：
- 电脑**合盖休眠唤醒**、**Wi-Fi 网络切换**、**蓝牙重连**或**开机数周不重启**后，设备间无法再粘贴内容；
- 其核心通信服务（`sharingd`、`useractivityd`、`pboard`）往往进入静默死锁状态，**进程不崩溃也不报错**，导致系统的守护机制不会重新拉起它们；
- 用户不得不手动在终端执行杀进程命令来恢复。

`ClipGuard` 通过后台常驻巡检、死锁探针检测与自动自愈机制，让两台 Mac 间的剪贴板恢复持久稳定的同步体验。

---

## ✨ 核心特性

- **多维健康巡检**：
  - 进程存活检查：实时监控 `sharingd`、`useractivityd`、`pboard` 进程状态；
  - 剪贴板响应探针：使用超时探针检测 `pbpaste` 响应，超时立即判定死锁；
  - 硬件与系统配置检测：监测蓝牙、Wi-Fi 及系统 Handoff 接力开关。
- **自动自愈（Auto-Healing）**：
  - 判定服务卡死后，自动平滑重启相关服务（`killall -TERM`），触发系统 `launchd` 生成干净实例，并刷新无线直连（AWDL）通道。
- **macOS 原生通知**：
  - 自动修复后通过系统通知中心弹出横幅提醒与音效，避免用户困惑。
- **零资源后台常驻**：
  - 依托系统原生 `LaunchAgent` 驱动，每 5 分钟轻量巡检一次，平时占用 0 CPU 与 0 额外常驻内存。
- **Tailscale Taildrop 快速分发**：
  - 内置 `clipguard send`，一键通过 Tailscale 将脚本同步给局域网/异地的另一台 Mac 设备。

---

## 🚀 快速上手

### 1. 安装与启动守护
```bash
# 复制或软链接至 PATH 路径
mkdir -p ~/.local/bin
cp clipguard ~/.local/bin/
chmod +x ~/.local/bin/clipguard
ln -sf ~/.local/bin/clipguard ~/.local/bin/clipfix

# 一键注册为系统后台开机自启守护（每 5 分钟巡检）
~/.local/bin/clipguard install
```

### 2. 常用命令
```bash
clipguard status        # 查看当前剪贴板进程状态、响应耗时与接力配置
clipfix                 # 随时一键强制重置剪贴板同步（秒级自愈）
clipguard check         # 执行单次巡检（若异常则自动重置并弹窗通知）
clipguard send [目标]   # 通过 Tailscale (Taildrop) 一键发送给另一台 Mac
clipguard uninstall     # 卸载后台守护服务
```
