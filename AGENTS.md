# AGENTS.md — WeType Touch Bar Bridge

本文件是参与本仓库开发的 AI 编码助手及自动化代理的项目级工作约定。适用于仓库根目录及其子目录。修改前先阅读 `README.md`、`main.m`、`build.sh`、`Info.plist` 和 `.github/workflows/build.yml`；以当前代码为事实依据，不要依据旧版本的推测覆盖已验证功能。

## 项目目标与边界

- 目标：为 macOS 微信输入法（WeType）提供接近系统原生拼音输入法体验的 Touch Bar 候选词显示与触摸选词能力。
- 这是独立的菜单栏辅助程序，不是输入法插件；**不得修改、重签名、注入或替换 WeType.app**。
- 已在 2018 款 Intel Touch Bar MacBook Pro + macOS Sequoia 上有用户实测；`arm64` 已完成 CI 编译验证，**不等于 Apple Silicon 实机功能已验证**。
- 当前版本为 v1.0。默认分支 `main` 用于后续开发；历史 `v0.1`～`v0.8` 分支和同名 Tags 是版本快照。未经明确要求，不修改历史分支、移动 Tag 或重写历史。
- 用户界面、README、诊断与使用说明以**简体中文**为主；代码中的变量/方法名遵循既有 Objective-C 约定。

## 代码结构

| 路径 | 职责 |
| --- | --- |
| `main.m` | AppKit 菜单栏应用；WeType AX 候选词读取、Touch Bar 渲染、选词、诊断和登录项开关 |
| `UpdateChecker.h` / `UpdateChecker.m` | 独立的 Release 版本检测模块，负责启动检查、六小时自动检查、设置持久化、网络请求和 NSAlert |
| `Info.plist` | Bundle Identifier、LSUIElement、应用版本等 |
| `build.sh` | 交互式编译、签名、选择安装目录、启动 |
| `.github/workflows/build.yml` | `macos-latest` 上分别编译 `x86_64` 和 `arm64` 两个 ZIP Artifact；版本分支 push 可自动发布新 Release，手动执行也可选择发布 |
| `.github/workflows/sync-cnb.yml` | 使用官方 git-sync 和完整 Git mirror 将全部分支、标签及历史同步到 CNB |
| `docs/` | 真实设备截图，勿用设计示意图替代实机验证 |
| `README.md` | 中文用户文档、下载说明与已知限制 |

## 核心工作机制（修改时须保持）

1. 使用 `NSRunningApplication` 查找 WeType 进程，使用 `AXUIElement` 遍历可访问的候选窗口，提取**有序数字标签及其候选词**。输入源目前使用 `com.tencent.inputmethod.wetype.pinyin`。
2. AX 查询运行于后台串行队列；所有 AppKit / `NSScrubber` / 菜单栏更新都应在**主线程**执行。避免在主线程做跨进程 AX 调用。
3. `NSScrubber` 按文本实测宽度布局，保留横向滚动、**右对齐**、连续深蓝灰底色、首选词高亮、圆角以及系统 Control Strip。滚动和候选数据变化时要正确处理复用视图。
4. 触摸候选词时依据实时编号映射模拟对应数字键；维持输入源验证、候选有效期及数组越界检查。绝不能在候选窗口消失、输入法切换后发送旧候选按键。
5. Touch Bar 的全局呈现依赖 **Apple 未公开 API**（包括系统 modal Touch Bar 和 DFRFoundation）。隔离相关调用、检查 selector/symbol 是否存在，不承诺跨版本永久兼容，不以臆测的私有接口替代已验证路径。
6. 登录时启动使用 macOS 13+ `SMAppService.mainAppService`，只能在用户明确点击菜单后注册/取消。系统是否批准由用户决定；不擅自创建 LaunchAgent、绕过系统登录项授权或持续重试注册。

## 性能与正确性

