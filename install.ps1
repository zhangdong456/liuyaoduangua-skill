# ============================================================
#  zhuchenbin-liuyao skills 一键安装脚本 (Windows PowerShell)
#  用法:
#    .\install.ps1                 # 自动探测并安装
#    .\install.ps1 -Target <目录>   # 安装到指定目录
#  安装内容: SKILL.md (聚合总纲) + references/ (6 模块)
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
    # Hermes (Windows)
    $hermesHome = $env:HERMES_HOME
    if ($hermesHome) { $candidates += "$hermesHome\profiles\liuyao\skills" }
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
$Dest = Join-Path $TargetDir $SkillName

# 安装: SKILL.md + references/
if (Test-Path $Dest) { Remove-Item -Recurse -Force $Dest }
New-Item -ItemType Directory -Force -Path "$Dest\references" | Out-Null
Copy-Item "$SrcDir\SKILL.md" "$Dest\SKILL.md"
Copy-Item "$SrcDir\references\*.md" "$Dest\references\"

$moduleCount = (Get-ChildItem "$Dest\references\*.md").Count
Write-Host "✅ 已安装聚合 skill: $Dest" -ForegroundColor Green
Write-Host "   包含: SKILL.md + references/ ($moduleCount 个模块)" -ForegroundColor Green
Write-Host ""
Write-Host "   💡 可选: 如需安装 6 个独立 skill（触发更精准），请将以下目录逐个复制:" -ForegroundColor Cyan
Write-Host "      zhuchenbin-liuyao-qigua / -duangua / -yingqi / -jixiang / -jingyan-ku / -yicuodian" -ForegroundColor Cyan
