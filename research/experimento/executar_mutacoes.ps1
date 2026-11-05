param(
    [Parameter(Mandatory = $true)]
    [string]$Worktree,
    [string]$Only
)

$ErrorActionPreference = 'Stop'
$controllerPath = Join-Path $Worktree 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
$originalRaw = [System.IO.File]::ReadAllText($controllerPath)
$original = $originalRaw.Replace("`r`n", "`n")
$evidenceDirectory = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\evidencias\mutacoes\bruto'))
New-Item -ItemType Directory -Force -Path $evidenceDirectory | Out-Null

function Replace-First([string]$text, [string]$old, [string]$new) {
    $index = $text.IndexOf($old, [System.StringComparison]::Ordinal)
    if ($index -lt 0) {
        throw "Trecho da variante não encontrado: $old"
    }
    return $text.Substring(0, $index) + $new + $text.Substring($index + $old.Length)
}

$variants = @(
    [ordered]@{
        id = 'F1'
        old = "case AuthenticationChallenge(`n          type: AuthChallengeType.termsAcceptanceRequired,`n        ):`n          sessionStore.keepChallenge(result);`n          _workspace = null;`n          _stage = StudyAppStage.policyOnboarding;"
        new = "case AuthenticationChallenge(`n          type: AuthChallengeType.termsAcceptanceRequired,`n        ):`n          sessionStore.keepChallenge(result);`n          _workspace = null;`n          _stage = StudyAppStage.workspace;"
    },
    [ordered]@{
        id = 'F2'
        old = "case AuthenticationChallenge(type: AuthChallengeType.mfaRequired):`n          sessionStore.keepChallenge(result);`n          _workspace = null;`n          _stage = StudyAppStage.mfaChallenge;"
        new = "case AuthenticationChallenge(type: AuthChallengeType.mfaRequired):`n          sessionStore.keepChallenge(result);`n          _workspace = null;`n          _stage = StudyAppStage.workspace;"
    },
    [ordered]@{
        id = 'F3'
        old = "} on IdentitySessionInvalidException {`n      if (_stage != StudyAppStage.restoring) return;`n      sessionStore.clear();`n      _stage = StudyAppStage.login;"
        new = "} on IdentitySessionInvalidException {`n      if (_stage != StudyAppStage.restoring) return;`n      sessionStore.clear();`n      _stage = StudyAppStage.workspace;"
    },
    [ordered]@{
        id = 'F4'
        old = "} catch (_) {`n      if (authenticationGeneration != null &&`n          !_isAuthenticationCurrent(authenticationGeneration)) {`n        return;`n      }`n      sessionStore.clear();`n      _workspace = null;`n      _stage = StudyAppStage.login;`n      rethrow;`n    }`n    await sessionStore.persistSession();"
        new = "} catch (_) {`n      _workspace = null;`n      return;`n    }`n    await sessionStore.persistSession();"
    },
    [ordered]@{
        id = 'F5'
        old = "if (!session.expiresAt.isAfter(DateTime.now().toUtc())) {"
        new = "if (false && !session.expiresAt.isAfter(DateTime.now().toUtc())) {"
    },
    [ordered]@{
        id = 'F6'
        old = "void _setStage(StudyAppStage value) {`n    _invalidateAuthenticationOperation();"
        new = "void _setStage(StudyAppStage value) {"
    },
    [ordered]@{
        id = 'F7'
        old = "if (authenticationGeneration != null &&`n          !_isAuthenticationCurrent(authenticationGeneration)) {`n        sessionStore.clear();`n        return;`n      }`n      _workspace = workspace;"
        new = "_workspace = workspace;"
    },
    [ordered]@{
        id = 'F8'
        old = "} catch (error) {`n      if (!_isAuthenticationCurrent(generation)) return false;`n      sessionStore.clear();`n      _errorMessage = error.toString();"
        new = "} catch (error) {`n      sessionStore.clear();`n      _errorMessage = error.toString();"
    }
)

$results = @()
try {
    foreach ($variant in $variants) {
        if ($Only -and $variant.id -ne $Only) {
            continue
        }
        $mutated = Replace-First $original $variant.old $variant.new
        [System.IO.File]::WriteAllText($controllerPath, $mutated)

        Push-Location $Worktree
        try {
            $baseOutput = (& flutter test --no-pub test/studyapp_flow_controller_test.dart --reporter compact 2>&1 | Out-String)
            $baseExit = $LASTEXITCODE
            $expandedOutput = (& flutter test --no-pub test/studyapp_flow_controller_test.dart test/cotb_authentication_testability_test.dart test/cotb_obsolete_response_conformance_test.dart --reporter compact 2>&1 | Out-String)
            $expandedExit = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        [System.IO.File]::WriteAllText((Join-Path $evidenceDirectory "$($variant.id)-existente.txt"), $baseOutput)
        [System.IO.File]::WriteAllText((Join-Path $evidenceDirectory "$($variant.id)-ampliada.txt"), $expandedOutput)

        $baseAssertionFailure = $baseOutput -match 'Some tests failed|Expected:|Actual:'
        $expandedAssertionFailure = $expandedOutput -match 'Some tests failed|Expected:|Actual:'

        $results += [ordered]@{
            id = $variant.id
            baseExitCode = $baseExit
            expandedExitCode = $expandedExit
            baseDetected = ($baseExit -ne 0 -and $baseAssertionFailure)
            expandedDetected = ($expandedExit -ne 0 -and $expandedAssertionFailure)
            baseRunClassification = $(if ($baseExit -eq 0) { 'survived' } elseif ($baseAssertionFailure) { 'detected-by-assertion' } else { 'invalid-run' })
            expandedRunClassification = $(if ($expandedExit -eq 0) { 'survived' } elseif ($expandedAssertionFailure) { 'detected-by-assertion' } else { 'invalid-run' })
            baseSummary = (($baseOutput -split "`r?`n") | Where-Object { $_ -match 'All tests passed|Some tests failed|Expected:|Actual:' } | Select-Object -Last 4) -join ' | '
            expandedSummary = (($expandedOutput -split "`r?`n") | Where-Object { $_ -match 'All tests passed|Some tests failed|Expected:|Actual:' } | Select-Object -Last 4) -join ' | '
        }
    }
}
finally {
    [System.IO.File]::WriteAllText($controllerPath, $originalRaw)
}

$results | ConvertTo-Json -Depth 4

