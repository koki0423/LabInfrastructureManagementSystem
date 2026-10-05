param(
    [Parameter(Mandatory = $true)]
    [string]$WorkingDirectory,

    [Parameter(Mandatory = $true)]
    [string]$BinaryPath
)

$ErrorActionPreference = "Stop"

$logDirectory = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "LIMS\logs"
$logPath = Join-Path $logDirectory "backend.log"
New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null

function Write-BackendLog {
    param(
        [string]$Message
    )

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $logPath -Value $line
}

if (-not (Test-Path -LiteralPath $WorkingDirectory -PathType Container)) {
    throw "バックエンドフォルダが見つかりません: $WorkingDirectory"
}

if (-not (Test-Path -LiteralPath $BinaryPath -PathType Leaf)) {
    throw "バックエンドバイナリが見つかりません: $BinaryPath"
}

Set-Location -LiteralPath $WorkingDirectory

while ($true) {
    Write-BackendLog "backend start: $BinaryPath"
    & $BinaryPath *>> $logPath
    $exitCode = $LASTEXITCODE
    Write-BackendLog "backend stopped (exit code: $exitCode). Restarting in 5 seconds."
    Start-Sleep -Seconds 5
}
