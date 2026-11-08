# 更新日志

本文件依据各版本分支的实际源码、`Info.plist`、历史 README、构建脚本与 GitHub Actions 配置整理，按版本从新到旧排列。主要记录用户可感知的变化；发布基础设施单独列出，不把每次 CI 调整当作新功能。

> **版本说明：** 历史 `v0.x` 分支中有部分为独立快照，而非严格线性继承的提交链。以下对比的是相邻版本的**实际文件内容**，不以 GitHub Compare 的 ahead/behind 数量直接判定功能增减。当前 `main` 的后续维护修改不等于已写入旧版本 Tag。

## [v1.1.2](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v1.1.2) — CNB Release API 更新源

- 将更新检测从 CNB 公共 Release 徽章（SVG）切换为 CNB OpenAPI 的最新 Release JSON，读取 `tag_name` 后进行数字版本比较。
- 使用仅针对本项目公开仓库的只读部署令牌访问 CNB API，下载入口也指向对应的 CNB Release 页面。
- 保留启动检查、每六小时自动检查、手动检查、开关持久化和原生 `NSAlert` 提示；不自动下载或安装更新。
- 版本号升级至 `1.1.2`，构建号升级至 `13`。

**发布维护：** GitHub 构建与签名成功后创建 `v1.1.2` Release。该版本首次镜像时曾因 CNB Release 不存在而导致附件上传失败；后来使用同一批 GitHub 产物补建 CNB Release 并成功上传两个 ZIP 和校验文件。后续在 `main` 中增加了显式创建 CNB Release 的保护，不回写历史 Tag。

## [v1.1.1](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v1.1.1) — 更新检查源调整

- 将自动更新来源由 GitHub Releases API 调整为无需客户端授权的 CNB Release 徽章，解析 SVG 中的版本号。
- 保留现有更新提示、版本比较和周期检查行为。
- 进一步调整本地构建脚本、发布配置及对应文档。

**说明：** 该版本使用的是 CNB 徽章方案；直接调用带只读令牌的 CNB JSON API 是 `v1.1.2` 才加入的行为。

## [v1.1](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v1.1) — 自动检查更新与自动发布

### 新增
- 新增自动检查更新：应用启动时检查一次，默认每六小时检查一次；菜单可开关自动检查或手动查询。
- 发现新版本时通过 macOS 原生 `NSAlert` 提示并跳转下载，不执行静默更新。
- 将更新检测独立封装为 `UpdateChecker.h` / `UpdateChecker.m`，避免将网络请求和版本处理逻辑塞进 `main.m`。

### 构建与分发
- GitHub Actions 同时编译 Intel `x86_64` 和 Apple Silicon `arm64` 版本，并将更新模块纳入本地及 CI 编译。
- 支持手动选择是否发布 Release；版本分支推送可自动构建并创建同名 Tag / Release。
- 改善发布 ZIP 的附件结构，避免把 Actions Artifact 的外层压缩包作为正式安装包。
- 新增 GitHub → CNB 全 Git 引用镜像工作流与 CNB Release 附件同步配置。

## [v1.0](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v1.0) — 首个正式版

- 为 `NSScrubber` 候选项新增触摸按压/高亮交互反馈，在结束或取消交互时清除按压状态。
- 保留先前版本的动态宽度、首选词外观、右对齐、滚动和数字选词行为。
- 引入双架构 GitHub Actions 构建、签名及验证流程，开始面向 Release 分发预编译安装包。
- 发布产物由早期 ad-hoc 签名改为固定自签测试证书签名，以改善跨版本代码签名身份的连续性；仍非 Apple Developer ID 签名或公证。

## [v0.8](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.8) — 登录时启动与安装体验

- 新增菜单栏「登录时启动」开关，利用 macOS 13+ 的 `SMAppService.mainAppService` 注册和取消登录项。
- 增加「打开登录项设置…」，处理需要系统批准的登录项状态。
- `build.sh` 增加安装目标选择：`/Applications`、项目的 `build` 目录或自定义位置。
- 完善实机截图、安装说明与日常使用文档。

## [v0.7](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.7) — 候选栏整体右对齐

