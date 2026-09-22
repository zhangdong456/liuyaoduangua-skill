param([string]$Root = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('liuyao-guards-' + [guid]::NewGuid())
New-Item -ItemType Directory -Path $tempRoot | Out-Null
try {
  $index = Join-Path $tempRoot 'index.jsonl'
  @('candidate', 'active', 'retired') | ForEach-Object {
    @{ source_id = $_; source_type = 'personal_rule'; status = $_; text = '应爻' } | ConvertTo-Json -Compress
  } | Set-Content -LiteralPath $index -Encoding UTF8
  $hits = @(& (Join-Path $Root 'rag/query-index.ps1') -Query '应爻' -IndexPath $index | ConvertFrom-Json)
  if ($hits.Count -ne 1 -or $hits[0].status -ne 'active') { throw 'Rule state isolation failed' }
  $allHits = @(& (Join-Path $Root 'rag/query-index.ps1') -Query '应爻' -IndexPath $index -Mode review | ConvertFrom-Json)
  if ($allHits.Count -ne 3) { throw 'Review mode lost rule states' }

  $casePath = Join-Path $tempRoot 'case.json'
  $store = Join-Path $tempRoot 'cases.jsonl'
  $case = [pscustomobject]@{ case_id='P-2026-0001'; source_type='personal'; status='pending'; question='能成吗'; asked_at='2026-01-03'; event_id='e1'; chart=@{raw='卦面'}; prediction=@{verdict='可成'}; outcome=@{status='pending'}; review=@{}; rule_version='v1' }
  $case | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $casePath
  # Isolate the store test from production index/dataset side effects.
  $isolated = Join-Path $tempRoot 'personal_cases'
  New-Item -ItemType Directory -Path $isolated | Out-Null
  Copy-Item -LiteralPath (Join-Path $Root 'personal_cases/upsert-case.ps1') -Destination $isolated
  & (Join-Path $isolated 'upsert-case.ps1') -CaseJsonPath $casePath -CasesPath $store | Out-Null
  $case.status='reviewed'; $case.outcome.status='wrong'
  $case | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $casePath
  & (Join-Path $isolated 'upsert-case.ps1') -CaseJsonPath $casePath -CasesPath $store | Out-Null
  $case.prediction.verdict='不成'
  $case | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $casePath
  $blocked=$false
  try { & (Join-Path $isolated 'upsert-case.ps1') -CaseJsonPath $casePath -CasesPath $store | Out-Null } catch { $blocked = $_.Exception.Message -like 'Frozen prediction*' }
  if (-not $blocked -or (Get-Content -Raw -LiteralPath $store | ConvertFrom-Json).prediction.verdict -ne '可成') { throw 'Prediction freezing failed' }
  foreach ($dir in @('references','personal_rules')) { New-Item -ItemType Directory -Path (Join-Path $tempRoot $dir) | Out-Null }
  Copy-Item -LiteralPath $store -Destination (Join-Path $isolated 'cases.jsonl')
  $builtIndex = Join-Path $tempRoot 'built-index.jsonl'
  & (Join-Path $Root 'rag/build-index.ps1') -Root $tempRoot -OutputPath $builtIndex | Out-Null
  $caseHit = & (Join-Path $Root 'rag/query-index.ps1') -Query '能成吗' -IndexPath $builtIndex | ConvertFrom-Json
  if ($caseHit.validation.result -ne 'wrong' -or $caseHit.validation.evidence_use -ne 'counterexample_check_errors') { throw 'Wrong-case validation label lost' }

  . (Join-Path $Root 'personal_rules/test-rule-evidence.ps1')
  $rule = [pscustomobject]@{rule_id='r1';status='candidate';confidence=0.8;scope='事业';trigger='求对方';introduced_at='2026-01-02';supporting_cases=@('c1','c2','c3');counter_cases=@()}
  $cases = @(1..3 | ForEach-Object { [pscustomobject]@{case_id="c$_";event_id="e$_";status='reviewed';asked_at='2026-01-03';outcome=@{status='correct'};prediction=@{shadow_rules=@('r1')};review=@{checked_rules=@('r1');supported_rules=@('r1');counter_rules=@()}} })
  foreach ($item in $cases) { $item.prediction.shadow_predictions=@(@{rule_id='r1';verdict='可成'}) }
  if (-not (Test-RuleEvidence $rule $cases)) { throw 'Valid independent evidence rejected' }
  $rule.supporting_cases=@('c1','c1','c1')
  if (Test-RuleEvidence $rule $cases) { throw 'Duplicate support accepted' }
  $rule.supporting_cases=@('c1','c2','c3')
  $cases[2].event_id='e1'
  if (Test-RuleEvidence $rule $cases) { throw 'Repeated event accepted' }
  $cases[2].event_id='e3'
  foreach ($item in $cases) { $item.prediction.shadow_rules=@() }
  if (Test-RuleEvidence $rule $cases) { throw 'Retrospective-only rule accepted' }
  foreach ($item in $cases) { $item.prediction.shadow_rules=@('r1') }
  $cases[2].review.counter_rules=@('r1')
  if (Test-RuleEvidence $rule $cases) { throw 'Counterexample accepted' }
  $cases[2].review.counter_rules=@(); $cases[2].review.checked_rules=@()
  if (Test-RuleEvidence $rule $cases) { throw 'Unchecked reviewed case accepted' }
  Write-Output 'PASS: rule isolation, frozen prediction, independent/prospective evidence, counterexamples and coverage.'
} finally {
  if ((Split-Path -Parent ([IO.Path]::GetFullPath($tempRoot))) -ne ([IO.Path]::GetTempPath()).TrimEnd('\')) { throw 'Unexpected cleanup path' }
  Remove-Item -LiteralPath $tempRoot -Recurse -Force
}
