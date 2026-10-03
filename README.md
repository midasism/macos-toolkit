# 🧰 macOS Toolkit

> 专为 macOS 打造的原生、轻量、开箱即用的**系统痛点自愈与极客工具箱**。零外部臃肿依赖，极低资源占用。

---

## 💡 为什么需要这个项目？

macOS 在日常使用与多设备联动中非常优雅，但在深度使用或多显示器工作流下，经常伴随一些令人头疼的**隐蔽系统顽疾**：
1. **外接显示器休眠不熄屏**：Mac 达到休眠时间后，外接屏常常停留在锁屏页面常亮不熄灭，往往是某些应用未释放电源断言导致，排查繁琐；
2. **跨设备通用剪贴板频繁假死**：合盖休眠唤醒、切换网络或数周不关机后，多台 Mac 间的 Universal Clipboard 容易静默断连，无报错却无法粘贴；

这些问题往往没有直观的图形化提示，每次都需要在终端执行复杂的诊断命令。

**`macos-toolkit`** 旨在将这些痛点的诊断、监控与自愈逻辑沉淀为简单、原生的轻量工具，支持一键部署到任意 Mac 设备上。

---

## 📦 工具列表

### 1. 🛡️ [SleepGuard](apps/SleepGuard/)
> **位置**：`apps/SleepGuard/`  
> **形态**：原生 Swift 编写的极简菜单栏应用（常驻状态栏）

- **痛点解决**：实时监控外接屏熄屏阻止断言（`PreventUserIdleDisplaySleep`）。
- **极简两态**：
  - `💤 正常`：无进程阻碍，空闲后外接屏正常熄灭待机。
  - `🛑 屏常亮`：检测到阻碍熄屏的进程。
- **一键杀进程**：点击下拉菜单直接定位具体 App 及阻碍时长，支持一键强制结束进程（`kill -9`）。
- **极低开销**：单文件 Swift 原生编译，内存占用 < 15MB，CPU 占用趋近 0。

---

### 2. 📋 [ClipGuard](scripts/ClipGuard/)
> **位置**：`scripts/ClipGuard/`  
> **形态**：Bash 守护脚本 + LaunchAgent 定时巡检 + CLI 工具

- **痛点解决**：解决 macOS 跨设备通用剪贴板（Universal Clipboard）断连假死。
- **健康探针**：
  - 进程存活监控：监控 `sharingd`、`useractivityd`、`pboard`；
  - 响应探针：以超时探针测试 `pbpaste` IPC 响应速度，识别假死死锁。
- **自动自愈**：检测到异常时自动重启服务重建干净 Session，并通过 macOS 原生通知中心提醒用户。
- **终端快捷指令**：提供 `clipfix` 随时一键秒级重置剪贴板同步。
- **跨机极速分发**：内置 `clipguard send`，基于 Tailscale (Taildrop) 一键把脚本投递给局域网/异地的其他 Mac 设备。

---

## 🚀 一键安装

克隆仓库后，运行根目录安装向导即可：

```bash
git clone https://github.com/midasism/macos-toolkit.git
cd macos-toolkit
chmod +x install.sh
./install.sh
```

可根据终端提示选择安装全部工具，或仅安装指定模块。

---

## 📂 仓库结构

```text
macos-toolkit/
├── apps/
│   └── SleepGuard/             # 菜单栏外接屏防休眠排查应用
│       ├── main.swift          # Swift 源码
│       ├── build.sh            # 独立构建与安装脚本
│       └── README.md           # 详细使用说明
├── scripts/
│   └── ClipGuard/              # 通用剪贴板自愈守护工具
│       ├── clipguard           # 主执行脚本与 CLI
│       ├── com.midas.clipguard.plist # LaunchAgent 定时巡检配置
│       └── README.md           # 详细使用说明
├── install.sh                  # 根目录一键安装脚本
├── .gitignore
├── LICENSE                     # MIT 许可证
└── README.md                   # 汇总说明文档
```

---

## 📄 License

本项目采用 [MIT License](LICENSE) 授权。
