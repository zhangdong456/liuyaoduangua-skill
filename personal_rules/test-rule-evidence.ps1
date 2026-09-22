function Test-RuleEvidence {
  param($Rule, $Cases, [int]$MinSupport = 3, [double]$MinConfidence = 0.75)
  if ($Rule.status -notin @('candidate', 'active') -or [double]$Rule.confidence -lt $MinConfidence) { return $false }
  if ([string]::IsNullOrWhiteSpace($Rule.scope) -or [string]::IsNullOrWhiteSpace($Rule.trigger)) { return $false }
  $introduced = [datetimeoffset]::MinValue
  if (-not [datetimeoffset]::TryParse([string]$Rule.introduced_at, [ref]$introduced)) { return $false }
  if (@($Rule.counter_cases | Where-Object { $_ }).Count -gt 0) { return $false }
  $eligible = @($Cases | Where-Object {
    $_.status -in @('reviewed', 'promoted') -and $_.outcome.status -in @('correct', 'partial', 'wrong')
  })
  # All reviewed cases must have an explicit applicability check: no unchecked failures hidden by selecting support IDs.
  foreach ($case in $eligible) {
    if ($Rule.rule_id -notin @($case.review.checked_rules)) { return $false }
    if ($Rule.rule_id -in @($case.review.counter_rules)) { return $false }
  }
  $ids = @($Rule.supporting_cases | Where-Object { $_ } | Select-Object -Unique)
  $support = @($eligible | Where-Object {
    $_.case_id -in $ids -and $Rule.rule_id -in @($_.review.supported_rules) -and
    -not [string]::IsNullOrWhiteSpace($_.event_id) -and @($_.review.corrections | Where-Object { $_ }).Count -eq 0
  } | Sort-Object case_id -Unique)
  $events = @($support.event_id | Select-Object -Unique)
  if ($events.Count -lt $MinSupport) { return $false }
  # A later prediction must name the candidate BEFORE feedback, not merely explain an old result.
  foreach ($case in $support) {
    $asked = [datetimeoffset]::MinValue
    if ([datetimeoffset]::TryParse([string]$case.asked_at, [ref]$asked) -and $asked -gt $introduced -and
      $Rule.rule_id -in @($case.prediction.shadow_rules) -and
      @($case.prediction.shadow_predictions | Where-Object { $_.rule_id -eq $Rule.rule_id -and -not [string]::IsNullOrWhiteSpace($_.verdict) }).Count -gt 0 -and
      $case.event_id -notin @($support | Where-Object {
        $prior = [datetimeoffset]::MinValue
        -not [datetimeoffset]::TryParse([string]$_.asked_at, [ref]$prior) -or $prior -le $introduced
      } | ForEach-Object event_id)) { return $true }
  }
  return $false
}

# Dot-source for reuse; direct execution returns eligibility without changing rule states.
if ($MyInvocation.InvocationName -ne '.') {
  $root = Split-Path -Parent $PSScriptRoot
  $cases = @(Get-Content -LiteralPath (Join-Path $root 'personal_cases/cases.jsonl') -ErrorAction SilentlyContinue | Where-Object { $_.Trim() } | ForEach-Object { $_ | ConvertFrom-Json })
  Get-Content -LiteralPath (Join-Path $PSScriptRoot 'rules.jsonl') | Where-Object { $_.Trim() } | ForEach-Object {
    $rule = $_ | ConvertFrom-Json
    [pscustomobject]@{ rule_id = $rule.rule_id; eligible = (Test-RuleEvidence -Rule $rule -Cases $cases) }
  } | ConvertTo-Json
}
