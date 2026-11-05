param(
    [string]$RunId = ('validation-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-WorkspacePaths
$runRoot = New-RunDirectory -Parent (Join-Path $paths.RunsRoot 'validation') -RunId $RunId

$s2 = Invoke-TestStrategy 'S2' $paths.FrontendRoot (Join-Path $runRoot 's2.txt')
Assert-NominalResult $s2
$analyze = Invoke-LoggedCommand 'flutter' @('analyze','--no-pub') $paths.FrontendRoot (Join-Path $runRoot 'analyze.txt')
if ($analyze.ExitCode -ne 0) { throw "Nominal analyze failed: $($analyze.LogPath)" }
$format = Invoke-LoggedCommand 'dart' @('format','--output=none','--set-exit-if-changed','lib','test') $paths.FrontendRoot (Join-Path $runRoot 'format.txt')
if ($format.ExitCode -ne 0) { throw "Nominal format failed: $($format.LogPath)" }
$diff = [pscustomobject]@{ ExitCode = $null; DurationMs = $null } # No original Git history in the anonymous export

$result = [pscustomobject]@{
    s2_passed = $s2.Passed; s2_exit_code = $s2.ExitCode; s2_duration_ms = $s2.DurationMs
    analyze_exit_code = $analyze.ExitCode; analyze_duration_ms = $analyze.DurationMs
    format_exit_code = $format.ExitCode; format_duration_ms = $format.DurationMs
    diff_check_exit_code = $diff.ExitCode; diff_check_duration_ms = $diff.DurationMs
    controller_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart')
    login_view_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/login_view.dart')
    root_view_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'lib/src/features/studyapp/presentation/studyapp_root_view.dart')
    widget_test_sha256 = Get-Sha256 (Join-Path $paths.FrontendRoot 'test/cotb_widget_regression_test.dart')
}
Save-Json $result (Join-Path $runRoot 'validation.json')
Write-Output "VALIDATION_RUN_ROOT=$runRoot"

