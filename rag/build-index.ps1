[CmdletBinding()]
param(
  [string]$Root = (Split-Path -Parent $PSScriptRoot),
  [string]$OutputPath = (Join-Path $PSScriptRoot 'index.jsonl')
)

$ErrorActionPreference = 'Stop'
$records = [System.Collections.Generic.List[object]]::new()

function Add-TextChunks {
  param([string]$Path, [string]$SourceType)
  $relative = [System.IO.Path]::GetRelativePath($Root, $Path).Replace('\', '/')
  $text = Get-Content -Raw -LiteralPath $Path
  $chunks = [regex]::Split($text, '(?m)(?=^#{1,4}\s+)')
  $n = 0
  foreach ($chunk in $chunks) {
    $clean = $chunk.Trim()
    if ($clean.Length -lt 40) { continue }
    $n++
    $records.Add([pscustomobject]@{
      source_id = "file:$relative#$n"
      source_type = $SourceType
      path = $relative
      text = $clean
    })
  }
}

Get-ChildItem -LiteralPath (Join-Path $Root 'references') -Filter '*.md' -File -Recurse | ForEach-Object {
  Add-TextChunks -Path $_.FullName -SourceType 'reference'
}

Get-ChildItem -LiteralPath (Join-Path $Root 'personal_rules') -Filter '*.md' -File -Recurse | ForEach-Object {
  Add-TextChunks -Path $_.FullName -SourceType 'personal_rule'
}

$ruleStore = Join-Path $Root 'personal_rules/rules.jsonl'
if (Test-Path -LiteralPath $ruleStore) {
  Get-Content -LiteralPath $ruleStore | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    $rule = $_ | ConvertFrom-Json
    $summaryParts = @(
      $rule.statement,
      $rule.scope,
      $rule.trigger,
      ($rule.exceptions -join ' ')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $records.Add([pscustomobject]@{
      source_id = "rule:$($rule.rule_id)"
      source_type = 'personal_rule'
      rule_id = $rule.rule_id
      status = $rule.status
      source_refs = $rule.source_refs
      supporting_cases = $rule.supporting_cases
      text = ($summaryParts -join ' | ')
    })
  }
}

$caseStore = Join-Path $Root 'personal_cases/cases.jsonl'
if (Test-Path -LiteralPath $caseStore) {
  Get-Content -LiteralPath $caseStore | ForEach-Object {
    if ([string]::IsNullOrWhiteSpace($_)) { return }
    $case = $_ | ConvertFrom-Json
    $summaryParts = @(
      $case.question,
      $case.context.topic,
      ($case.prediction.yongshen -join ' '),
      $case.prediction.verdict
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $records.Add([pscustomobject]@{
      source_id = "case:$($case.case_id)"
      source_type = 'case_summary'
      case_id = $case.case_id
      topic = $case.context.topic
      keywords = $case.keywords
      rule_ids = $case.prediction.evidence_rules
      text = ($summaryParts -join ' | ')
    })
  }
}

$parent = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force $parent | Out-Null
$records | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 8 } | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Output "INDEXED $($records.Count) records -> $OutputPath"
