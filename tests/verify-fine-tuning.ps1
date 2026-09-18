[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) "liuyao-fine-tuning-$PID"
$casesPath = Join-Path $tempRoot 'cases.jsonl'
$rulesPath = Join-Path $tempRoot 'rules.jsonl'
$outputDir = Join-Path $tempRoot 'output'

New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
try {
  $cases = @()
  for ($i = 1; $i -le 30; $i++) {
    $cases += [pscustomobject]@{
      case_id = "P-2026-$('{0:D4}' -f $i)"
      status = 'reviewed'
      question = "高质量正确案例 $i"
      asked_at = '2026-01-01T10:00:00+08:00'
      chart = [pscustomobject]@{ topic = '事业'; raw = "卦面 $i" }
      prediction = [pscustomobject]@{
        verdict = '可成'
        confidence = 0.85
        evidence_rules = @('R-001', 'P-R-001')
      }
      outcome = [pscustomobject]@{ status = 'correct'; occurred_at = '2026-02-01T10:00:00+08:00'; description = '结果符合' }
      review = [pscustomobject]@{ correct_parts = @('主线判断正确'); wrong_parts = @(); error_tags = @(); new_rule_candidate = '求对方答应之事优先看应爻动态' }
      rule_version = 'test'
    }
  }
  for ($i = 31; $i -le 100; $i++) {
    $cases += [pscustomobject]@{
      case_id = "P-2026-$('{0:D4}' -f $i)"
      status = 'reviewed'
      question = "已分类反馈案例 $i"
      asked_at = '2026-01-01T10:00:00+08:00'
      chart = [pscustomobject]@{ topic = '事业'; raw = "卦面 $i" }
      prediction = [pscustomobject]@{ verdict = '待定'; confidence = 0.6; evidence_rules = @('R-001') }
      outcome = [pscustomobject]@{ status = 'partial'; occurred_at = '2026-02-01T10:00:00+08:00'; description = '部分符合' }
      review = [pscustomobject]@{ correct_parts = @('部分细节'); wrong_parts = @('应期'); error_tags = @('timing'); new_rule_candidate = $null }
      rule_version = 'test'
    }
  }
  $cases | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 8 } | Set-Content -LiteralPath $casesPath -Encoding UTF8

  [pscustomobject]@{
    rule_id = 'P-R-001'
    statement = '求对方答应之事优先看应爻动态'
    status = 'candidate'
    supporting_cases = @('P-2026-0001', 'P-2026-0002', 'P-2026-0003')
    counter_cases = @()
    confidence = 0.85
  } | ConvertTo-Json -Compress -Depth 8 | Set-Content -LiteralPath $rulesPath -Encoding UTF8

  $status = & (Join-Path $Root 'fine_tuning/prepare-dataset.ps1') -Root $Root -CasesPath $casesPath -RulesPath $rulesPath -OutputDir $outputDir | ConvertFrom-Json
  if (-not $status.ready) { throw 'Fine-tuning preparation did not become ready at the configured thresholds.' }
  if ($status.metrics.reviewed_cases -ne 100) { throw "Expected 100 reviewed cases, got $($status.metrics.reviewed_cases)." }
  if ($status.metrics.high_quality_correct -ne 30) { throw "Expected 30 high-quality correct cases, got $($status.metrics.high_quality_correct)." }
  if (-not $status.metrics.error_types_classified) { throw 'Error classification gate did not pass.' }
  if ($status.metrics.verified_rule_candidates -ne 1) { throw "Expected one verified rule candidate, got $($status.metrics.verified_rule_candidates)." }
  $datasetPath = Join-Path $outputDir 'dataset.jsonl'
  if (-not (Test-Path -LiteralPath $datasetPath -PathType Leaf)) { throw 'Fine-tuning dataset was not generated.' }
  $datasetRows = @(Get-Content -LiteralPath $datasetPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($datasetRows.Count -ne 30) { throw "Expected 30 dataset examples, got $($datasetRows.Count)." }
  Write-Output 'PASS: automatic fine-tuning data preparation thresholds verified.'
}
finally {
  if (Test-Path -LiteralPath $tempRoot) {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force
  }
}
