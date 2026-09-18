#!/usr/bin/env bash
# ============================================================
#  zhuchenbin-liuyao skills 一键安装脚本 (Linux / macOS / Git Bash)
#  用法:
#    ./install.sh                 # 自动探测并安装
#    ./install.sh <目标目录>       # 安装到指定目录
#  安装内容: SKILL.md + references/ + personal_cases/ + personal_rules/ + rag/ + fine_tuning/
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

# 安装规则层；不要删除整个目标目录，否则会误删个人案例。
mkdir -p "$DEST/references"
cp "$SRC_DIR/SKILL.md" "$DEST/SKILL.md"
cp "$SRC_DIR"/references/*.md "$DEST/references/"

# 安装个人学习层的模板和脚本，保留用户已有的案例、索引和个人规则。
mkdir -p "$DEST/personal_cases/raw" "$DEST/personal_cases/reviews" "$DEST/personal_rules" "$DEST/rag" "$DEST/fine_tuning"
cp "$SRC_DIR"/personal_cases/README.md "$SRC_DIR"/personal_cases/schema.json "$SRC_DIR"/personal_cases/CASE_TEMPLATE.md "$SRC_DIR"/personal_cases/REVIEW_TEMPLATE.md "$SRC_DIR"/personal_cases/upsert-case.ps1 "$DEST/personal_cases/"
cp "$SRC_DIR/personal_rules/RULES.md" "$DEST/personal_rules/"
cp "$SRC_DIR"/rag/*.ps1 "$SRC_DIR/rag/README.md" "$DEST/rag/"
cp "$SRC_DIR"/fine_tuning/policy.json "$SRC_DIR/fine_tuning/README.md" "$SRC_DIR/fine_tuning/prepare-dataset.ps1" "$DEST/fine_tuning/"
touch "$DEST/personal_cases/cases.jsonl" "$DEST/personal_cases/index.jsonl" "$DEST/personal_rules/rules.jsonl" "$DEST/rag/source-map.jsonl"

echo "✅ 已安装聚合 skill: $DEST"
echo "   包含: SKILL.md + references/ ($(ls "$DEST/references" | wc -l) 个模块) + personal learning loop + automatic fine-tuning preparation"
echo ""
echo "   💡 可选: 如需安装 6 个独立 skill（触发更精准），请将以下目录逐个复制:"
echo "      zhuchenbin-liuyao-qigua / -duangua / -yingqi / -jixiang / -jingyan-ku / -yicuodian"