- 用户实测 WeType AX 读取通常为数毫秒到十几毫秒，但**端到端显示延迟尚未被精确测量**。不要把 100ms 轮询间隔或 AX 单次耗时当成端到端延迟保证。
- 保留 `[Perf]` 的 AX、主线程等待、UI 提交指标。若修改调度方式，比较变更前后的实际日志，并记录测试环境。
- 避免重复提交相同候选数组、无界遍历 AX 子树、在主线程阻塞等待、过度频繁重建 Touch Bar，以及后台线程直接操作 UI。
- 验证中英文混排、Emoji、候选窗口开关、前台应用切换、输入法切换、长词、候选数量变化、滚动、选词及辅助功能权限丢失。
- AX 可能接触用户正在输入的私密文字：不上传候选文本、不引入遥测或外部网络传输、不在一般日志中记录用户输入内容；公开日志/截图前应脱敏。

## 构建与验证

本地构建（**会弹出交互式安装目录选择并尝试启动**）：

```bash
chmod +x build.sh
./build.sh
```

非交互检查时，不要直接在 CI 中运行交互式 `build.sh`；按工作流在临时构建目录单独调用 `xcrun clang`。

CI 维持两个独立的单架构构建，不要未经请求改成 Universal 2：

- `macos-latest`；矩阵 `x86_64`、`arm64`。
- `-mmacosx-version-min=13.0`；链接 `Cocoa`、`ApplicationServices`、`Carbon`、`ServiceManagement`。
- `lipo -archs "$BIN"` 应只返回当前矩阵指定架构；验证 `codesign --verify --deep --strict`。
- 输出文件名必须分别为 `WeTypeTouchBarBridge-x86_64.zip` 和 `WeTypeTouchBarBridge-arm64.zip`。
- CI 使用固定自签测试证书 `WeTypeTouchBarBridge Developer` 签名，并校验签名身份；本地 `build.sh` 则使用 ad-hoc 签名。两者均非 Apple Developer ID，也未公证，不可宣称绕过 Gatekeeper。变更签名路径时同步修改 README。GitHub Runner 无实体 Touch Bar，CI 成功不代表 UI 实机功能通过。
- `vMAJOR.MINOR` / `vMAJOR.MINOR.PATCH` 版本分支 push 自动双架构构建，首次成功时创建同名 Tag 和 Release（标题即分支名）；后续更新该分支只构建新的 Actions Artifact，已有 Release 与 Tag 不可变。手动 `workflow_dispatch` 默认仅构建；显式启用 `publish_release` 才允许创建 Release。普通 Tag push 仍只构建。
- 版本分支的 `Info.plist` 版本必须匹配分支名（两段 Tag 对应三段版本号补 `.0`），且分支本身须包含最新版 workflow；不为获得自动发布而改写历史分支或 Tag。只有两个架构都成功，才发布两个单层 ZIP 和 `SHA256SUMS`。

修改前后至少运行或检查适用项：

```bash
bash -n build.sh
plutil -lint Info.plist
```

macOS 上可进一步编译、运行 `codesign`、`lipo` 检查；需要 Touch Bar 实机验证的变更必须明确标识「未实机验证」直至获得测试结果。无法使用 macOS SDK 的环境不应声称已通过 macOS 编译。

## 版本检测与代码镜像

