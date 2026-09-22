# ============================================================
#  zhuchenbin-liuyao skills 一键安装脚本 (Windows PowerShell)
#  用法:
#    .\install.ps1                 # 自动探测并安装
#    .\install.ps1 -Target <目录>   # 安装到指定目录
#  安装内容: SKILL.md + references/ + personal_cases/ + personal_rules/ + rag/ + fine_tuning/
#  注意: 本机 Hermes(liuyao) 走 skills.external_dirs 直读仓库, 勿安装进 Hermes profile(同名本地优先会遮蔽直读版)
# ============================================================
param(
    [string]$Target = ""
)

$ErrorActionPreference = "Stop"
$SkillName = "zhuchenbin-liuyao"
$SrcDir = Split-Path -Parent $MyInvocation.MyCommand.Path

function Detect-Target {
    if ($Target -ne "") {
        New-Item -ItemType Directory -Force -Path $Target | Out-Null
        return $Target
    }
    $candidates = @()
    # Hermes 不做自动探测: liuyao profile 用 skills.external_dirs 直读仓库,
    # 装进 profile 会因同名本地优先遮蔽直读版 (见 AGENTS.md「本机 Hermes」)。
    $candidates += "$env:USERPROFILE\.claude\skills"          # Claude Code
    $candidates += "$env:USERPROFILE\.cursor\skills"          # Cursor
    foreach ($d in $candidates) {
        if (Test-Path $d) { return $d }
    }
    Write-Host "ERROR: 未找到可用的 skills 目录。请手动指定: .\install.ps1 -Target <目录>" -ForegroundColor Red
    Write-Host "常见目录: ~\.claude\skills (Claude Code) / ~\.cursor\skills (Cursor)" -ForegroundColor Yellow
    exit 1
}

$TargetDir = Detect-Target

# 显式指定 Hermes profile 路径时仍允许, 但警告会遮蔽 external_dirs 直读版
if ($Target -match "hermes[\\/]profiles") {
    Write-Warning "目标是 Hermes profile skills 目录: 本地副本会遮蔽 skills.external_dirs 直读的仓库版, 建议改用 external_dirs (见 AGENTS.md)。"
}
$Dest = Join-Path $TargetDir $SkillName

# 安装规则层；不要删除整个目标目录，否则会误删个人案例。
New-Item -ItemType Directory -Force -Path "$Dest\references" | Out-Null
Copy-Item "$SrcDir\SKILL.md" "$Dest\SKILL.md"
Copy-Item "$SrcDir\references\*.md" "$Dest\references\"

# 安装个人学习层的模板和脚本，保留用户已有的案例、索引和个人规则。
New-Item -ItemType Directory -Force -Path "$Dest\personal_cases\raw", "$Dest\personal_cases\reviews", "$Dest\personal_rules", "$Dest\rag", "$Dest\fine_tuning" | Out-Null
Copy-Item "$SrcDir\personal_cases\README.md", "$SrcDir\personal_cases\schema.json", "$SrcDir\personal_cases\CASE_TEMPLATE.md", "$SrcDir\personal_cases\REVIEW_TEMPLATE.md", "$SrcDir\personal_cases\upsert-case.ps1" "$Dest\personal_cases\"
Copy-Item "$SrcDir\personal_rules\RULES.md" "$Dest\personal_rules\"
Copy-Item "$SrcDir\rag\*.ps1", "$SrcDir\rag\README.md" "$Dest\rag\"
Copy-Item "$SrcDir\fine_tuning\policy.json", "$SrcDir\fine_tuning\README.md", "$SrcDir\fine_tuning\prepare-dataset.ps1" "$Dest\fine_tuning\"
foreach ($file in @("$Dest\personal_cases\cases.jsonl", "$Dest\personal_cases\index.jsonl", "$Dest\personal_rules\rules.jsonl", "$Dest\rag\source-map.jsonl")) {
    if (-not (Test-Path $file)) { New-Item -ItemType File -Path $file | Out-Null }
}

$moduleCount = (Get-ChildItem "$Dest\references\*.md").Count
Write-Host "✅ 已安装聚合 skill: $Dest" -ForegroundColor Green
Write-Host "   包含: SKILL.md + references/ ($moduleCount 个模块) + personal learning loop + automatic fine-tuning preparation" -ForegroundColor Green
Write-Host ""
Write-Host "   💡 可选: 6 个独立 skill (触发更精准) = 复制 references/<mod>.md 为目标目录的 SKILL.md:" -ForegroundColor Cyan
Write-Host "      zhuchenbin-liuyao-qigua / -duangua / -yingqi / -jixiang / -jingyan-ku / -yicuodian" -ForegroundColor Cyan
Write-Host "   ⚠️ 本机 Hermes(liuyao) 走 skills.external_dirs 直读仓库+父目录薄壳, 勿安装进 Hermes profile." -ForegroundColor Yellow
