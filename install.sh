#!/usr/bin/env bash
# ============================================================
#  zhuchenbin-liuyao skills 一键安装脚本 (Linux / macOS / Git Bash)
#  用法:
#    ./install.sh                 # 自动探测并安装
#    ./install.sh <目标目录>       # 安装到指定目录
#  安装内容: SKILL.md (聚合总纲) + references/ (6 模块)
# ============================================================
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"

# 聚合 skill 的目录名
SKILL_NAME="zhuchenbin-liuyao"

detect_target() {
    # 1. 显式指定
    if [[ -n "$TARGET" ]]; then
        mkdir -p "$TARGET"
        echo "$TARGET"
        return
    fi
    # 2. 常见平台自动探测
    local candidates=()
    # Hermes (Linux/macOS)
    [[ -n "${HERMES_HOME:-}" ]] && candidates+=("$HERMES_HOME/profiles/liuyao/skills")
    # Claude Code / Anthropic 标准
    candidates+=("$HOME/.claude/skills")
    # Cursor
    candidates+=("$HOME/.cursor/skills")
    for d in "${candidates[@]}"; do
        if [[ -d "$d" ]]; then
            echo "$d"
            return
        fi
    done
    # 3. 都没有 → 提示
    echo "ERROR: 未找到可用的 skills 目录。请手动指定: ./install.sh <目标目录>" >&2
    echo "常见目录: ~/.claude/skills (Claude Code) / ~/.cursor/skills (Cursor)" >&2
    exit 1
}

TARGET_DIR="$(detect_target)"
DEST="$TARGET_DIR/$SKILL_NAME"

# 安装: SKILL.md + references/
rm -rf "$DEST"
mkdir -p "$DEST/references"
cp "$SRC_DIR/SKILL.md" "$DEST/SKILL.md"
cp "$SRC_DIR"/references/*.md "$DEST/references/"

echo "✅ 已安装聚合 skill: $DEST"
echo "   包含: SKILL.md + references/ ($(ls "$DEST/references" | wc -l) 个模块)"
echo ""
echo "   💡 可选: 如需安装 6 个独立 skill（触发更精准），请将以下目录逐个复制:"
echo "      zhuchenbin-liuyao-qigua / -duangua / -yingqi / -jixiang / -jingyan-ku / -yicuodian"