- 新增 `TrailingCandidateHost` 容器，根据候选项总宽度调整 `NSScrubber` 的位置。
- 候选内容较少时整体靠右、贴近系统控制区；内容较多时仍利用 `NSScrubber` 原生横向滚动。
- 延续 v0.6 的候选词背景与首选词高亮。

## [v0.6](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.6) — 原生风格外观

- 新增自定义 `CandidateItemView`，调整候选区的深蓝灰底色及首选词高亮外观。
- `NSScrubber` 高度从 30pt 调整至 36pt。
- 复用候选项视图时重新应用外观，避免滚动或重载后的样式错乱。
- 保留动态宽度、后台轮询与性能日志。

## [v0.5](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.5) — 自适应宽度与性能诊断

- 候选栏从 `NSCandidateListTouchBarItem` 切换为 `NSScrubber` + `NSScrubberFlowLayout`，获得更明确的布局和选词控制。
- 根据实际字体宽度计算候选项尺寸（最小约 44pt、最大约 270pt），支持横向滚动。
- 增加 `[Perf]` 性能日志，记录 AX 查询、主队列等待和 UI 更新阶段的耗时；这些数据不等同于 Touch Bar 实际上屏延迟。
- 继续采用 100ms 的后台 AX 轮询，候选数据变化时更新控件布局。

## [v0.4](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.4) — 原生候选尺寸与滚动

- 取消 v0.3 的固定四候选一页方案及前后翻页按钮。
- 将 AX 读取到的完整可见候选列表交给系统 `NSCandidateListTouchBarItem`，由 AppKit 负责候选宽度、裁剪和滚动。
- 仍使用后台 100ms 轮询及系统模态 Touch Bar 呈现方式。

## [v0.3](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.3) — 降低轮询延迟

- 将 AX 候选查询从主线程的 250ms `NSTimer` 移到后台串行 GCD 定时器，轮询周期缩短至 **100ms（10Hz）**。
- 增加固定每页四项的候选分页与前后翻页按钮。
- 候选发生变化时重置页码，并增加触摸选词的 1.5 秒时效防护。
- 仍使用原生 `NSCandidateListTouchBarItem`。

## [v0.2.1](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.2.1) — 编译警告修复

- 将诊断文字更新方法从 `setDiagnostic:` 更名为 `updateDiagnosticMessage:`，避免与 `diagnostic` 属性自动生成的 setter 冲突。
- 不改变 Touch Bar 显示方案或 250ms 轮询频率。

## [v0.2](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.2) — 诊断原型

- 增加「强制测试 Touch Bar」菜单项和独立测试按钮，用于排查系统模态 Touch Bar 是否能够显示。
- 增加菜单中的候选状态提示，区分辅助功能授权、WeType 进程和候选读取情况。
- 为原生候选栏与触摸显示路径增加调试输出，便于定位无法显示的问题。
- 保持主线程 250ms 轮询和 `NSCandidateListTouchBarItem` 方案。

## [v0.1](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/tree/v0.1) — 初始实验原型

- 实现从微信输入法候选窗口的 macOS 辅助功能树读取候选文字。
- 尝试使用系统 `NSCandidateListTouchBarItem` 和系统模态 Touch Bar 接口展示候选词。
- 触摸候选项时发送对应数字键（1–9）给输入法进行选词。
- 实现菜单栏辅助应用、辅助功能授权判断与暂停/退出操作。
- 使用主线程 `NSTimer` 每 250ms（4Hz）采样；此阶段的触摸显示兼容性仍处于实验状态。

---

## 历史版本元数据备注

- `v0.2.1` 分支的 `Info.plist` 仍标为 `0.2.0`；`v0.4` 分支仍标为 `0.3.0`。上述条目按**分支名称和代码功能**分类，而不是依据这两个旧 `Info.plist` 的版本字符串。
- 某些早期 README 曾描述 MIT 许可，但各版本分支的 `LICENSE` 文件实际均为 **GNU GPLv3**；有关许可证应以对应版本的 `LICENSE` 正文为准。
- `main` 在 `v1.1.2` 分支之后仍有维护性更新，包括 CNB Release 创建/上传流程修复、`.cnb.yml` 配置更正和 README 精简。这些后续变更**没有自动进入已发布的 `v1.1.2` Tag**，因此不列作该版本已包含的功能。
