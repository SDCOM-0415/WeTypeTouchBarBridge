# 构建与发布维护说明

本文件面向项目维护者，普通用户请阅读 [README](../README.md)。

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

## GitHub → CNB 全分支镜像

新增工作流 [Mirror all Git refs to CNB](https://github.com/SDCOM-0415/WeTypeTouchBarBridge/actions/workflows/sync-cnb.yml)，在 GitHub 推送任意分支、标签或版本构建工作流完成后自动执行，也支持手动触发。

同步目标：[CNB / SDCOM / WeTypeTouchBarBridge](https://cnb.cool/SDCOM/WeTypeTouchBarBridge)。流程先尝试官方 `tencentcom/git-sync`（这一阶段允许失败），再根据 [CNB 迁移文档](https://docs.cnb.cool/zh/guide/migration-tools.html) 执行 `git clone --mirror` + `git push --mirror`，确保所有 Git 分支、标签和提交历史都同步。**以完整镜像推送为最终结果**；它会覆盖同名远端引用，并删除 CNB 中 GitHub 已不存在的引用。因此 CNB 仓库应作为只读镜像，不应独立维护分支或标签。GitHub Release 的二进制附件不属于 Git refs，不会随 Git 镜像一起迁移。

配置之前，先在 CNB 创建目标仓库并生成对该仓库有写入权限的访问令牌，然后在本机执行：

```bash
# 在交互式提示中粘贴 CNB 访问令牌；不会显示在 shell 历史或终端输出中
gh secret set CNB_GIT_TOKEN --repo SDCOM-0415/WeTypeTouchBarBridge
```

该令牌只保存在 GitHub Actions Secret 中，工作流通过 HTTPS 用户名 `cnb` 认证。**无需提供令牌给任何聊天机器人。** 未配置时同步工作流会跳过；配置后到 Actions 页面手动执行一次即可开始初次镜像。若官方 git-sync 第一次执行失败，继续尝试完整镜像；如果最终镜像失败，工作流仍会明确报错，不会把失败伪装成同步成功。

