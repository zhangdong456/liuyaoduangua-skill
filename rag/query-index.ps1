[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Query,
  [int]$Top = 5,
  [string]$IndexPath = (Join-Path $PSScriptRoot 'index.jsonl')
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $IndexPath)) {
  throw "Index not found: $IndexPath. Run build-index.ps1 first."
}

$terms = [regex]::Matches($Query.ToLowerInvariant(), '[\p{L}\p{N}]+') | ForEach-Object Value | Select-Object -Unique
$hits = foreach ($line in Get-Content -LiteralPath $IndexPath) {
  if ([string]::IsNullOrWhiteSpace($line)) { continue }
  $item = $line | ConvertFrom-Json
  $haystack = (($item.text, $item.topic, $item.keywords, $item.rule_ids) -join ' ').ToLowerInvariant()
  $score = 0
  foreach ($term in $terms) {
    if ($haystack.Contains($term)) { $score++ }
  }
  if ($score -gt 0) {
    [pscustomobject]@{ score = $score; source_id = $item.source_id; source_type = $item.source_type; path = $item.path; text = $item.text }
  }
}

$hits | Sort-Object score -Descending | Select-Object -First $Top | ConvertTo-Json -Depth 8
