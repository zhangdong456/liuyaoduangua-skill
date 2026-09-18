[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$CaseJsonPath,
  [string]$CasesPath = (Join-Path $PSScriptRoot 'cases.jsonl')
)

$ErrorActionPreference = 'Stop'
$case = Get-Content -Raw -LiteralPath $CaseJsonPath | ConvertFrom-Json
foreach ($field in @('case_id', 'source_type', 'status', 'question', 'asked_at', 'chart', 'prediction', 'outcome', 'review', 'rule_version')) {
  if ($null -eq $case.$field) { throw "Missing required case field: $field" }
}

$parent = Split-Path -Parent $CasesPath
New-Item -ItemType Directory -Force $parent | Out-Null
$records = [System.Collections.Generic.List[object]]::new()
if (Test-Path -LiteralPath $CasesPath) {
  foreach ($line in Get-Content -LiteralPath $CasesPath) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    $existing = $line | ConvertFrom-Json
    if ($existing.case_id -ne $case.case_id) { $records.Add($existing) }
  }
}
$records.Add($case)

$tempPath = "$CasesPath.$PID.tmp"
try {
  $records | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 12 } | Set-Content -LiteralPath $tempPath -Encoding UTF8
  Move-Item -LiteralPath $tempPath -Destination $CasesPath -Force
  $activePath = Join-Path $PSScriptRoot 'active-case.json'
  [pscustomobject]@{
    case_id = $case.case_id
    status = $case.status
    question = $case.question
    updated_at = (Get-Date).ToString('o')
  } | ConvertTo-Json -Compress | Set-Content -LiteralPath $activePath -Encoding UTF8

  $root = Split-Path -Parent $PSScriptRoot
  $buildIndex = Join-Path $root 'rag/build-index.ps1'
  if (Test-Path -LiteralPath $buildIndex) {
    & $buildIndex -Root $root -OutputPath (Join-Path $root 'rag/index.jsonl') | Out-Host
  }
  $prepareDataset = Join-Path $root 'fine_tuning/prepare-dataset.ps1'
  if (Test-Path -LiteralPath $prepareDataset) {
    & $prepareDataset -Root $root -CasesPath $CasesPath -RulesPath (Join-Path $root 'personal_rules/rules.jsonl') -Quiet | Out-Null
  }
  Write-Output "UPSERTED $($case.case_id) -> $CasesPath"
}
finally {
  if (Test-Path -LiteralPath $tempPath) { Remove-Item -LiteralPath $tempPath -Force }
}
