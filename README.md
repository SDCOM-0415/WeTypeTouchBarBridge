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

> **响应延迟提示：** 本项目是独立于微信输入法的第三方辅助 App，并非输入法内置的 Touch Bar 组件。候选词需要通过 macOS 辅助功能接口读取并同步到 Touch Bar，触摸选词也需要通过模拟按键转交给输入法处理，因此在显示候选词和触摸上屏时可能存在一定延迟；实际体验会随系统负载、设备及输入法状态而变化。
- **性能诊断**：后台读取候选词并提供延迟分析日志。

## 运行环境

- 带实体 Touch Bar 的 MacBook Pro（目前在 2018 款 Intel 机型上验证）。
- macOS Sequoia 已实测；其他系统版本需要自行验证。
- 已安装并启用微信输入法（WeType），已知输入源标识：`com.tencent.inputmethod.wetype.pinyin`。
- 从源码编译需要 Xcode Command Line Tools（无需安装完整 Xcode）；直接下载预编译 App 则不需要。
- 在「系统设置 → 隐私与安全性 → 辅助功能」中授权本程序。

## 下载与安装（GitHub Releases）

**v1.0 已发布，请前往** [GitHub Releases（最新版）](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/releases/latest)，也可以在 [全部 Releases](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/releases) 查看历史发布记录和更新说明。

| 设备架构 | 预期安装包名称 | 适用设备 |
| --- | --- | --- |
| Intel（x86_64） | `WeTypeTouchBarBridge-x86_64.zip` | Intel Touch Bar MacBook Pro |
| Apple Silicon（arm64） | `WeTypeTouchBarBridge-arm64.zip` | Apple Silicon Touch Bar MacBook Pro |

1. 打开 [Releases](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/releases)，选择所需版本。
2. 在该 Release 的 **Assets** 中选择适合自己 Mac 架构的安装包（若发布者已附加）；注意 GitHub 自动生成的 **Source code** 压缩包仅包含源码，并非预编译 App。
3. 新发布流程的 Release 安装 ZIP 解压一次即可得到 `WeTypeTouchBarBridge.app`，建议移动到 `/Applications` 后启动。历史版本的部分 Release 使用了 Actions Artifact 包装，可能需要解压两次。
4. 在「系统设置 → 隐私与安全性 → 辅助功能」中授予程序权限。输入拼音后，候选词会显示在 Touch Bar 上。
5. 需要登录时启动时，可在菜单栏「候1」中自行启用该选项。

如果某次 Release 尚未附上对应架构的预编译 ZIP，可在 [GitHub Actions 构建记录](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/actions/workflows/build.yml) 找到成功运行的 `x86_64` / `arm64` Artifacts，或按下文自行从源码编译。Actions Artifact 的保留期限有限，下载可能需要登录 GitHub。

**安全与兼容性：** v0.8 的预编译包使用 ad-hoc 签名；v1.0 起的预编译包使用固定自签测试证书（WeTypeTouchBarBridge Developer）。本地 `build.sh` 仍使用 ad-hoc 签名。两种方式都不是 Apple Developer ID 签名，也没有进行 Apple 公证，macOS 可能拦截启动；请仅在核对并信任项目来源后运行，不建议全局关闭 Gatekeeper。Intel Touch Bar Mac 已有实机验证，arm64 目前仅完成 CI 构建测试，尚未在 Apple Silicon Touch Bar 设备上验证。

## GitHub Actions 构建与发布

### 版本分支自动发布

从包含当前工作流的 `main` 创建 `v1.1`、`v1.1.0` 等版本分支并推送时，Actions 会自动构建 `x86_64` 和 `arm64`。两个架构构建成功且版本校验通过后，自动创建**与分支同名**的 Git Tag 和 GitHub Release，Release 标题也是完整分支名（如 `v1.1`），无需手动填写 Tag。标签支持两段或三段版本号，`v1.1` 对应 `Info.plist` 中的 `1.1.0`。

