# WeType Touch Bar Bridge v0.5 — 宽度自适应与诊断

相比 v0.4：
- 改成 `NSScrubber` + `NSScrubberFlowLayout`，以字体实际测量宽度分配候选项，最小 44pt，最长 270pt，可横向滚动。
- 继续用后台 AX 100ms 轮询；仅在候选变化时 reload 布局。
- 记录阶段耗时：`AX` 是后台获取/解析候选用时、`queue` 是等待主线程、`UI` 是同步提交控件更新用时（**不包含 Touch Bar 实际呈现延迟**）。
- 菜单栏显示“候5”以确认版本。日志不打印候选词内容。

## 构建

解压后进入本目录运行 `chmod +x build.sh && ./build.sh`。如果 macOS 拒绝 Finder 启动，可直接执行 `./build/WeTypeTouchBarBridge.app/Contents/MacOS/WeTypeTouchBarBridge`。在系统设置中授予此 App 辅助功能访问权。

## 采集性能日志

打开另一个终端：

```bash
log stream --style compact --level info --predicate 'process == "WeTypeTouchBarBridge" AND eventMessage CONTAINS "[Perf]"'
```

在其他 App 使用微信输入法输入。把 `CHANGE` 及 `10s` 统计行反馈回来，注意不要上传敏感输入内容。系统日志有时不包含标准错误日志；也可以直接从终端运行可执行文件以看到 NSLog。

## 限制

这不是微信输入法的官方扩展，依赖 WeType Accessibility 树和未公开的系统模态 Touch Bar 显示接口。触摸选词以编号键模拟实现，**仅对 1–9 编号候选有效**；没有修改微信输入法二进制。AX + UI 指标不是端到端可见延迟。代码尚未在真实 macOS SDK 编译及 Mac Touch Bar 上实机验证。若编译报错请提供完整 clang 输出。
