import AppKit
import ApplicationServices
import Foundation
import Darwin

let bundleID = "com.tencent.inputmethod.wetype"

guard AXIsProcessTrusted() else {
    print("请先授予 Terminal 辅助功能权限")
    exit(1)
}

let interval: TimeInterval = 0.1

func readAX(_ element: AXUIElement, _ name: String) -> Any? {
    var value: CFTypeRef?
    let status = AXUIElementCopyAttributeValue(
        element,
        name as CFString,
        &value
    )
    return status == .success ? value : nil
}

func collect(
    _ element: AXUIElement,
    depth: Int = 0
) -> [String] {
    guard depth <= 6 else { return [] }

    var result: [String] = []
    let role = readAX(element, "AXRole") as? String ?? ""
    let value = readAX(element, "AXValue") as? String ?? ""

    if role == "AXStaticText" && !value.isEmpty {
        result.append(value)
    }

    if let children = readAX(element, "AXChildren") as? [AXUIElement] {
        for child in children.prefix(60) {
            result += collect(child, depth: depth + 1)
        }
    }

    return result
}

func getCandidates() -> [String] {
    guard let app = NSRunningApplication
        .runningApplications(withBundleIdentifier: bundleID)
        .first else { return [] }

    let root = AXUIElementCreateApplication(app.processIdentifier)
    AXUIElementSetMessagingTimeout(root, 1)

    guard let windows = readAX(root, "AXWindows") as? [AXUIElement]
    else { return [] }

    var values: [String] = []
    for window in windows.prefix(5) {
        values += collect(window)
    }

    return values.filter {
        !$0.isEmpty &&
        !($0.count == 1 && $0.first?.isNumber == true)
    }
}

var last = ""
var samples: [Double] = []

print("=== WeType Accessibility 性能测试 ===")
print("采样间隔：100ms")
print("切换到其他 App 输入拼音，按 Ctrl+C 结束")
print("注意：AX 耗时不等于按键到候选词出现的端到端延迟")
print("------------------------------------")

while true {
    let start = ProcessInfo.processInfo.systemUptime
    let words = getCandidates()
    let elapsed = (ProcessInfo.processInfo.systemUptime - start) * 1000

    samples.append(elapsed)

    let snapshot = words.joined(separator: " | ")

    if snapshot != last {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )

        print(String(
            format: "[%@] AX %.1fms | %@",
            timestamp,
            elapsed,
            snapshot.isEmpty ? "(候选窗口关闭)" : snapshot
        ))
        fflush(stdout)
        last = snapshot
    }

    if samples.count >= 100 {
        let sorted = samples.sorted()
        let avg = samples.reduce(0, +) / Double(samples.count)
        let p95 = sorted[Int(Double(sorted.count - 1) * 0.95)]

        print(String(
            format: "[统计] AVG %.1fms | P95 %.1fms | MAX %.1fms",
            avg, p95, sorted.last ?? 0
        ))
        fflush(stdout)
        samples.removeAll()
    }

    let duration = ProcessInfo.processInfo.systemUptime - start
    Thread.sleep(forTimeInterval: max(0, interval - duration))
}