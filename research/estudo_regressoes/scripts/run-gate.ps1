param(
    [string]$RunId = ('gate-' + (Get-Date -Format 'yyyyMMdd-HHmmss')),
    [ValidateSet('N1','N2','N3','N4','N5','N6','N7','N8')][string]$ResumeFrom
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-WorkspacePaths
$candidateRoot = Join-Path (Join-Path $paths.RunsRoot 'gate') $RunId
if ($ResumeFrom) {
    if (-not (Test-Path -LiteralPath $candidateRoot)) { throw "Resume directory not found: $candidateRoot" }
    $runRoot = $candidateRoot
} else {
    $runRoot = New-RunDirectory -Parent (Join-Path $paths.RunsRoot 'gate') -RunId $RunId
}
$logsRoot = New-Item -ItemType Directory -Path (Join-Path $runRoot 'logs') -Force
$diffsRoot = New-Item -ItemType Directory -Path (Join-Path $runRoot 'diffs') -Force
$records = [System.Collections.Generic.List[object]]::new()
$catalog = Get-VariantCatalog
if ($ResumeFrom) {
    Import-Csv (Join-Path $runRoot 'gate-results.csv') | ForEach-Object {
        if (-not $_.PSObject.Properties['classification_note']) {
            $_ | Add-Member -NotePropertyName classification_note -NotePropertyValue ''
        }
        $records.Add($_)
    }
    $startIndex = [array]::IndexOf(@($catalog.Id), $ResumeFrom)
    $catalog = @($catalog[$startIndex..($catalog.Count - 1)])
    $resumeLog = Join-Path $logsRoot ("resume-$($ResumeFrom.ToLowerInvariant())-preflight-s2.txt")
    $resumePreflight = Invoke-TestStrategy 'S2' $paths.FrontendRoot $resumeLog
    Assert-NominalResult $resumePreflight
    Save-Json ([pscustomobject]@{
        resume_from = $ResumeFrom; passed = $resumePreflight.Passed; exit_code = $resumePreflight.ExitCode
        duration_ms = $resumePreflight.DurationMs; log = [System.IO.Path]::GetRelativePath($runRoot,$resumeLog)
        controller_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart')
        login_view_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/login_view.dart')
        root_view_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/studyapp_root_view.dart')
    }) (Join-Path $runRoot ("resume-$($ResumeFrom.ToLowerInvariant())-preflight.json"))
}

if ($ResumeFrom -eq 'N7') {
    $n6Record = $records | Where-Object variant -eq 'N6'
    if ($n6Record.outcome -eq 'inconclusive' -and $n6Record.s2 -eq 'detected_assertion') {
        $n6Record.analyze = 'quality_failure'
        $n6Record.outcome = 'blocked'
        $n6Record.classification_note = 'manual_review: analyzer dead_code warnings are mutation-caused quality failure; S2 assertion blocks gate'
        $manifestPath = Join-Path $runRoot $n6Record.manifest
        $manifest = Get-Content -Raw $manifestPath | ConvertFrom-Json
        ($manifest.steps | Where-Object name -eq 'analyze').classification = 'quality_failure'
        $manifest | Add-Member -NotePropertyName classification_review -NotePropertyValue $n6Record.classification_note -Force
        Save-Json $manifest $manifestPath
        $records | Export-Csv -LiteralPath (Join-Path $runRoot 'gate-results.csv') -NoTypeInformation -Encoding utf8NoBOM
        Save-Json $records (Join-Path $runRoot 'gate-results.json')
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
        $diffPath = Join-Path $diffsRoot ("$($variant.Id).patch")
        $diff = & git diff --no-index --no-color -- $backupPath $targetPath 2>&1 | Out-String
        [System.IO.File]::WriteAllText($diffPath, $diff, [System.Text.UTF8Encoding]::new($false))

        $steps = [System.Collections.Generic.List[object]]::new()
        $format = Invoke-LoggedCommand 'dart' @('format','--output=none','--set-exit-if-changed','lib','test') $paths.FrontendRoot (Join-Path $logsRoot ("{0}-format.txt" -f $variant.Id.ToLowerInvariant()))
        $steps.Add([pscustomobject]@{ name='format'; exit_code=$format.ExitCode; duration_ms=$format.DurationMs; classification=$(if($format.ExitCode -eq 0){'pass'}else{'quality_failure'}); log=[System.IO.Path]::GetRelativePath($runRoot,$format.LogPath) })

        $analyze = Invoke-LoggedCommand 'flutter' @('analyze','--no-pub') $paths.FrontendRoot (Join-Path $logsRoot ("{0}-analyze.txt" -f $variant.Id.ToLowerInvariant()))
        $analyzeClass = if ($analyze.ExitCode -eq 0) {
            'pass'
        } elseif ($analyze.Output -match 'error -|Error:|Compilation failed') {
            'invalid_variant'
        } elseif ($analyze.Output -match 'warning -|info -') {
            'quality_failure'
        } else {
            'infrastructure_error'
        }
        $steps.Add([pscustomobject]@{ name='analyze'; exit_code=$analyze.ExitCode; duration_ms=$analyze.DurationMs; classification=$analyzeClass; log=[System.IO.Path]::GetRelativePath($runRoot,$analyze.LogPath) })

        $s1 = Invoke-TestStrategy 'S1' $paths.FrontendRoot (Join-Path $logsRoot ("{0}-s1.txt" -f $variant.Id.ToLowerInvariant()))
        $s1Class = Get-VariantClassification $variant $s1
        $steps.Add([pscustomobject]@{ name='S1'; exit_code=$s1.ExitCode; passed=$s1.Passed; duration_ms=$s1.DurationMs; classification=$s1Class; log=[System.IO.Path]::GetRelativePath($runRoot,$s1.LogPath) })

        $s2 = Invoke-TestStrategy 'S2' $paths.FrontendRoot (Join-Path $logsRoot ("{0}-s2.txt" -f $variant.Id.ToLowerInvariant()))
        $s2Class = Get-VariantClassification $variant $s2
        $steps.Add([pscustomobject]@{ name='S2'; exit_code=$s2.ExitCode; passed=$s2.Passed; duration_ms=$s2.DurationMs; classification=$s2Class; log=[System.IO.Path]::GetRelativePath($runRoot,$s2.LogPath) })

        $artifactManifest = [pscustomobject]@{
            variant = $variant.Id; nominal_sha256 = $originalHash; mutated_sha256 = $mutatedHash
            diff_sha256 = Get-Sha256 $diffPath; generated_at = (Get-Date).ToString('o'); steps = $steps
        }
        $manifestPath = Join-Path $runRoot ("{0}-artifact-manifest.json" -f $variant.Id.ToLowerInvariant())
        Save-Json $artifactManifest $manifestPath
        $artifactPass = (Test-Path -LiteralPath $manifestPath) -and ((Get-Item $manifestPath).Length -gt 0) -and ($steps.Count -eq 4)

        $infra = @($steps | Where-Object { $_.classification -in @('infrastructure_error','inconclusive_unmatched_failure') }).Count -gt 0
        $qualityFailure = @($steps | Where-Object { $_.classification -eq 'quality_failure' }).Count -gt 0
        $invalid = @($steps | Where-Object { $_.classification -eq 'invalid_variant' }).Count -gt 0
        $detected = @($steps | Where-Object { $_.classification -eq 'detected_assertion' }).Count -gt 0
        $allPass = @($steps | Where-Object { $_.classification -ne 'pass' -and $_.classification -ne 'survived' }).Count -eq 0
        $gateOutcome = if (-not $artifactPass -or $infra) { 'inconclusive' } elseif ($invalid) { 'inconclusive_invalid_variant' } elseif ($detected) { 'blocked' } elseif ($qualityFailure) { 'blocked_quality' } elseif ($allPass) { 'not_blocked' } else { 'inconclusive' }

        $record = [pscustomobject]@{
            variant = $variant.Id; outcome = $gateOutcome; format = $steps[0].classification
            analyze = $steps[1].classification; s1 = $s1Class; s2 = $s2Class
            artifact_validation = $(if($artifactPass){'pass'}else{'fail'})
            nominal_sha256 = $originalHash; mutated_sha256 = $mutatedHash
            diff = [System.IO.Path]::GetRelativePath($runRoot,$diffPath)
            manifest = [System.IO.Path]::GetRelativePath($runRoot,$manifestPath)
            classification_note = ''
        }
        $records.Add($record)
        $records | Export-Csv -LiteralPath (Join-Path $runRoot 'gate-results.csv') -NoTypeInformation -Encoding utf8NoBOM
        Save-Json $records (Join-Path $runRoot 'gate-results.json')
        if ($gateOutcome -eq 'inconclusive') { throw "$($variant.Id): gate infrastructure inconclusive; stopping" }
    } finally {
        [System.IO.File]::WriteAllBytes($targetPath, $originalBytes)
    }
    if ((Get-Sha256 $targetPath) -ne $originalHash) { throw "$($variant.Id): gate restoration hash mismatch" }
}
Write-Output "GATE_RUN_ROOT=$runRoot"