- 更新检测实现必须保留在独立的 `UpdateChecker.h` / `UpdateChecker.m`，不要把 NSURLSession、版本比较或更新提示再次塞回 `main.m`。本地与 CI 构建必须同时编译 `main.m` 和 `UpdateChecker.m`。
- 每次启动异步查询公开的 GitHub Releases 最新版本，版本比较按数字段执行；默认每六小时复查一次，开关通过 `NSUserDefaults` 持久化，关闭自动检查也保留启动检查和手动检查。
- 新版本提示采用与辅助功能提示相同的 `NSAlert` 外观；不得阻塞输入法轮询、自动安装软件或上传候选词。网络失败不得中断正常使用。
- CNB 目标为 `https://cnb.cool/SDCOM/WeTypeTouchBarBridge.git`；使用官方 `docker://tencentcom/git-sync` 先行同步，容忍该步骤的首次失败；随后使用 `git clone --mirror` + `git push --mirror` 完整同步所有 Git 分支和标签。
- 完整镜像为权威结果，不可将最终同步失败当作成功；使用 GitHub Secret `CNB_GIT_TOKEN`（HTTPS 用户名 `cnb`），未配置时跳过，不在仓库或日志中写入令牌。镜像会删除 CNB 独有的 Git refs，CNB 只作 GitHub 的单向镜像；不包含 Release 附件。

## 安装与安全规则

- `build.sh` 提供三个选择：**1. `/Applications`（默认） 2. `./build` 3. 自定义路径**；保留直接回车选默认值。
- 编译应先写入 `./build`，签名后才安装到用户选择的目标；不得静默覆盖其他 Bundle Identifier 的同名应用。
- 对不可信输入路径做好引用、空值、失败处理。更新已注册登录项的 App 时说明重新授权/路径变化风险。
- **绝不**通过 `spctl --master-disable`、关闭 `sslVerify`、清空系统安全设置或要求授予不必要的权限来掩盖构建与签名问题。
- 本程序现用 Bundle Identifier `org.example.wetypetouchbarbridge`。更改该标识会影响辅助功能、登录项权限及升级行为，必须显式说明并提供迁移方案。

## 许可证与版本发布

- 当前维护的项目许可证以仓库根目录 `LICENSE` 为准，为 **GNU GPLv3（GPL-3.0）**；不得在新文档、Release 文案中继续将当前版本描述为 MIT。
- GPLv3 **允许商业使用和商业销售**，但对分发受保护软件及修改版施加许可证与对应源码义务，不得误写成「禁止商用」。
- v0.1～v0.8 曾在 MIT 下公开发布。后续许可证变更不自动取消历史上合法授予的 MIT 权利；不要宣称历史 MIT 授权已被撤销。
- 维护分支和 Tags 发生过一次明确由仓库所有者要求的 GPLv3 同步；今后遵守 Tag 不可变原则，除非所有者再次明确授权，不要重写已发布 Tag。
- 修改许可文本、版权归属、License 标识或发布附件时，应先核对来源、贡献者授权及 Release 描述；不要擅自修改许可证正文。

## 修改规范与交付

1. 先解释具体问题与受影响代码路径，优先做**最小可验证修改**，避免为 UI 微调重写可靠的 AX 或选词链路。
2. 保持方法签名与 ObjC 属性 setter 不冲突（历史版本曾因 `setDiagnostic:` 冲突出现编译警告）；开启/认真处理 `-Wall -Wextra`。
3. 修改版本号时保持 `Info.plist`、菜单栏版本标识、README 与 Release 说明一致；不要偷偷将历史 Tag 指向新代码。
4. 修改 CI 时考虑 GitHub Actions 的事件/权限和 Artifact 过期机制；经仓库所有者授权，版本分支 push 可自动创建同名新 Release，手动发布需要明确选择发布模式；发布 Job 单独授予 `contents: write`。不得覆盖已有 Release 或移动历史 Tag。
5. 提交应描述实际改动；在 PR/交付说明中区分 **静态检查、CI 编译、Intel 实机测试、Apple Silicon 实机测试** 四种不同的验证等级。
6. 不添加未授权的依赖、数据采集、远程请求或静默自启动功能。

## 给后续 AI Agent 的提示

这个项目经过多轮真实设备测试。**低延迟、右对齐、按文字宽度分配、首选项高亮以及触摸选词，是已经获得用户认可的体验基线。** 修复新问题时应优先保持这些特性，不要回退为固定数量分页、平均分配宽度或左对齐方案。若需要改变交互方式，明确解释取舍并取得用户指示。
