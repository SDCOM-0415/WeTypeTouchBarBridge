#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
PROJECT_DIR="$PWD"
NAME="WeTypeTouchBarBridge.app"
BUILD_DIR="$PROJECT_DIR/build"
STAGED_APP="$BUILD_DIR/$NAME"

if ! xcrun --find clang >/dev/null 2>&1; then
  echo '需要 Xcode Command Line Tools：xcode-select --install' >&2
  exit 1
fi

APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" Info.plist)
echo "=== WeType Touch Bar Bridge v${APP_VERSION} 构建 ==="
echo "请选择 .app 安装位置："
echo "  1. 应用程序文件夹（/Applications，默认）"
echo "  2. ./build"
echo "  3. 自行输入目录"
printf "请选择 [1/2/3，直接回车选择 1]: "
IFS= read -r choice || choice=""
choice="${choice:-1}"
case "$choice" in
  1) DEST_DIR="/Applications" ;;
  2) DEST_DIR="$BUILD_DIR" ;;
  3)
    printf "请输入目标文件夹完整路径（可用 ~/ 开头）: "
    IFS= read -r DEST_DIR || DEST_DIR=""
    if [ -z "$DEST_DIR" ]; then echo "路径不能为空" >&2; exit 1; fi
    case "$DEST_DIR" in
      "~") DEST_DIR="$HOME" ;;
      "~/"*) DEST_DIR="$HOME/${DEST_DIR#\~/}" ;;
    esac
    case "$DEST_DIR" in
      /*) ;;
      *) DEST_DIR="$PROJECT_DIR/$DEST_DIR" ;;
    esac
    ;;
  *) echo "无效选项：$choice" >&2; exit 1 ;;
esac

# Always compile in ./build, then install the signed .app into the chosen folder.
mkdir -p "$BUILD_DIR"
pkill -x WeTypeTouchBarBridge 2>/dev/null || true
rm -rf "$STAGED_APP"
mkdir -p "$STAGED_APP/Contents/MacOS"

xcrun clang -fobjc-arc -fmodules -mmacosx-version-min=13.0 -O2 -Wall -Wextra \
  -framework Cocoa -framework ApplicationServices -framework Carbon \
  -framework ServiceManagement \
  main.m UpdateChecker.m -o "$STAGED_APP/Contents/MacOS/WeTypeTouchBarBridge"
cp Info.plist "$STAGED_APP/Contents/Info.plist"
codesign --force --sign - "$STAGED_APP"
echo "构建完成：$STAGED_APP"

TARGET_APP="$DEST_DIR/$NAME"
if [ "$TARGET_APP" != "$STAGED_APP" ]; then
  if [ "$DEST_DIR" = "/Applications" ] && [ ! -w "$DEST_DIR" ]; then
    echo "没有 /Applications 写入权限。请手动选择用户目录，或在系统提示下授权复制。" >&2
    exit 1
  fi
  mkdir -p "$DEST_DIR"
  # Avoid silently replacing an unrelated app bundle with the same name.
  if [ -e "$TARGET_APP" ]; then
    id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TARGET_APP/Contents/Info.plist" 2>/dev/null || true)
    if [ "$id" != "org.example.wetypetouchbarbridge" ]; then
      echo "目标已有同名但不同应用标识的程序，已停止以避免覆盖：$TARGET_APP" >&2
      exit 1
    fi
    rm -rf "$TARGET_APP"
  fi
  ditto "$STAGED_APP" "$TARGET_APP"
fi

echo "安装位置：$TARGET_APP"
echo "如需开机自启动：打开菜单栏「候1」→「登录时启动」，并根据 macOS 提示批准。"
echo "如首次使用，请在「系统设置 → 隐私与安全性 → 辅助功能」授权。"
if ! open "$TARGET_APP"; then
  echo "Finder 启动失败，可直接运行："
  echo "  \"$TARGET_APP/Contents/MacOS/WeTypeTouchBarBridge\""
fi
