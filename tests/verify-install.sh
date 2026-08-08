#!/usr/bin/env bash
# ============================================================
#  zhuchenbin-liuyao-skills 安装脚本验证 (canonical test)
#  用法: bash tests/verify-install.sh
#  验证: install.sh + install.ps1 → 安装完整性 / 内容一致性 / 幂等 / 语法
# ============================================================
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/hermes-verify-liuyao-XXXXXX")"
PASS=0; FAIL=0

ok()   { echo "  ✅ $1"; PASS=$((PASS+1)); }
bad()  { echo "  ❌ $1"; FAIL=$((FAIL+1)); }

# 断言: 文件存在且与源一致
assert_installed() { # $1=安装根 $2=模块名
  local dest="$1/zhuchenbin-liuyao"
  [[ -f "$dest/SKILL.md" ]] && cmp -s "$dest/SKILL.md" "$ROOT/SKILL.md" && ok "SKILL.md 已装且一致" || bad "SKILL.md 缺失/不一致"
  local n=0
  for f in "$ROOT"/references/*.md; do
    local base
    base="$(basename "$f")"
    if [[ -f "$dest/references/$base" ]] && cmp -s "$f" "$dest/references/$base"; then n=$((n+1)); fi
  done
  [[ $n -eq 6 ]] && ok "references/ 6 模块齐全且一致" || bad "references/ 仅 $n/6 模块正确"
}

echo "=== 1. install.sh (bash) ==="
bash "$ROOT/install.sh" "$WORK/sh" > /dev/null 2>&1
assert_installed "$WORK/sh"

echo "=== 2. install.ps1 (PowerShell) ==="
if command -v powershell.exe > /dev/null 2>&1; then
  powershell.exe -NoProfile -ExecutionPolicy Bypass \
    -File "$(cygpath -w "$ROOT/install.ps1")" \
    -Target "$(cygpath -w "$WORK/ps")" > /dev/null 2>&1
  assert_installed "$WORK/ps"
else
  echo "  ⚠️ powershell.exe 不可用，跳过"; FAIL=$((FAIL+1))
fi

echo "=== 3. 幂等性 ==="
bash "$ROOT/install.sh" "$WORK/sh" > /dev/null 2>&1
[[ -f "$WORK/sh/zhuchenbin-liuyao/SKILL.md" ]] && ok "重复安装成功" || bad "重复安装失败"

echo "=== 4. 语法检查 ==="
bash -n "$ROOT/install.sh" && ok "install.sh bash 语法" || bad "install.sh 语法错误"
if command -v powershell.exe > /dev/null 2>&1; then
  ps_src="$(cygpath -w "$ROOT/install.ps1")"
  if powershell.exe -NoProfile -Command "\$t=\$null; [System.Management.Automation.PSParser]::Tokenize((Get-Content -Raw '$ps_src'),[ref]\$t) > \$null; if (\$?) {'ok'} else {'fail'}" 2>/dev/null | grep -q ok; then
    ok "install.ps1 PS 语法"
  else
    bad "install.ps1 语法错误"
  fi
fi

rm -rf "$WORK"
echo ""
echo "========== PASS=$PASS FAIL=$FAIL =========="
[[ $FAIL -eq 0 ]]
