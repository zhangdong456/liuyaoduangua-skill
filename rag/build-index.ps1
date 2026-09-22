[CmdletBinding()]
param(
  [string]$Root,
  [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$scriptRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptRoot)) {
  $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}
if ([string]::IsNullOrWhiteSpace($Root)) {
  $Root = Split-Path -Parent $scriptRoot
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
  $OutputPath = Join-Path $scriptRoot 'index.jsonl'
}
$records = [System.Collections.Generic.List[object]]::new()

function Add-TextChunks {
  param([string]$Path, [string]$SourceType)
  # Windows PowerShell 5.1/.NET Framework does not provide
  # System.IO.Path.GetRelativePath (it was added in newer .NET versions).
  # All indexed files are descendants of $Root, so a normalized prefix
  # calculation is sufficient and keeps this script compatible with both
  # Windows PowerShell 5.1 and newer PowerShell/.NET runtimes.
  $rootFull = [System.IO.Path]::GetFullPath($Root).TrimEnd('\', '/')
  $pathFull = [System.IO.Path]::GetFullPath($Path)
  if ($pathFull.Equals($rootFull, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = ''
  } elseif ($pathFull.StartsWith($rootFull + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
            $pathFull.StartsWith($rootFull + [System.IO.Path]::AltDirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    $relative = $pathFull.Substring($rootFull.Length).TrimStart('\', '/')
  } else {
    throw "Path '$Path' is outside index root '$Root'."
  }
  $relative = $relative.Replace('\', '/')
  $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $Path
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
  Add-TextChunks -Path $_.FullName -SourceType 'learning_document'
}

$ruleStore = Join-Path $Root 'personal_rules/rules.jsonl'
if (Test-Path -LiteralPath $ruleStore) {
  Get-Content -Encoding UTF8 -LiteralPath $ruleStore | ForEach-Object {
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
  Get-Content -Encoding UTF8 -LiteralPath $caseStore | ForEach-Object {
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
      validation = [pscustomobject]@{
        result = $case.outcome.status
        error_tags = $case.review.error_tags
        evidence_use = if ($case.outcome.status -eq 'correct') { 'verified_example' } elseif ($case.outcome.status -in @('wrong', 'partial')) { 'counterexample_check_errors' } else { 'not_verified' }
      }
      text = ($summaryParts -join ' | ')
    })
  }
}

$parent = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force $parent | Out-Null
$records | ForEach-Object { $_ | ConvertTo-Json -Compress -Depth 8 } | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Output "INDEXED $($records.Count) records -> $OutputPath"
