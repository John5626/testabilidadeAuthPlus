param(
    [Parameter(Mandatory)][string]$RunRoot
)

. (Join-Path $PSScriptRoot 'Common.ps1')
$resolvedRoot = (Resolve-Path $RunRoot).Path
$records = @(Import-Csv (Join-Path $resolvedRoot 'variant-runs.csv'))
if ($records.Count -eq 0) { throw 'No variant records found' }

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
        variant = $first.variant
        strategy = $first.strategy
        n = $group.Count
        outcome = $(if ($classes.Count -eq 1 -and $classes[0] -eq 'detected_assertion') { 'detected_stable' }
                    elseif ($classes.Count -eq 1 -and $classes[0] -eq 'survived') { 'survived_stable' }
                    elseif ($classes.Count -eq 1 -and $classes[0] -eq 'invalid_variant') { 'invalid_variant' }
                    else { 'unstable_inconclusive' })
        classifications = $classes -join ';'
        median_ms = $median
        min_ms = ($durations | Measure-Object -Minimum).Minimum
        max_ms = ($durations | Measure-Object -Maximum).Maximum
    }
}
$aggregate | Export-Csv -LiteralPath (Join-Path $resolvedRoot 'variant-summary.csv') -NoTypeInformation -Encoding utf8NoBOM
Save-Json $aggregate (Join-Path $resolvedRoot 'variant-summary.json')
Write-Output "VARIANT_SUMMARY_ROOT=$resolvedRoot"

