param(
    [string]$RunId = ('rotated-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-WorkspacePaths
$runRoot = New-RunDirectory -Parent (Join-Path $paths.RunsRoot 'nominal') -RunId $RunId
$logsRoot = New-Item -ItemType Directory -Path (Join-Path $runRoot 'logs') -Force
$records = [System.Collections.Generic.List[object]]::new()

$environment = [pscustomobject]@{
    started_at = (Get-Date).ToString('o')
    frontend_head = 'anonymous-export' 
    controller_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart')
    widget_test_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'test/cotb_widget_regression_test.dart')
    flutter_version = ((& flutter --version 2>&1) -join "`n")
    protocol_sha256 = Get-Sha256 (Join-Path $paths.StudyRoot 'protocol.md')
}
Save-Json $environment (Join-Path $runRoot 'environment.json')

foreach ($strategy in @('S0', 'S1', 'S2')) {
    $log = Join-Path $logsRoot ("warmup-{0}.txt" -f $strategy.ToLowerInvariant())
    $result = Invoke-TestStrategy $strategy $paths.FrontendRoot $log
    $record = [pscustomobject]@{
        phase = 'warmup'; round = 0; order = 0; strategy = $strategy
        expected = $result.Expected; passed = $result.Passed; exit_code = $result.ExitCode
        duration_ms = $result.DurationMs; classification = $(if ($result.NominalPass) { 'nominal_pass' } else { 'nominal_failure' })
        log = [System.IO.Path]::GetRelativePath($runRoot, $log)
    }
    $records.Add($record)
    Assert-NominalResult $result
}

$orders = @(
    @('S0', 'S1', 'S2'),
    @('S1', 'S2', 'S0'),
    @('S2', 'S0', 'S1')
)
for ($round = 1; $round -le 10; $round++) {
    $order = $orders[($round - 1) % $orders.Count]
    for ($position = 0; $position -lt $order.Count; $position++) {
        $strategy = $order[$position]
        $log = Join-Path $logsRoot ("round-{0:d2}-{1:d2}-{2}.txt" -f $round, ($position + 1), $strategy.ToLowerInvariant())
        $result = Invoke-TestStrategy $strategy $paths.FrontendRoot $log
        $record = [pscustomobject]@{
            phase = 'measured'; round = $round; order = ($position + 1); strategy = $strategy
            expected = $result.Expected; passed = $result.Passed; exit_code = $result.ExitCode
            duration_ms = $result.DurationMs; classification = $(if ($result.NominalPass) { 'nominal_pass' } else { 'nominal_failure' })
            log = [System.IO.Path]::GetRelativePath($runRoot, $log)
        }
        $records.Add($record)
        $records | Export-Csv -LiteralPath (Join-Path $runRoot 'nominal-runs.csv') -NoTypeInformation -Encoding utf8NoBOM
        Save-Json $records (Join-Path $runRoot 'nominal-runs.json')
        Assert-NominalResult $result
    }
}

$summary = foreach ($strategy in @('S0', 'S1', 'S2')) {
    $values = @($records | Where-Object { $_.phase -eq 'measured' -and $_.strategy -eq $strategy } | ForEach-Object duration_ms | Sort-Object)
    $median = if ($values.Count % 2 -eq 0) {
        ($values[$values.Count / 2 - 1] + $values[$values.Count / 2]) / 2.0
    } else { $values[[math]::Floor($values.Count / 2)] }
    [pscustomobject]@{
        strategy = $strategy; n = $values.Count; median_ms = $median
        min_ms = ($values | Measure-Object -Minimum).Minimum
        max_ms = ($values | Measure-Object -Maximum).Maximum
        non_modal_results = @($records | Where-Object { $_.phase -eq 'measured' -and $_.strategy -eq $strategy -and $_.classification -ne 'nominal_pass' }).Count
    }
}
$summary | Export-Csv -LiteralPath (Join-Path $runRoot 'nominal-summary.csv') -NoTypeInformation -Encoding utf8NoBOM
Save-Json $summary (Join-Path $runRoot 'nominal-summary.json')
Write-Output "NOMINAL_RUN_ROOT=$runRoot"

