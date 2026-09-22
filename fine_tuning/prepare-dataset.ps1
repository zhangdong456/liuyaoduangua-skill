[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [string]$CasesPath = (Join-Path $Root 'personal_cases/cases.jsonl'),
  [string]$RulesPath = (Join-Path $Root 'personal_rules/rules.jsonl'),
  [string]$OutputDir = (Join-Path $PSScriptRoot 'output'),
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$policyPath = Join-Path $PSScriptRoot 'policy.json'
$policy = Get-Content -Raw -LiteralPath $policyPath | ConvertFrom-Json
. (Join-Path $Root 'personal_rules/test-rule-evidence.ps1')

function Read-Jsonl {
  param([string]$Path)
  $items = [System.Collections.Generic.List[object]]::new()
  if (-not (Test-Path -LiteralPath $Path)) { return @() }
  foreach ($line in Get-Content -LiteralPath $Path) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $items.Add(($line | ConvertFrom-Json))
  }
  return @($items)
}

function Get-Array {
  param($Value)
  if ($null -eq $Value) { return @() }
  return @($Value)
}

function Get-ChartText {
  param($Chart)
  if ($null -eq $Chart) { return '' }
  if ($Chart -is [string]) { return $Chart }
  return ($Chart | ConvertTo-Json -Compress -Depth 10)
}

$cases = @(Read-Jsonl -Path $CasesPath)
$rules = @(Read-Jsonl -Path $RulesPath)
$reviewStatuses = @('reviewed', 'promoted')
$resultStatuses = @('correct', 'partial', 'wrong')
$reviewed = @($cases | Where-Object {
  $_.status -in $reviewStatuses -and
  $_.outcome.status -in $resultStatuses -and
  $null -ne $_.review
})

$highQualityCorrect = @($reviewed | Where-Object {
  $_.outcome.status -eq 'correct' -and
  @($_.review.corrections | Where-Object { $_ }).Count -eq 0 -and
  [double]$_.prediction.confidence -ge [double]$policy.min_prediction_confidence -and
  (Get-Array $_.review.correct_parts).Count -gt 0 -and
  -not [string]::IsNullOrWhiteSpace([string]$_.question) -and
  $null -ne $_.chart -and
  -not [string]::IsNullOrWhiteSpace([string]$_.prediction.verdict) -and
  -not [string]::IsNullOrWhiteSpace([string]$_.rule_version)
})

$errorCases = @($reviewed | Where-Object { $_.outcome.status -in @('partial', 'wrong') })
$allowedTags = @(Get-Array $policy.error_tags)
$classifiedErrorCases = @($errorCases | Where-Object {
  $tags = @(Get-Array $_.review.error_tags)
  $tags.Count -gt 0 -and @($tags | Where-Object { $_ -notin $allowedTags }).Count -eq 0
})
$errorTypesClassified = $errorCases.Count -gt 0 -and $classifiedErrorCases.Count -eq $errorCases.Count

$reviewedIds = @{}
foreach ($case in $reviewed) { $reviewedIds[[string]$case.case_id] = $true }
function Test-VerifiedRule {
  param($Rule, [hashtable]$ReviewedIds, $Policy)
  if ($Rule.status -notin @('candidate', 'active')) { return $false }
  if ([double]$Rule.confidence -lt [double]$Policy.min_rule_confidence) { return $false }
  $supporting = @(Get-Array $Rule.supporting_cases)
  $counter = @(Get-Array $Rule.counter_cases)
  return (Test-RuleEvidence -Rule $Rule -Cases $cases -MinSupport ([int]$Policy.min_rule_support) -MinConfidence ([double]$Policy.min_rule_confidence))
}
$verifiedRules = @($rules | Where-Object { Test-VerifiedRule -Rule $_ -ReviewedIds $reviewedIds -Policy $policy })

$metrics = [pscustomobject]@{
  reviewed_cases = $reviewed.Count
  high_quality_correct = $highQualityCorrect.Count
  error_cases = $errorCases.Count
  error_types_classified = [bool]$errorTypesClassified
  verified_rule_candidates = $verifiedRules.Count
}
$ready = $metrics.reviewed_cases -ge [int]$policy.min_reviewed_cases -and
  $metrics.high_quality_correct -ge [int]$policy.min_high_quality_correct -and
  $metrics.error_types_classified -and
  $metrics.verified_rule_candidates -gt 0

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$datasetPath = Join-Path $OutputDir 'dataset.jsonl'
$reportPath = Join-Path $OutputDir 'report.md'
$statusPath = Join-Path $OutputDir 'status.json'

if ($ready) {
  $datasetRows = [System.Collections.Generic.List[string]]::new()
  foreach ($case in $highQualityCorrect) {
    $question = "问题：$($case.question)`n卦面：$(Get-ChartText $case.chart)`n请按当前六爻规则给出吉凶、依据和应期，并区分主线与细节。"
    $answerParts = @(
      [string]$case.prediction.verdict,
      "用神：$((Get-Array $case.prediction.yongshen) -join '、')",
      "应期：$($case.prediction.timing)",
      "依据规则：$((Get-Array $case.prediction.evidence_rules) -join '、')"
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $row = [pscustomobject]@{
      messages = @(
        [pscustomobject]@{ role = 'system'; content = '按个人六爻规则解卦：先定卦种和用神，再分吉凶层、应期层和细节层；不得把事后结果当作预测依据。' },
        [pscustomobject]@{ role = 'user'; content = $question },
        [pscustomobject]@{ role = 'assistant'; content = ($answerParts -join "`n") }
      )
    }
    $datasetRows.Add(($row | ConvertTo-Json -Compress -Depth 12))
  }
  $datasetRows | Set-Content -LiteralPath $datasetPath -Encoding UTF8
}
elseif (Test-Path -LiteralPath $datasetPath) {
  Remove-Item -LiteralPath $datasetPath -Force
}

$status = [pscustomobject]@{
  generated_at = (Get-Date).ToString('o')
  ready = [bool]$ready
  metrics = $metrics
  policy = $policy
  output_files = if ($ready) { @('dataset.jsonl', 'report.md', 'status.json') } else { @('status.json') }
}
$status | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $statusPath -Encoding UTF8

$reportLines = @(
  '# Fine-tuning 数据准备报告',
  '',
  "生成时间：$($status.generated_at)",
  "状态：$(if ($ready) { 'READY' } else { 'NOT_READY' })",
  '',
  '## 门槛结果',
  '',
  "- 已复盘案例：$($metrics.reviewed_cases) / $($policy.min_reviewed_cases)",
  "- 高质量正确案例：$($metrics.high_quality_correct) / $($policy.min_high_quality_correct)",
  "- 错误类型已分类：$($metrics.error_types_classified)",
  "- 通过多案例验证的规则候选：$($metrics.verified_rule_candidates)",
  '',
  '## 数据边界',
  '',
  '- 训练输入只使用预测时可见的卦面、问题和断语。',
  '- 实际结果和复盘不会写入训练样本，避免结果泄漏。',
  '- 只有高质量正确案例进入当前数据集。',
  '- 该脚本只准备数据，不自动提交外部 fine-tuning 请求。'
)
$reportLines | Set-Content -LiteralPath $reportPath -Encoding UTF8

if (-not $Quiet) { $status | ConvertTo-Json -Depth 10 }

