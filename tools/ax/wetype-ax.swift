import AppKit
import ApplicationServices

let bundleID = "com.tencent.inputmethod.wetype"

guard AXIsProcessTrusted() else {
    print("没有辅助功能权限。")
    print("请在 系统设置 > 隐私与安全性 > 辅助功能")
    print("允许 Terminal，然后重新运行。")
    exit(1)
}

let apps = NSRunningApplication.runningApplications(
    withBundleIdentifier: bundleID
)

guard let app = apps.first else {
    print("未找到微信输入法进程")
    exit(1)
}

print("WeType PID: \(app.processIdentifier)")

let root = AXUIElementCreateApplication(
    app.processIdentifier
)
AXUIElementSetMessagingTimeout(root, 2)

func attribute(
    _ element: AXUIElement,
    _ name: String
) -> Any? {
    var value: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(
        element,
        name as CFString,
        &value
    )
    return result == .success ? value : nil
}

func walk(
    _ element: AXUIElement,
    depth: Int = 0
) {
    guard depth <= 5 else { return }

    let role = attribute(element, "AXRole") as? String ?? "?"
    let title = attribute(element, "AXTitle") as? String ?? ""
    let value = attribute(element, "AXValue") as? String ?? ""
    let desc = attribute(element, "AXDescription") as? String ?? ""

    let indent = String(repeating: "  ", count: depth)

    print("\(indent)Role: \(role)")
    if !title.isEmpty {
        print("\(indent)  Title: \(title)")
    }
    if !value.isEmpty {
        print("\(indent)  Value: \(value)")
    }
    if !desc.isEmpty {
        print("\(indent)  Description: \(desc)")
    }

    var actions: CFArray?
    if AXUIElementCopyActionNames(element, &actions) == .success,
       let names = actions as? [String],
       !names.isEmpty {
        print("\(indent)  Actions: \(names)")
    }

    if let children = attribute(
        element, "AXChildren"
    ) as? [AXUIElement] {
        for child in children.prefix(40) {
            walk(child, depth: depth + 1)
        }
    }
}

if let windows = attribute(root, "AXWindows") as? [AXUIElement] {
    print("发现 \(windows.count) 个窗口")
    for window in windows.prefix(10) {
        walk(window)
    }
} else {
    print("无法获取 AXWindows")
}