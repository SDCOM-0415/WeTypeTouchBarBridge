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
- **更新提醒**：启动时检查更新，也可每 6 小时自动检查。

> **响应延迟提示：** 候选词依赖 macOS 辅助功能接口读取，可能随设备负载和输入法状态存在少量延迟。

## 运行环境

- 带实体 Touch Bar 的 MacBook Pro（目前在 2018 款 Intel 机型上验证）。
- macOS Sequoia 已实测；其他系统版本需要自行验证。
- 已安装并启用微信输入法（WeType），已知输入源标识：`com.tencent.inputmethod.wetype.pinyin`。
- 从源码编译需要 Xcode Command Line Tools（无需安装完整 Xcode）；直接下载预编译 App 则不需要。
- 在「系统设置 → 隐私与安全性 → 辅助功能」中授权本程序。

## 下载与安装

**下载最新版本：** [GitHub Releases（最新版）](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/releases/latest)，或使用 [CNB 镜像](https://cnb.cool/SDCOM/WeTypeTouchBarBridge/-/releases)；历史版本见 [GitHub Releases](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/releases)。

| 设备架构 | 预期安装包名称 | 适用设备 |
| --- | --- | --- |
| Intel（x86_64） | `WeTypeTouchBarBridge-x86_64.zip` | Intel Touch Bar MacBook Pro |
| Apple Silicon（arm64） | `WeTypeTouchBarBridge-arm64.zip` | Apple Silicon Touch Bar MacBook Pro |

1. 打开 [Releases](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/releases)，选择所需版本。
2. 在 **Assets** 中下载适合自己 Mac 架构的安装包（不要下载仅含源码的 **Source code**）。
3. 解压 ZIP，得到 `WeTypeTouchBarBridge.app`，建议移动到 `/Applications` 后启动。
4. 在「系统设置 → 隐私与安全性 → 辅助功能」中授予程序权限。输入拼音后，候选词会显示在 Touch Bar 上。
5. 如需开机启动，可在菜单栏「候1」启用「登录时启动」。

**安全与兼容性：** 安装包未使用 Apple Developer ID 签名或公证，macOS 可能提示拦截；请仅从可信来源下载，不建议全局关闭 Gatekeeper。2018 款 Intel Touch Bar Mac 已通过实机验证；Apple Silicon 版本已通过 CI 构建，但尚无对应 Touch Bar 设备的实测记录。

## 自动检查更新

启动时会检查 [CNB Releases](https://cnb.cool/SDCOM/WeTypeTouchBarBridge/-/releases) 是否有新版本，并在发现更新时弹出系统提示。默认每 6 小时自动检查一次，可在菜单栏「候1」中关闭自动检查或选择「立即检查更新」。程序只提示下载，不会自动安装。

## 从源码构建

需要 macOS 13+ 和 Xcode Command Line Tools。

```bash
git clone https://github.com/SDCOM-0415/WeTypeTouchBarBridge.git
cd WeTypeTouchBarBridge
./build.sh
```

构建脚本会提示选择安装位置。建议放在 `/Applications`，然后在系统设置中授予辅助功能权限；如需开机启动，可通过菜单栏「候1」→「登录时启动」启用。

维护者所需的双架构 CI、签名、版本发布与 CNB 镜像操作详见 [构建与发布维护说明](docs/MAINTAINER.md)。

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
- 由于第三方跨进程读取、刷新和按键转发机制，候选词显示及触摸选词可能比输入法原生集成方案略有延迟，无法保证完全实时。
- 辅助功能权限可能读取到正在输入的文字，请仅在信任本项目源码时授权，分享诊断日志前请检查隐私内容。
- 项目已发布 GitHub Release；v0.8 预编译包为 ad-hoc 签名，v1.0 起为固定自签测试证书签名，均未经 Apple 公证，也未做广泛机型验证。跨签名身份升级后可能需要重新授权辅助功能和登录项。
- 候选栏是对 Apple 原生体验的复刻，并非系统自带输入法内部组件。

## 项目文件

| 文件 | 用途 |
| --- | --- |
| `main.m` | Objective-C / AppKit 主程序 |
| `UpdateChecker.h` / `UpdateChecker.m` | 独立的自动更新检测模块 |
| `build.sh` | 一键构建与签名脚本 |
| `Info.plist` | 应用包配置 |
| `.github/workflows/build.yml` | 双架构 GitHub Actions 自动构建工作流 |
| `docs/` | 实际运行截图 |
| `LICENSE` | GNU GPLv3 开源许可证 |

## 许可证

本项目当前维护的代码采用 [GNU General Public License v3.0（GPL-3.0）](LICENSE) 授权。GPLv3 允许商业使用，但要求分发修改后的受保护程序时遵守相应的源码提供及相同许可证等义务。
