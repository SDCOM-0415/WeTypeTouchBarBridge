import AppKit
import ApplicationServices
import Foundation
import Darwin

let bundleID = "com.tencent.inputmethod.wetype"

guard AXIsProcessTrusted() else {
    print("""
    [ERROR] 没有辅助功能权限。

    请打开：
    系统设置 > 隐私与安全性 > 辅助功能

    允许 Terminal，然后重新运行。
    """)
    exit(1)
}

func readAX(
    _ element: AXUIElement,
    _ attribute: String
) -> Any? {
    var value: CFTypeRef?

    let status = AXUIElementCopyAttributeValue(
        element,
        attribute as CFString,
        &value
    )

    guard status == .success else {
        return nil
    }

    return value
}

func collectCandidates(
    from element: AXUIElement,
    depth: Int = 0
) -> [String] {
    guard depth <= 6 else {
        return []
    }

    var results: [String] = []

    let role = readAX(
        element, "AXRole"
    ) as? String ?? ""

    let value = readAX(
        element, "AXValue"
    ) as? String ?? ""

    if role == "AXStaticText",
       !value.isEmpty {
        results.append(value)
    }

    if let children = readAX(
        element, "AXChildren"
    ) as? [AXUIElement] {

        for child in children.prefix(60) {
            results.append(
                contentsOf: collectCandidates(
                    from: child,
                    depth: depth + 1
                )
            )
        }
    }

    return results
}

func getCandidates() -> [String] {
    guard let app = NSRunningApplication
        .runningApplications(
            withBundleIdentifier: bundleID
        ).first else {
        return []
    }

    let root = AXUIElementCreateApplication(
        app.processIdentifier
    )

    AXUIElementSetMessagingTimeout(root, 1.0)

    guard let windows = readAX(
        root, "AXWindows"
    ) as? [AXUIElement] else {
        return []
    }

    var values: [String] = []

    for window in windows.prefix(5) {
        values.append(
            contentsOf: collectCandidates(
                from: window
            )
        )
    }

    // 过滤 1～9 的候选序号
    return values.filter { value in
        let trimmed = value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        if trimmed.isEmpty {
            return false
        }

        if trimmed.count == 1,
           let character = trimmed.first,
           character.isNumber {
            return false
        }

        return true
    }
}

print("""
========================================
 WeType Candidate Watch
 微信输入法 Touch Bar 桥接前置测试
========================================

输入法：\(bundleID)
刷新间隔：300ms

请切换到文本编辑器输入拼音。
候选变化会自动显示在这里。

按 Ctrl+C 退出。

========================================
""")

var lastSnapshot = ""
var lastPID: pid_t = 0

while true {
    let apps = NSRunningApplication
        .runningApplications(
            withBundleIdentifier: bundleID
        )

    if let app = apps.first {
        let pid = app.processIdentifier

        if pid != lastPID {
            print("[INFO] 检测到微信输入法 PID: \(pid)")
            lastPID = pid
        }
    } else if lastPID != 0 {
        print("[WARN] 微信输入法进程已退出")
        lastPID = 0
    }

    let candidates = getCandidates()
    let snapshot = candidates.joined(
        separator: " | "
    )

    if snapshot != lastSnapshot {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        let timestamp = formatter.string(
            from: Date()
        )

        if snapshot.isEmpty {
            print("[\(timestamp)] 候选窗口已关闭")
        } else {
            print("[\(timestamp)] \(snapshot)")
        }

        fflush(stdout)
        lastSnapshot = snapshot
    }

    Thread.sleep(forTimeInterval: 0.3)
}