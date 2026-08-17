<#
.SYNOPSIS
    Runs Gradle dependencyInsight for Jewel's compatibility-critical dependencies.

.DESCRIPTION
    Inspects the already configured Gradle project without modifying files or starting an application.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DependencyInsightTask,

    [Parameter(Mandatory = $true)]
    [string]$Configuration,

    [string]$GradleWrapper = (Join-Path (Get-Location) 'gradlew.bat'),

    [string[]]$Dependencies = @(
        'org.jetbrains.jewel',
        'org.jetbrains.compose',
        'org.jetbrains.kotlin',
        'com.intellij',
        'com.jetbrains.intellij.platform'
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $GradleWrapper -PathType Leaf)) {
    throw "未找到 Gradle Wrapper: $GradleWrapper"
}

$resolvedWrapper = (Resolve-Path -LiteralPath $GradleWrapper).Path
foreach ($dependency in $Dependencies) {
    Write-Host "`n=== dependencyInsight: $dependency ==="
    & $resolvedWrapper $DependencyInsightTask "--configuration=$Configuration" "--dependency=$dependency"
    if ($LASTEXITCODE -ne 0) {
        throw "dependencyInsight 失败: $dependency (exit code $LASTEXITCODE)"
    }
}