版本分支之后再次推送时仍会构建并上传新的 Actions Artifacts，**但已有 Tag / Release 保持不可变，不自动覆盖已发布资产**。要发布新的正式版本，请创建新的版本分支并调整 `Info.plist` 版本。若已有同名 Tag 但未创建 Release，只有该 Tag 指向本次构建的同一提交时才允许补发。标签推送仍只构建，不会重复触发发布。

**注意：** 触发 `push` 工作流的版本分支本身必须包含新版 `.github/workflows/build.yml`。过去的历史版本分支未必有此文件配置，不会因为仅修改 `main` 就自动获得新的触发行为；不要为此改写已发布的历史分支或标签。

### 手动构建与发布

在 [Build macOS 工作流](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/actions/workflows/build.yml) 点击 **Run workflow**：

- **publish_release**（默认 false）：仅构建两个架构并上传 Actions Artifacts；勾选后在成功构建、版本校验和产物校验通过时发布 Release。
- **release_tag**：手动发布时填写，如 `v1.1` 或 `v1.1.0`，版本必须匹配当前分支的 `Info.plist`。

正式发布时会直接上传 `WeTypeTouchBarBridge-x86_64.zip`、`WeTypeTouchBarBridge-arm64.zip` 和 `SHA256SUMS`。安装包 ZIP 内直接包含 `.app`，不再嵌套 Actions Artifact。签名采用固定自签测试证书，不等同于 Apple Developer ID 签名或公证；首次配置需提供仓库证书 Secrets。

### CNB Release 安装包镜像

新版本成功发布 GitHub Release 后，`build.yml` 还会运行 **Mirror published ZIPs to CNB Release**：重用这一次 macOS 双架构构建的 Artifacts，从 GitHub Release 下载原始 `SHA256SUMS` 并验证文件哈希；随后将同名 Tag 推送到 CNB。CNB 根目录的 [`.cnb.yml`](.cnb.yml) 使用官方 `git:release` 内置任务创建同名 Release（不重新编译），GitHub Actions 再运行官方 `cnbcool/attachments:latest` 容器上传 **x86_64 ZIP、arm64 ZIP 和 SHA256SUMS**。如果 CNB 的 Release 创建有延迟，上传任务会自动重试；最终同步失败会明确显示为 GitHub Actions 中 CNB 镜像任务失败，但不会删除已成功发布的 GitHub Release。

CNB 附件使用 CNB OpenAPI 权限，与 Git 仓库 push 的权限是两回事。需要在 CNB 创建两个最小权限访问令牌（或一枚同时具有两项权限的令牌），分别配置 GitHub Actions Secrets：

