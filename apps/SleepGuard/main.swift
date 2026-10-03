import Cocoa
import Foundation

// MARK: - 数据模型
struct AssertionItem {
    let pid: Int
    let process: String
    let duration: String
    let type: String
    let name: String
    let targetApp: String?
    let targetPid: Int?
}

class AssertionChecker {
    static func check() -> (displayBlocked: Bool, systemBlocked: Bool, items: [AssertionItem]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g", "assertions"]

        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return (false, false, [])
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return (false, false, [])
        }

        var displayBlocked = false
        var systemBlocked = false
        var items: [AssertionItem] = []

        // 检查全局状态
        if output.contains("PreventUserIdleDisplaySleep    1") {
            displayBlocked = true
        }
        if output.contains("PreventUserIdleSystemSleep     1") || output.contains("PreventSystemSleep             1") {
            systemBlocked = true
        }

        // 解析进程段落
        guard let owningRange = output.range(of: "Listed by owning process:") else {
            return (displayBlocked, systemBlocked, items)
        }
        var owningText = String(output[owningRange.upperBound...])
        if let kernelRange = owningText.range(of: "Kernel Assertions:") {
            owningText = String(owningText[..<kernelRange.lowerBound])
        }

        let lines = owningText.components(separatedBy: .newlines)
        let headerRegex = try? NSRegularExpression(pattern: #"^\s*pid\s+(\d+)\(([^)]+)\):\s+\[0x[0-9a-fA-F]+\]\s+(\S+)\s+([A-Za-z0-9_]+)(?:\s+named:\s*\"(.*)\")?"#)

        var currentItem: (pid: Int, comm: String, dur: String, type: String, name: String)? = nil
        var currentTargetApp: String? = nil
        var currentTargetPid: Int? = nil

        for line in lines {
            let nsLine = line as NSString
            if let match = headerRegex?.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) {
                if let cur = currentItem {
                    items.append(AssertionItem(pid: cur.pid, process: cur.comm, duration: cur.dur, type: cur.type, name: cur.name, targetApp: currentTargetApp, targetPid: currentTargetPid))
                }
                let pid = Int(nsLine.substring(with: match.range(at: 1))) ?? 0
                let comm = nsLine.substring(with: match.range(at: 2))
                let dur = nsLine.substring(with: match.range(at: 3))
                let type = nsLine.substring(with: match.range(at: 4))
                var name = ""
                if match.numberOfRanges > 5 && match.range(at: 5).location != NSNotFound {
                    name = nsLine.substring(with: match.range(at: 5))
                }
                currentItem = (pid, comm, dur, type, name)
                currentTargetApp = nil
                currentTargetPid = nil
            } else if currentItem != nil && line.contains("Created for PID:") {
                let pidRegex = try? NSRegularExpression(pattern: #"Created for PID:\s*(\d+)"#)
                if let pMatch = pidRegex?.firstMatch(in: line, range: NSRange(location: 0, length: (line as NSString).length)) {
                    if let tPid = Int((line as NSString).substring(with: pMatch.range(at: 1))) {
                        currentTargetPid = tPid
                        currentTargetApp = getProcessName(pid: tPid)
                    }
                }
            }
        }

        if let cur = currentItem {
            items.append(AssertionItem(pid: cur.pid, process: cur.comm, duration: cur.dur, type: cur.type, name: cur.name, targetApp: currentTargetApp, targetPid: currentTargetPid))
        }

        return (displayBlocked, systemBlocked, items)
    }

    static func getProcessName(pid: Int) -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-p", "\(pid)", "-o", "comm="]
        let pipe = Pipe()
        task.standardOutput = pipe
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            return "PID \(pid)"
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if path.contains(".app") {
                let comps = path.components(separatedBy: "/")
                for c in comps where c.hasSuffix(".app") {
                    return c
                }
            }
            return (path as NSString).lastPathComponent
        }
        return "PID \(pid)"
    }
}

// MARK: - 状态栏应用委托
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    var statusItem: NSStatusItem!
    var timer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        updateStatus()

        // 每 5 秒自动检查一次状态
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }

    func updateStatus() {
        let (displayBlocked, _, _) = AssertionChecker.check()

        DispatchQueue.main.async {
            if let button = self.statusItem.button {
                if displayBlocked {
                    button.title = "🛑 屏常亮"
                    button.toolTip = "检测到有应用阻止屏幕熄灭！外接屏将常亮不熄。"
                } else {
                    button.title = "💤 正常"
                    button.toolTip = "屏幕休眠正常：空闲超时后显示器将正常熄灭。"
                }
            }
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        let (displayBlocked, _, items) = AssertionChecker.check()

        // 标题项
        let titleItem = NSMenuItem(title: "🖥️ 屏幕熄灭状态监控", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(NSMenuItem.separator())

        // 状态摘要
        let dispTitle = displayBlocked ? "🛑 屏幕熄灭：被阻止 (外接屏无法黑屏)" : "🟢 屏幕熄灭：正常 (空闲将自动熄屏)"
        let dispItem = NSMenuItem(title: dispTitle, action: nil, keyEquivalent: "")
        dispItem.isEnabled = false
        menu.addItem(dispItem)
        menu.addItem(NSMenuItem.separator())

        // 阻止屏幕休眠的应用
        let displayBlockers = items.filter { $0.type == "PreventUserIdleDisplaySleep" }
        if !displayBlockers.isEmpty {
            let header = NSMenuItem(title: "【阻止屏幕熄屏的进程】", action: nil, keyEquivalent: "")
            header.isEnabled = false
            menu.addItem(header)

            for item in displayBlockers {
                let name = item.targetApp ?? item.process
                let menuItem = NSMenuItem(title: "  ❌ \(name) (PID \(item.pid)) [\(item.duration)]", action: #selector(killProcessAction(_:)), keyEquivalent: "")
                menuItem.target = self
                menuItem.representedObject = item.pid
                menuItem.toolTip = "点击强制关闭此进程 (kill -9 \(item.pid))\n原因: \(item.name)"
                menu.addItem(menuItem)
            }
        } else {
            let okItem = NSMenuItem(title: "  ✅ 当前无任何应用阻止屏幕熄灭", action: nil, keyEquivalent: "")
            okItem.isEnabled = false
            menu.addItem(okItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 底部操作
        let refreshItem = NSMenuItem(title: "🔄 立即刷新", action: #selector(refreshAction), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(title: "退出 SleepGuard", action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc func killProcessAction(_ sender: NSMenuItem) {
        guard let pid = sender.representedObject as? Int else { return }
        let alert = NSAlert()
        alert.messageText = "是否强制终止此进程？"
        alert.informativeText = "\(sender.title.trimmingCharacters(in: .whitespaces))\n\n终止后该应用将立即退出。"
        alert.addButton(withTitle: "终止进程")
        alert.addButton(withTitle: "取消")
        if alert.runModal() == .alertFirstButtonReturn {
            kill(pid_t(pid), SIGKILL)
            updateStatus()
        }
    }

    @objc func refreshAction() {
        updateStatus()
    }

    @objc func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}

// 启动 App
let app = NSApplication.shared
app.setActivationPolicy(.accessory) // 菜单栏常驻模式，不显示 Dock 图标
let delegate = AppDelegate()
app.delegate = delegate
app.run()
