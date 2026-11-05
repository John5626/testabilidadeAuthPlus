param(
    [string]$RunId = ('campaign-' + (Get-Date -Format 'yyyyMMdd-HHmmss')),
    [ValidateSet('N1','N2','N3','N4','N5','N6','N7','N8')][string]$ResumeFrom
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-WorkspacePaths
$candidateRoot = Join-Path (Join-Path $paths.RunsRoot 'variants') $RunId
if ($ResumeFrom) {
    if (-not (Test-Path -LiteralPath $candidateRoot)) { throw "Resume directory not found: $candidateRoot" }
    $runRoot = $candidateRoot
} else {
    $runRoot = New-RunDirectory -Parent (Join-Path $paths.RunsRoot 'variants') -RunId $RunId
}
$logsRoot = New-Item -ItemType Directory -Path (Join-Path $runRoot 'logs') -Force
$diffsRoot = New-Item -ItemType Directory -Path (Join-Path $runRoot 'diffs') -Force
$records = [System.Collections.Generic.List[object]]::new()
$restorations = [System.Collections.Generic.List[object]]::new()
$allCatalog = Get-VariantCatalog
$catalog = $allCatalog
if ($ResumeFrom) {
    $recordsPath = Join-Path $runRoot 'variant-runs.csv'
    $restorationsPath = Join-Path $runRoot 'restorations.csv'
    if (Test-Path -LiteralPath $recordsPath) {
        Import-Csv $recordsPath | ForEach-Object {
            if (-not $_.PSObject.Properties['classification_note']) {
                $_ | Add-Member -NotePropertyName classification_note -NotePropertyValue ''
            }
            $records.Add($_)
        }
    }
    if (Test-Path -LiteralPath $restorationsPath) { Import-Csv $restorationsPath | ForEach-Object { $restorations.Add($_) } }
    $startIndex = [array]::IndexOf(@($catalog.Id), $ResumeFrom)
    $catalog = @($catalog[$startIndex..($catalog.Count - 1)])
}

if ($ResumeFrom -eq 'N5') {
    $n5 = $allCatalog | Where-Object Id -eq 'N5'
    foreach ($record in @($records | Where-Object { $_.variant -eq 'N5' -and $_.classification -eq 'inconclusive_unmatched_failure' })) {
        $logPath = Join-Path $runRoot $record.log
        $output = [System.IO.File]::ReadAllText($logPath)
        $reviewResult = [pscustomobject]@{
            ExitCode = [int]$record.exit_code
            Passed = $null
            Expected = [int]$record.expected_tests
            Output = $output
        }
        $reviewed = Get-VariantClassification $n5 $reviewResult
        if ($reviewed -ne 'detected_assertion') { throw "N5 review did not produce detected_assertion: $reviewed" }
        $record.classification = $reviewed
        $record.classification_note = 'manual_review: direct assertions caused by permanent busy; prior applicable_path_no_oracle prediction disproved'
    }
    $records | Export-Csv -LiteralPath (Join-Path $runRoot 'variant-runs.csv') -NoTypeInformation -Encoding utf8NoBOM
    Save-Json $records (Join-Path $runRoot 'variant-runs.json')
}

$controllerPath = Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
$nominalControllerHash = Get-Sha256 $controllerPath
if ($nominalControllerHash -ne '523641C6CDC5242D2606E44C20D0C8752920CEDA062CE6A95CEA1169627899F8') {
    throw "Nominal controller hash mismatch before campaign: $nominalControllerHash"
}

$preflightName = if ($ResumeFrom) { "resume-$($ResumeFrom.ToLowerInvariant())-preflight-s2.txt" } else { 'preflight-s2.txt' }
$preflight = Invoke-TestStrategy 'S2' $paths.FrontendRoot (Join-Path $logsRoot $preflightName)
Assert-NominalResult $preflight
$preflightRecord = [pscustomobject]@{
    phase = $(if($ResumeFrom){"resume-$ResumeFrom"}else{'initial'}); strategy = 'S2'; expected = 27
    passed = $preflight.Passed; exit_code = $preflight.ExitCode; duration_ms = $preflight.DurationMs
    controller_sha256 = $nominalControllerHash; log = [System.IO.Path]::GetRelativePath($runRoot,$preflight.LogPath)
}
$preflightPath = Join-Path $runRoot 'preflight.csv'
if ($ResumeFrom -and (Test-Path -LiteralPath $preflightPath)) {
    $existingPreflight = @(Import-Csv $preflightPath)
    @($existingPreflight + $preflightRecord) | Export-Csv -LiteralPath $preflightPath -NoTypeInformation -Encoding utf8NoBOM
} else {
    $preflightRecord | Export-Csv -LiteralPath $preflightPath -NoTypeInformation -Encoding utf8NoBOM
}
if ($ResumeFrom) {
    $invalidRecord = @($records | Where-Object { $_.classification -eq 'invalid_variant' } | Select-Object -Last 1)
    if ($invalidRecord.Count -eq 1 -and -not @($restorations | Where-Object { $_.variant -eq $invalidRecord[0].variant })) {
        $invalidVariant = $allCatalog | Where-Object { $_.Id -eq $invalidRecord[0].variant }
        $invalidTarget = Join-Path $paths.FrontendRoot $invalidVariant.Target
        $restoredHash = Get-Sha256 $invalidTarget
        $expectedHash = $invalidRecord[0].nominal_sha256
        if ($restoredHash -ne $expectedHash) { throw "$($invalidVariant.Id): resume restoration hash mismatch" }
        $restorations.Add([pscustomobject]@{
            variant = $invalidVariant.Id; original_sha256 = $expectedHash; restored_sha256 = $restoredHash
            byte_restored = $true; sanity_passed = $preflight.Passed; sanity_exit_code = $preflight.ExitCode
            sanity_duration_ms = $preflight.DurationMs; sanity_log = [System.IO.Path]::GetRelativePath($runRoot,$preflight.LogPath)
        })
        $restorations | Export-Csv -LiteralPath (Join-Path $runRoot 'restorations.csv') -NoTypeInformation -Encoding utf8NoBOM
    }
}

foreach ($variant in $catalog) {
    $targetPath = Join-Path $paths.FrontendRoot $variant.Target
    $originalBytes = [System.IO.File]::ReadAllBytes($targetPath)
    $originalHash = Get-Sha256 $targetPath
    $backupPath = Join-Path $runRoot ("{0}-nominal-source.bin" -f $variant.Id.ToLowerInvariant())
    [System.IO.File]::WriteAllBytes($backupPath, $originalBytes)
    try {
        Set-VariantMutation $variant $targetPath
        $mutatedHash = Get-Sha256 $targetPath
        if ($mutatedHash -eq $originalHash) { throw "$($variant.Id): mutation did not change target" }
        $diffPath = Join-Path $diffsRoot ("$($variant.Id).patch")
        $diff = & git diff --no-index --no-color -- $backupPath $targetPath 2>&1 | Out-String
        [System.IO.File]::WriteAllText($diffPath, $diff, [System.Text.UTF8Encoding]::new($false))

        $variantInvalid = $false
        foreach ($strategy in $variant.Strategies) {
            $completed = @($records | Where-Object { $_.variant -eq $variant.Id -and $_.strategy -eq $strategy }).Count
            for ($repetition = ($completed + 1); $repetition -le 3; $repetition++) {
                $log = Join-Path $logsRoot ("{0}-{1}-r{2}.txt" -f $variant.Id.ToLowerInvariant(), $strategy.ToLowerInvariant(), $repetition)
                $result = Invoke-TestStrategy $strategy $paths.FrontendRoot $log
                $classification = Get-VariantClassification $variant $result
                $record = [pscustomobject]@{
                    variant = $variant.Id; strategy = $strategy; repetition = $repetition
                    applicability = $(if ($variant.Id -eq 'N5' -and $strategy -in @('S0','S1')) { 'applicable_path_no_oracle' } else { 'applicable' })
                    expected_tests = $result.Expected; passed = $result.Passed; exit_code = $result.ExitCode
                    duration_ms = $result.DurationMs; classification = $classification
                    nominal_sha256 = $originalHash; mutated_sha256 = $mutatedHash
                    diff = [System.IO.Path]::GetRelativePath($runRoot, $diffPath)
                    log = [System.IO.Path]::GetRelativePath($runRoot, $log)
                    classification_note = ''
                }
                $records.Add($record)
                $records | Export-Csv -LiteralPath (Join-Path $runRoot 'variant-runs.csv') -NoTypeInformation -Encoding utf8NoBOM
                Save-Json $records (Join-Path $runRoot 'variant-runs.json')
                if ($classification -eq 'invalid_variant') {
                    $variantInvalid = $true
                    break
                }
                if ($classification -in @('infrastructure_error', 'inconclusive_unmatched_failure')) {
                    throw "$($variant.Id)/$strategy/r$repetition stopped campaign: $classification"
                }
            }
            if ($variantInvalid) { break }
        }
    } finally {
        [System.IO.File]::WriteAllBytes($targetPath, $originalBytes)
    }
    $restoredHash = Get-Sha256 $targetPath
    $restored = $restoredHash -eq $originalHash
    $sanityLog = Join-Path $logsRoot ("{0}-restored-s2.txt" -f $variant.Id.ToLowerInvariant())
    if (-not $restored) { throw "$($variant.Id): byte restoration hash mismatch" }
    $sanity = Invoke-TestStrategy 'S2' $paths.FrontendRoot $sanityLog
    Assert-NominalResult $sanity
    $restorations.Add([pscustomobject]@{
        variant = $variant.Id; original_sha256 = $originalHash; restored_sha256 = $restoredHash
        byte_restored = $restored; sanity_passed = $sanity.Passed; sanity_exit_code = $sanity.ExitCode
        sanity_duration_ms = $sanity.DurationMs; sanity_log = [System.IO.Path]::GetRelativePath($runRoot, $sanityLog)
    })
    $restorations | Export-Csv -LiteralPath (Join-Path $runRoot 'restorations.csv') -NoTypeInformation -Encoding utf8NoBOM
}

$aggregate = foreach ($group in ($records | Group-Object variant, strategy)) {
    $first = $group.Group[0]
    $classes = @($group.Group.classification | Sort-Object -Unique)
    $durations = @($group.Group.duration_ms | ForEach-Object { [long]$_ } | Sort-Object)
    $median = if ($durations.Count % 2 -eq 0) {
        ($durations[$durations.Count / 2 - 1] + $durations[$durations.Count / 2]) / 2.0
    } else {
        $durations[[math]::Floor($durations.Count / 2)]
    }
    [pscustomobject]@{
        variant = $first.variant; strategy = $first.strategy; n = $group.Count
        outcome = $(if ($classes.Count -eq 1 -and $classes[0] -eq 'detected_assertion') { 'detected_stable' }
                    elseif ($classes.Count -eq 1 -and $classes[0] -eq 'survived') { 'survived_stable' }
                    else { 'unstable_inconclusive' })
        classifications = $classes -join ';'
        median_ms = $median
        min_ms = ($durations | Measure-Object -Minimum).Minimum
        max_ms = ($durations | Measure-Object -Maximum).Maximum
    }
}
$aggregate | Export-Csv -LiteralPath (Join-Path $runRoot 'variant-summary.csv') -NoTypeInformation -Encoding utf8NoBOM
Save-Json $aggregate (Join-Path $runRoot 'variant-summary.json')
Write-Output "VARIANT_RUN_ROOT=$runRoot"