- `CNB_GIT_TOKEN`：`repo-code:rw`，允许推送 Tag 和其他 Git 引用；原先全量镜像已在使用。
- `CNB_RELEASE_TOKEN`：`repo-contents:rw`，用于 CNB Release 附件上传。**只有 `repo-code:rw` 不够**。按照 [CNB 附件插件说明](https://cnb.cool/wmde/attachments) 配置。

在你的 Mac 上交互式写入新令牌（不把令牌放到命令行参数或聊天中）：

```bash
gh secret set CNB_RELEASE_TOKEN --repo SDCOM-0415/WeTypeTouchBarBridge
```

目标仓库必须是 `SDCOM/WeTypeTouchBarBridge`，令牌需拥有该仓库相关权限。**CNB 镜像附件只针对新创建的 GitHub Release 运行**，不会覆盖已有版本，也不会自动补齐历史 Release。首次使用请从包含 `.cnb.yml` 的源码创建新版本分支并发布，历史标签的代码快照可能还没有这份 CNB 配置文件。CNB Git 镜像不包括 GitHub Release 附件，附件通过上述独立上传步骤传输。

## 自动检查更新

更新检测逻辑独立放在 `UpdateChecker.h` / `UpdateChecker.m`，`main.m` 只负责初始化模块和接入菜单；本地 `build.sh` 与 GitHub Actions 均同时编译两个 Objective-C 源文件。

程序启动时会通过 GitHub Releases API 检查一次最新正式版；如果发现比本机版本更新的 Release，会以和辅助功能授权提示相同风格的 macOS `NSAlert` 提示，可选择「前往下载」或「稍后」。默认启用「自动检查更新（每 6 小时）」，可在菜单栏「候1」中切换开关（偏好设置会被保存），也可随时点击「立即检查更新」。

关闭自动检查仅停止后续每 6 小时的轮询，**每次程序启动仍检查一次**；检查在后台异步执行，网络失败不会阻碍 Touch Bar 输入或自动安装任何内容。程序只请求公开的 GitHub Release 元数据，不上传候选词或输入内容。检测到同一新版本后，当前运行会话不会反复提示。未重新发布新版 App 之前，旧版二进制不会自动获得此功能。

## GitHub → CNB 全分支镜像

新增工作流 [Mirror all Git refs to CNB](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/actions/workflows/sync-cnb.yml)，在 GitHub 推送任意分支、标签或版本构建工作流完成后自动执行，也支持手动触发。

同步目标：[CNB / SDCOM / WeTypeTouchBarBridge](https://cnb.cool/SDCOM/WeTypeTouchBarBridge)。流程先尝试官方 `tencentcom/git-sync`（这一阶段允许失败），再根据 [CNB 迁移文档](https://docs.cnb.cool/zh/guide/migration-tools.html) 执行 `git clone --mirror` + `git push --mirror`，确保所有 Git 分支、标签和提交历史都同步。**以完整镜像推送为最终结果**；它会覆盖同名远端引用，并删除 CNB 中 GitHub 已不存在的引用。因此 CNB 仓库应作为只读镜像，不应独立维护分支或标签。GitHub Release 的二进制附件不属于 Git refs，不会随 Git 镜像一起迁移。

配置之前，先在 CNB 创建目标仓库并生成对该仓库有写入权限的访问令牌，然后在本机执行：

```bash
# 在交互式提示中粘贴 CNB 访问令牌；不会显示在 shell 历史或终端输出中
gh secret set CNB_GIT_TOKEN --repo SDCOM-0415/WeTypeTouchBarBridge
```

该令牌只保存在 GitHub Actions Secret 中，工作流通过 HTTPS 用户名 `cnb` 认证。**无需提供令牌给任何聊天机器人。** 未配置时同步工作流会跳过；配置后到 Actions 页面手动执行一次即可开始初次镜像。若官方 git-sync 第一次执行失败，继续尝试完整镜像；如果最终镜像失败，工作流仍会明确报错，不会把失败伪装成同步成功。

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

本地 `build.sh` 生成的是使用临时（ad-hoc）签名的实验性程序，与 GitHub Release v1.0 起使用的固定自签测试证书不同；两者**都未经过 Apple 公证**。若 Finder 无法打开，可在确认并信任源码后从终端运行：

```bash
./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge
```

菜单栏出现「候1」表示辅助程序已启动。使用微信输入法输入拼音时，Touch Bar 会显示候选词。

### 安装位置选择（v0.8 起支持）

执行 `./build.sh` 后，脚本会交互式询问安装目标：

```text
1. 应用程序文件夹（/Applications，默认）
2. ./build
3. 自行输入目录
```

直接按回车选择选项 1。选项 3 支持绝对路径、以 `~/` 开头的用户目录路径以及相对于项目目录的路径。脚本始终先在 `./build` 编译和临时签名，再复制 App 到所选位置并尝试运行。

建议选择 `/Applications`，避免移动已登记登录项的 App。已存在的同名应用仅在其 Bundle Identifier 与本项目一致时才会被替换；修改安装位置后应重新检查辅助功能及登录项授权。

### 登录时自动启动（v0.8 起支持）

在菜单栏点击「候1」→「登录时启动」，程序使用 macOS 13+ 提供的 `SMAppService.mainAppService` 申请将当前 App 注册为登录项。

- 系统可能要求到「系统设置 → 通用 → 登录项与扩展」批准；你可以从菜单中的「打开登录项设置…」跳转。
- 再次点击「登录时启动」可尝试取消注册。
- 此设置只在用户主动操作时请求，不会在安装过程中悄悄开启。
- 建议把 App 固定放在 `/Applications` 后再注册，之后不要随意移动或更名。

**注意：** 自启动授权与辅助功能授权彼此独立。两者都可能需要你手动在系统设置中批准。

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
