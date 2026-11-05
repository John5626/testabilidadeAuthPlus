Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false

function Get-WorkspacePaths {
    $studyRoot = Split-Path -Parent $PSScriptRoot
    $workspaceRoot = (Resolve-Path (Join-Path $studyRoot '..\..')).Path
    [pscustomobject]@{
        StudyRoot = $studyRoot
        WorkspaceRoot = $workspaceRoot
        FrontendRoot = (Resolve-Path (Join-Path $workspaceRoot 'frontend')).Path
        RunsRoot = Join-Path $studyRoot 'runs'
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function New-RunDirectory {
    param(
        [Parameter(Mandatory)][string]$Parent,
        [Parameter(Mandatory)][string]$RunId
    )
    $path = Join-Path $Parent $RunId
    if (Test-Path -LiteralPath $path) {
        throw "Run directory already exists: $path"
    }
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    $path
}

function Get-StrategyDefinition {
    param([Parameter(Mandatory)][ValidateSet('S0', 'S1', 'S2')][string]$Strategy)
    $s0 = @('test/studyapp_flow_controller_test.dart')
    $s1 = $s0 + @(
        'test/cotb_authentication_testability_test.dart',
        'test/cotb_obsolete_response_conformance_test.dart'
    )
    switch ($Strategy) {
        'S0' { [pscustomobject]@{ Name = 'S0'; Expected = 17; Files = $s0 } }
        'S1' { [pscustomobject]@{ Name = 'S1'; Expected = 22; Files = $s1 } }
        'S2' { [pscustomobject]@{ Name = 'S2'; Expected = 27; Files = $s1 + @('test/cotb_widget_regression_test.dart') } }
    }
}

function Invoke-LoggedCommand {
    param(
        [Parameter(Mandatory)][string]$Executable,
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$WorkingDirectory,
        [Parameter(Mandatory)][string]$LogPath
    )
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    Push-Location $WorkingDirectory
    try {
        $output = & $Executable @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } finally {
        Pop-Location
        $watch.Stop()
    }
    [System.IO.File]::WriteAllText(
        $LogPath,
        $output,
        [System.Text.UTF8Encoding]::new($false)
    )
    [pscustomobject]@{
        Executable = $Executable
        Arguments = $Arguments
        Command = "$Executable $($Arguments -join ' ')"
        ExitCode = $exitCode
        DurationMs = $watch.ElapsedMilliseconds
        LogPath = $LogPath
        Output = $output
    }
}

function Get-PassedTestCount {
    param([Parameter(Mandatory)][string]$Output)
    $matches = [regex]::Matches($Output, '\+(?<passed>\d+)(?:\s+-\d+)?:\s+All tests passed!')
    if ($matches.Count -eq 0) { return $null }
    [int]$matches[$matches.Count - 1].Groups['passed'].Value
}

function Invoke-TestStrategy {
    param(
        [Parameter(Mandatory)][ValidateSet('S0', 'S1', 'S2')][string]$Strategy,
        [Parameter(Mandatory)][string]$FrontendRoot,
        [Parameter(Mandatory)][string]$LogPath
    )
    $definition = Get-StrategyDefinition $Strategy
    $result = Invoke-LoggedCommand `
        -Executable 'flutter' `
        -Arguments (@('test', '--no-pub') + $definition.Files + @('--reporter', 'expanded')) `
        -WorkingDirectory $FrontendRoot `
        -LogPath $LogPath
    $passed = Get-PassedTestCount $result.Output
    [pscustomobject]@{
        Strategy = $Strategy
        Expected = $definition.Expected
        Passed = $passed
        ExitCode = $result.ExitCode
        DurationMs = $result.DurationMs
        Command = $result.Command
        LogPath = $result.LogPath
        Output = $result.Output
        NominalPass = ($result.ExitCode -eq 0 -and $passed -eq $definition.Expected)
    }
}

function Assert-NominalResult {
    param([Parameter(Mandatory)]$Result)
    if (-not $Result.NominalPass) {
        throw "Nominal $($Result.Strategy) failed: exit=$($Result.ExitCode), passed=$($Result.Passed), expected=$($Result.Expected), log=$($Result.LogPath)"
    }
}

function Get-VariantCatalog {
    @(
        [pscustomobject]@{
            Id = 'N1'; Target = 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
            Strategies = @('S2'); FailurePatterns = @('W3 login persiste')
            Start = '  Future<void> logout() async {'; End = '  void openRegistration()'
            Old = '    sessionStore.clear();'; New = $null
        },
        [pscustomobject]@{
            Id = 'N2'; Target = 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
            Strategies = @('S2'); FailurePatterns = @('W3 login persiste')
            Start = '  Future<void> _startAuthenticatedSession('; End = '  bool _isAuthenticationCurrent'
            Old = '      await sessionStore.persistSession();'; New = $null
        },
        [pscustomobject]@{
            Id = 'N3'; Target = 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
            Strategies = @('S2'); FailurePatterns = @('W2 challenge MFA expirado')
            Start = '  Future<bool> verifyMfa(String code) async {'; End = '  Future<bool> requestPasswordRecovery'
            Old = '      _ensureChallengeIsUsable(challenge!);'; New = $null
        },
        [pscustomobject]@{
            Id = 'N4'; Target = 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
            Strategies = @('S0', 'S1', 'S2'); FailurePatterns = @('MFA inválido mantém challenge', 'W2 MFA recusado')
            Start = '  Future<bool> verifyMfa(String code) async {'; End = '  Future<bool> requestPasswordRecovery'
            Old = '      _errorMessage = error.toString();'; New = '      _returnToLoginAfterChallengeFailure(error);'
        },
        [pscustomobject]@{
            Id = 'N5'; Target = 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
            Strategies = @('S0', 'S1', 'S2'); FailurePatterns = @(
                'W1 login pendente',
                'login real challenge de termos não cria sessão',
                'login real MFA válido cria sessão ACCESS',
                'login real MFA inválido mantém challenge',
                'login real conflito no aceite recarrega versões'
            )
            Start = '  Future<bool> signIn({required String email, required String password}) async {'; End = '  Future<bool> retryPolicyOnboarding'
            Old = '        _busy = false;'; New = $null
        },
        [pscustomobject]@{
            Id = 'N6'; Target = 'lib/src/features/studyapp/presentation/login_view.dart'
            Strategies = @('S2'); FailurePatterns = @('W1 login pendente')
            Start = 'class _LoginViewState'; End = '                              if (widget.noticeMessage != null)'
            Old = '                              if (widget.errorMessage != null)'; New = '                              if (false && widget.errorMessage != null)'
        },
        [pscustomobject]@{
            Id = 'N7'; Target = 'lib/src/features/studyapp/presentation/studyapp_flow_controller.dart'
            Strategies = @('S2'); FailurePatterns = @('W4 falha transitória')
            Start = '  Future<void> resumeSession() async {'; End = '  void openLanding()'
            Old = "        _errorMessage = 'Não foi possível confirmar a sessão. Tente novamente.';"; New = $null
        },
        [pscustomobject]@{
            Id = 'N8'; Target = 'lib/src/features/studyapp/presentation/studyapp_root_view.dart'
            Strategies = @('S2'); FailurePatterns = @('W2 MFA recusado')
            Start = '            StudyAppStage.mfaChallenge => MfaChallengeView('; End = '            StudyAppStage.invitation =>'
            Old = '              onCancel: controller.leaveAuthenticationChallenge,'; New = '              onCancel: controller.openLanding,'
        }
    )
}

function Set-VariantMutation {
    param(
        [Parameter(Mandatory)]$Variant,
        [Parameter(Mandatory)][string]$TargetPath
    )
    $text = [System.IO.File]::ReadAllText($TargetPath)
    $startIndex = $text.IndexOf($Variant.Start, [System.StringComparison]::Ordinal)
    if ($startIndex -lt 0) { throw "$($Variant.Id): start marker not found" }
    $endIndex = $text.IndexOf($Variant.End, $startIndex + $Variant.Start.Length, [System.StringComparison]::Ordinal)
    if ($endIndex -lt 0) { throw "$($Variant.Id): end marker not found" }
    $segment = $text.Substring($startIndex, $endIndex - $startIndex)
    $occurrences = ([regex]::Matches($segment, [regex]::Escape($Variant.Old))).Count
    if ($occurrences -ne 1) { throw "$($Variant.Id): expected one transformation site, found $occurrences" }
    if ($null -eq $Variant.New) {
        $pattern = '(?m)^' + [regex]::Escape($Variant.Old) + '\r?\n'
        $mutatedSegment = [regex]::Replace($segment, $pattern, '', 1)
    } else {
        $mutatedSegment = $segment.Replace($Variant.Old, $Variant.New)
    }
    $mutated = $text.Substring(0, $startIndex) + $mutatedSegment + $text.Substring($endIndex)
    [System.IO.File]::WriteAllText($TargetPath, $mutated, [System.Text.UTF8Encoding]::new($false))
}

function Get-VariantClassification {
    param(
        [Parameter(Mandatory)]$Variant,
        [Parameter(Mandatory)]$TestResult
    )
    if ($TestResult.ExitCode -eq 0 -and $TestResult.Passed -eq $TestResult.Expected) {
        return 'survived'
    }
    $infrastructure = @(
        'Could not acquire lock', 'Waiting for another flutter command',
        'Unable to find git in your PATH', 'Failed host lookup',
        'SocketException', 'No space left on device', 'FileSystemException',
        'The flutter tool cannot access', 'ProcessException'
    )
    foreach ($pattern in $infrastructure) {
        if ($TestResult.Output.Contains($pattern, [System.StringComparison]::OrdinalIgnoreCase)) {
            return 'infrastructure_error'
        }
    }
    if ($TestResult.Output -match 'Error:|Compilation failed|Failed to load') {
        return 'invalid_variant'
    }
    foreach ($pattern in $Variant.FailurePatterns) {
        if ($TestResult.Output.Contains($pattern, [System.StringComparison]::OrdinalIgnoreCase)) {
            return 'detected_assertion'
        }
    }
    'inconclusive_unmatched_failure'
}

function Save-Json {
    param(
        [Parameter(Mandatory)]$Value,
        [Parameter(Mandatory)][string]$Path,
        [int]$Depth = 8
    )
    $Value | ConvertTo-Json -Depth $Depth | Set-Content -LiteralPath $Path -Encoding utf8NoBOM
}

