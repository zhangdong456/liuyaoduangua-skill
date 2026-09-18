[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$required = @(
  'SKILL.md',
  'personal_cases/schema.json',
  'personal_cases/CASE_TEMPLATE.md',
  'personal_rules/RULES.md',
  'rag/build-index.ps1',
  'rag/query-index.ps1',
  'fine_tuning/policy.json',
  'fine_tuning/prepare-dataset.ps1'
)

foreach ($relative in $required) {
  $path = Join-Path $Root $relative
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
    throw "Missing required file: $relative"
  }
}

$schema = Get-Content -Raw -LiteralPath (Join-Path $Root 'personal_cases/schema.json') | ConvertFrom-Json
if (-not $schema.required -or -not ($schema.required -contains 'prediction') -or -not ($schema.required -contains 'review')) {
  throw 'Case schema does not require prediction and review fields.'
}

$tempIndex = Join-Path ([System.IO.Path]::GetTempPath()) "liuyao-learning-index-$PID.jsonl"
try {
  & (Join-Path $Root 'rag/build-index.ps1') -Root $Root -OutputPath $tempIndex | Out-Null
  $rows = @(Get-Content -LiteralPath $tempIndex | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  if ($rows.Count -lt 1) { throw 'RAG index is empty.' }

  $resultText = & (Join-Path $Root 'rag/query-index.ps1') -Query '用神 应期 对轨' -IndexPath $tempIndex -Top 2
  $result = $resultText | ConvertFrom-Json
  if (-not $result) { throw 'RAG query returned no result.' }
  Write-Output "PASS: schema, index build, and low-token query verified ($($rows.Count) index records)."
}
finally {
  if (Test-Path -LiteralPath $tempIndex) {
    Remove-Item -LiteralPath $tempIndex -Force
  }
}
