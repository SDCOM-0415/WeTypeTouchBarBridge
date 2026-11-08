# 微信输入法辅助功能测试脚本

这里保留 WeType Touch Bar Bridge 开发早期用于验证 **macOS Accessibility (AX) 能否读取微信输入法候选窗口** 的原始 Swift 脚本。它们是实验与排障工具，不属于正式 App，也不会被 `build.sh` 或 GitHub Actions 的 macOS 构建任务编译。

| 脚本 | 用途 |
| --- | --- |
| [`wetype-ax.swift`](wetype-ax.swift) | 一次性遍历微信输入法的 AX 窗口树，打印 Role、Title、Value、Description 和 Actions（深度最多 5 层；每层最多 40 个子节点）。 |
| [`wetype-watch-legacy-300ms.swift`](wetype-watch-legacy-300ms.swift) | 早期的 300ms 周期候选监视器；候选变化时输出时间戳和内容，并报告输入法进程启动/退出。对应上传的原始 `wetype-watch.swift.bak`，仅为归档改名。 |
| [`wetype-watch.swift`](wetype-watch.swift) | 后续 100ms 周期采样工具；检测候选变化，并每 100 次查询统计 AX 查询耗时 AVG/P95/MAX。 |

## 使用方法

需要在**带有实体 Touch Bar 的 macOS 设备上**安装并启动微信输入法，并在「系统设置 → 隐私与安全性 → 辅助功能」中允许用于运行脚本的终端（例如 Terminal）。这些脚本本身不需要 Touch Bar 才能读取 AX，但它们原本用于 Touch Bar 项目的前期验证。

进入仓库根目录后，可按需运行其中一个：

```bash
swift tools/ax/wetype-ax.swift
swift tools/ax/wetype-watch.swift
# 或运行旧版 300ms 监视器
swift tools/ax/wetype-watch-legacy-300ms.swift
```

监视器会持续运行，按 `Ctrl+C` 停止。它们只读取当前 WeType 的 AX 树，不注入输入法进程，也不修改输入法设置。

> **隐私提醒：** 脚本会在终端输出候选文字；不要在测试时输入密码、私密文本等敏感内容，分享运行日志前也要检查候选文字。AX 查询耗时不代表从按键到候选显示的端到端延迟。

## 与正式程序的关系

这些脚本展示了最初的探索路线：先验证候选窗口的 AX 属性，再观察候选变化与 AX 采样耗时。正式程序已在 Objective-C 中实现独立的轮询、界面显示和触摸选词逻辑；**不要把这里的旧参数或测试算法当作正式程序的当前行为**。
