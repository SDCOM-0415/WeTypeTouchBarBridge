# WeType Touch Bar Bridge

**让微信输入法（WeType）在配备 Touch Bar 的 MacBook Pro 上获得接近 macOS 原生拼音输入法的候选词体验。**

这是一款轻量级 macOS 菜单栏辅助程序：在微信输入法输入拼音时，将候选词实时同步到 Touch Bar，支持直接触摸选词。

> 本项目为独立社区作品，与腾讯、微信及 Apple 无官方关联。当前已在一台 **2018 款 Intel MacBook Pro（macOS Sequoia）** 上完成实际使用测试；并非所有系统或输入法版本都已验证。

## 实机效果

### Touch Bar 候选词栏

![微信输入法 Touch Bar 候选词效果](docs/touchbar-current.png)

### 在 macOS「文本编辑」中使用

![微信输入法、候选词窗口与 Touch Bar 同步展示](docs/wetype-textedit-demo.png)

上图来自项目实际运行截图，并非设计效果图。Touch Bar 候选词与微信输入法窗口中的候选词保持对应。

## 功能特性

- **实时同步候选词**：通过 macOS 辅助功能接口读取微信输入法候选窗口。
- **原生风格外观**：深蓝灰色连续背景、首选词高亮、圆角候选区域。
- **按文字实际宽度布局**：中文、英文和 Emoji 均可根据显示宽度分配空间。
- **候选词整体右对齐**：靠近右侧亮度、音量等系统控制区，同时保留系统 Control Strip。
- **横向滚动**：候选词过多时可以浏览后面的候选项。
- **触摸选词**：点击 Touch Bar 候选项，映射到微信输入法的候选编号执行选词。
- **性能诊断**：后台读取候选词并提供延迟分析日志。

## 运行环境

- 带实体 Touch Bar 的 MacBook Pro（目前在 2018 款 Intel 机型上验证）。
- macOS Sequoia 已实测；其他系统版本需要自行验证。
- 已安装并启用微信输入法（WeType），已知输入源标识：`com.tencent.inputmethod.wetype.pinyin`。
- Xcode Command Line Tools（无需安装完整 Xcode）。
- 在「系统设置 → 隐私与安全性 → 辅助功能」中授权本程序。

## 编译与启动

克隆仓库：

```bash
git clone https://github.com/SDCOM-0415/WeTypeTouchBarBridge.git
cd WeTypeTouchBarBridge
```

如尚未安装命令行开发工具：

```bash
xcode-select --install
```

构建并尝试启动：

```bash
chmod +x build.sh
./build.sh
```

编译产物位于：

```text
build/WeTypeTouchBarBridge.app
```

这是使用临时（ad-hoc）签名的实验性程序，**未经过 Apple 公证**。若 Finder 无法打开，可在确认并信任源码后从终端运行：

```bash
./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge
```

菜单栏出现「候7」表示辅助程序已启动。使用微信输入法输入拼音时，Touch Bar 会显示候选词。

不建议为了启动本程序而全局关闭 macOS Gatekeeper。

## 工作原理

1. 检测微信输入法进程与输入源。
2. 使用 `AXUIElement` 查询候选词窗口中的文本。
3. 后台采样候选变化，并在主线程更新 Touch Bar。
4. 通过 AppKit `NSScrubber` 绘制可滚动、动态宽度且右对齐的候选栏。
5. 将用户触摸的候选项映射为微信输入法对应的数字选词操作。

项目**不修改微信输入法安装包**，也不注入其进程。

## 已知限制与安全说明

- **使用了 Apple 未公开的 Touch Bar 系统模态接口**，系统更新可能导致显示功能失效。
- 依赖微信输入法辅助功能树的结构和候选编号，微信输入法升级后可能需要适配。
- 触摸选词通过模拟数字键完成，不保证兼容所有输入场景。
- 辅助功能权限可能读取到正在输入的文字，请仅在信任本项目源码时授权，分享诊断日志前请检查隐私内容。
- 目前主要是个人实机验证项目，没有提供通用、公证过的二进制安装包。
- 候选栏是对 Apple 原生体验的复刻，并非系统自带输入法内部组件。

## 项目文件

| 文件 | 用途 |
| --- | --- |
| `main.m` | Objective-C / AppKit 主程序 |
| `build.sh` | 一键构建与签名脚本 |
| `Info.plist` | 应用包配置 |
| `docs/` | 实际运行截图 |
| `LICENSE` | MIT 开源许可证 |

## 许可证

本项目使用 [MIT License](LICENSE)。
