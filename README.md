# WeType Touch Bar Bridge v0.7 · 右对齐候选栏

在 v0.6 已验证可用的背景高亮、动态文字宽度、候选点击映射、后台轮询与性能日志基础上，**将候选词整体靠右排列**，使最后一项尽量贴近右侧系统亮度/音量控制条。

## 本版变化

- 使用 `TrailingCandidateHost` 容器，在每次候选词更新后测量总宽度，设置 `NSScrubber` 的可见宽度并靠右摆放。
- 候选词较少时，空白留在左侧；候选词较多、超过可用宽度时，Scrubber 占满容器并保留水平滚动。
- 继续保留 v0.6 的深蓝灰背景、第一候选词高亮、点击数字键映射以及后台 100ms AX 读取与 `[Perf]` 日志。
- 菜单栏标识改为 `候7`，以确认是新版本。

## 安装

解压后在该目录运行：

```bash
chmod +x build.sh
./build.sh
```

macOS Gatekeeper 如不允许 Finder 启动，可从终端直接运行：

```bash
./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge
```

## 已知边界

- Apple 私有的系统模态 Touch Bar 显示接口，在不同 macOS 版本上可能变化。
- `NSScrubber` 的滚动和布局依赖 AppKit；右对齐容器方案在无物理 Touch Bar 的构建环境中无法实机验证。
- 这里的“靠右”是相对于 Touch Bar **候选栏可用容器**右缘，不会覆盖右侧系统控制条。
- 采用背景程序的 AX 窗口读数；请勿在输入密码等敏感内容时启用调试日志。
