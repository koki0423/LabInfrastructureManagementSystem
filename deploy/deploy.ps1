$repo2Url = "https://github.com/koki0423/lims-front-v3.git"
$repo3Url = "https://github.com/koki0423/LIMS-back.git"

$repo2DirName = ""
$repo3DirName = ""

$scriptVersion = "deploy.ps1 v2026-10-02-final"

$backendBinaryName = "server.exe"
$backendTaskName = "LIMS Backend"
$backupTaskName = "LIMS MySQL Backup"
$backupSourceRelativePath = "scripts\mysql_backup.ps1"

$ErrorActionPreference = "Stop"

function Write-Step {
    param(
        [string]$Message
    )

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Write-Info {
    param(
        [string]$Message
    )

    Write-Host "[INFO] $Message" -ForegroundColor White
}

function Write-WarnMsg {
    param(
        [string]$Message
    )

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Success {
    param(
        [string]$Message
    )

    Write-Host "[ OK ] $Message" -ForegroundColor Green
}

function Get-RepoNameFromUrl {
    param(
        [string]$Url
    )

    $name = Split-Path $Url -Leaf

    if ($name.EndsWith(".git")) {
        $name = $name.Substring(0, $name.Length - 4)
    }

    return $name
}

function Require-Command {
    param(
        [string]$Name,
        [string]$InstallHint
    )

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "必要なコマンドが見つかりません: $Name`n$InstallHint"
    }
}

function Ensure-Administrator {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $currentPrincipal = [Security.Principal.WindowsPrincipal]::new($currentIdentity)

    if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "PowerShell を管理者として実行してから、もう一度 deploy.ps1 を実行してください。"
    }
}

function Invoke-CommandChecked {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList,
        [string]$WorkingDirectory,
        [string]$UserMessage
    )

    if (-not [string]::IsNullOrWhiteSpace($UserMessage)) {
        Write-Info $UserMessage
    }

    Push-Location $WorkingDirectory
    try {
        & $FilePath @ArgumentList
        if ($LASTEXITCODE -ne 0) {
            throw "コマンドの実行に失敗しました: $FilePath $($ArgumentList -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
}

function Assert-DockerComposeAvailable {
    & docker compose version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "docker compose を実行できません。Docker Desktop を起動してから、もう一度実行してください。"
    }
}

function ConvertTo-PowerShellSingleQuotedString {
    param(
        [string]$Value
    )

    return "'" + $Value.Replace("'", "''") + "'"
}

function New-PowerShellTaskAction {
    param(
        [string]$ScriptPath,
        [hashtable]$Parameters = @{}
    )

    $powerShellPath = (Get-Command powershell.exe -ErrorAction Stop).Source
    $argument = "-NoProfile -NonInteractive -ExecutionPolicy Bypass -File $(ConvertTo-PowerShellSingleQuotedString -Value $ScriptPath)"

    foreach ($parameterName in $Parameters.Keys) {
        $argument += " -$parameterName $(ConvertTo-PowerShellSingleQuotedString -Value ([string]$Parameters[$parameterName]))"
    }

    return New-ScheduledTaskAction -Execute $powerShellPath -Argument $argument
}

function Register-OrReplaceScheduledTask {
    param(
        [string]$TaskName,
        $Action,
        $Trigger,
        [string]$Description
    )

    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($null -ne $existingTask) {
        Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    }

    $settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries `
        -StartWhenAvailable `
        -RestartCount 3 `
        -RestartInterval (New-TimeSpan -Minutes 1)

    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $settings `
        -Description $Description `
        -Force | Out-Null
}

function Install-BackupScript {
    param(
        [string]$SourcePath
    )

    if (-not (Test-Path -LiteralPath $SourcePath -PathType Leaf)) {
        throw "バックアップスクリプトが見つかりません: $SourcePath"
    }

    $installDirectory = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "LIMS\scripts"
    $destinationPath = Join-Path $installDirectory "mysql_backup.ps1"

    New-Item -Path $installDirectory -ItemType Directory -Force | Out-Null
    Copy-Item -LiteralPath $SourcePath -Destination $destinationPath -Force

    Write-Success "バックアップスクリプトを配置しました: $destinationPath"
    return $destinationPath
}

function Register-BackendTask {
    param(
        [string]$RunnerScriptPath,
        [string]$BackendPath,
        [string]$BinaryPath
    )

    $action = New-PowerShellTaskAction `
        -ScriptPath $RunnerScriptPath `
        -Parameters @{
            WorkingDirectory = $BackendPath
            BinaryPath = $BinaryPath
        }
    $trigger = New-ScheduledTaskTrigger -AtLogOn

    Register-OrReplaceScheduledTask `
        -TaskName $backendTaskName `
        -Action $action `
        -Trigger $trigger `
        -Description "LIMS バックエンドをログオン時に起動します。"

    Start-ScheduledTask -TaskName $backendTaskName
    Write-Success "バックエンド自動起動タスクの設定と起動が完了しました。"
}

function Register-BackupTask {
    param(
        [string]$BackupScriptPath
    )

    $action = New-PowerShellTaskAction -ScriptPath $BackupScriptPath
    $trigger = New-ScheduledTaskTrigger -Daily -At 12:00AM

    Register-OrReplaceScheduledTask `
        -TaskName $backupTaskName `
        -Action $action `
        -Trigger $trigger `
        -Description "LIMS MySQL バックアップを毎日 0:00 に実行します。"

    Write-Success "バックアップ定期実行タスクを登録しました。"
}

try {
    Write-Host "実行スクリプト: $($MyInvocation.MyCommand.Path)" -ForegroundColor Magenta
    Write-Host "バージョン: $scriptVersion" -ForegroundColor Magenta

    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ([string]::IsNullOrWhiteSpace($scriptDir)) {
        $scriptDir = (Get-Location).Path
    }

    if ([string]::IsNullOrWhiteSpace($repo2DirName)) {
        $repo2DirName = Get-RepoNameFromUrl -Url $repo2Url
    }

    if ([string]::IsNullOrWhiteSpace($repo3DirName)) {
        $repo3DirName = Get-RepoNameFromUrl -Url $repo3Url
    }

    $envRepoPath = $scriptDir
    $frontendPath = Join-Path $envRepoPath "frontend"
    $backendBasePath = Join-Path $envRepoPath "backend"
    $repo2Path = Join-Path $frontendPath $repo2DirName
    $repo3Path = Join-Path $backendBasePath $repo3DirName
    $backendBinaryPath = Join-Path $repo3Path $backendBinaryName
    $docsGoPath = Join-Path $repo3Path "docs\docs.go"
    $composePath = Join-Path $envRepoPath "docker-compose.yml"
    $backendRunnerPath = Join-Path $envRepoPath "scripts\start_backend.ps1"
    $backupSourcePath = Join-Path $envRepoPath $backupSourceRelativePath

    Write-Step "[1/9] 事前準備を確認しています"
    Ensure-Administrator
    Require-Command -Name "git" -InstallHint "Git をインストールしてから、もう一度実行してください。"
    Require-Command -Name "go" -InstallHint "Go をインストールしてから、もう一度実行してください。"
    Require-Command -Name "docker" -InstallHint "Docker Desktop をインストールして起動してから、もう一度実行してください。"
    Require-Command -Name "Get-ScheduledTask" -InstallHint "Windows タスク スケジューラが利用できる Windows 環境で実行してください。"
    Require-Command -Name "Register-ScheduledTask" -InstallHint "Windows タスク スケジューラが利用できる Windows 環境で実行してください。"
    Assert-DockerComposeAvailable

    Write-Step "[2/9] ディレクトリ構成を確認しています"

    if (-not (Test-Path -LiteralPath $frontendPath -PathType Container)) {
        throw "frontend フォルダが見つかりません: $frontendPath"
    }

    if (-not (Test-Path -LiteralPath $backendBasePath -PathType Container)) {
        New-Item -Path $backendBasePath -ItemType Directory | Out-Null
        Write-Info "backend フォルダを新規作成しました。"
    }

    if (-not (Test-Path -LiteralPath $composePath -PathType Leaf)) {
        throw "docker-compose.yml が見つかりません: $composePath"
    }

    if (-not (Test-Path -LiteralPath $backendRunnerPath -PathType Leaf)) {
        throw "バックエンド起動スクリプトが見つかりません: $backendRunnerPath"
    }

    Write-Step "[3/9] 必要なリポジトリを確認しています"

    if (-not (Test-Path -LiteralPath $repo2Path -PathType Container)) {
        Write-WarnMsg "フロントエンドが見つからないため、clone します。"
        Invoke-CommandChecked `
            -FilePath "git" `
            -ArgumentList @("clone", $repo2Url, $repo2DirName) `
            -WorkingDirectory $frontendPath `
            -UserMessage "フロントエンドを取得しています..."
    }
    else {
        Write-Info "フロントエンドは既に存在するため、clone をスキップします。"
    }

    if (-not (Test-Path -LiteralPath $repo3Path -PathType Container)) {
        Write-WarnMsg "バックエンドが見つからないため、clone します。"
        Invoke-CommandChecked `
            -FilePath "git" `
            -ArgumentList @("clone", $repo3Url, $repo3DirName) `
            -WorkingDirectory $backendBasePath `
            -UserMessage "バックエンドを取得しています..."
    }
    else {
        Write-Info "バックエンドは既に存在するため、clone をスキップします。"
    }

    if (-not (Test-Path -LiteralPath $repo3Path -PathType Container)) {
        throw "バックエンドフォルダが見つかりません: $repo3Path"
    }

    Write-Step "[4/9] Swagger ドキュメントを生成しています"
    Invoke-CommandChecked `
        -FilePath "go" `
        -ArgumentList @("run", "github.com/swaggo/swag/cmd/swag@latest", "init", "-g", "main.go", "-o", "docs") `
        -WorkingDirectory $repo3Path `
        -UserMessage "Swagger ドキュメントを生成しています..."

    if (-not (Test-Path -LiteralPath $docsGoPath -PathType Leaf)) {
        throw "Swagger ドキュメントの生成に失敗しました: $docsGoPath"
    }

    Write-Success "Swagger ドキュメントの生成が完了しました。"

    Write-Step "[5/9] バックエンドをビルドしています"
    Invoke-CommandChecked `
        -FilePath "go" `
        -ArgumentList @("mod", "tidy") `
        -WorkingDirectory $repo3Path `
        -UserMessage "必要な Go パッケージを確認しています..."

    Invoke-CommandChecked `
        -FilePath "go" `
        -ArgumentList @("build", "-o", $backendBinaryName, ".") `
        -WorkingDirectory $repo3Path `
        -UserMessage "バックエンドをビルドしています..."

    if (-not (Test-Path -LiteralPath $backendBinaryPath -PathType Leaf)) {
        throw "バックエンドバイナリの作成に失敗しました: $backendBinaryPath"
    }

    Write-Success "バックエンドのビルドが完了しました。"

    Write-Step "[6/9] Docker コンテナを起動しています"
    Invoke-CommandChecked `
        -FilePath "docker" `
        -ArgumentList @("compose", "up", "-d") `
        -WorkingDirectory $envRepoPath `
        -UserMessage "必要なコンテナを起動しています..."
    Write-Success "Docker コンテナの起動が完了しました。"

    Write-Step "[7/9] バックエンド自動起動を設定しています"
    Register-BackendTask -RunnerScriptPath $backendRunnerPath -BackendPath $repo3Path -BinaryPath $backendBinaryPath

    Write-Step "[8/9] バックアップスクリプトを配置しています"
    $backupScriptPath = Install-BackupScript -SourcePath $backupSourcePath

    Write-Step "[9/9] バックアップ定期実行を設定しています"
    Register-BackupTask -BackupScriptPath $backupScriptPath

    Write-Host ""
    Write-Success "セットアップが完了しました。"
    Write-Info "フロントエンド: http://localhost"
    Write-Info "バックエンド タスク確認: Get-ScheduledTask -TaskName '$backendTaskName'"
    Write-Info "バックエンド ログ確認: Get-Content '$([Environment]::GetFolderPath("LocalApplicationData"))\LIMS\logs\backend.log' -Tail 100"
    Write-Info "バックアップ タスク確認: Get-ScheduledTask -TaskName '$backupTaskName'"
    Write-Info "バックアップ ログ確認: Get-Content '$([Environment]::GetFolderPath("LocalApplicationData"))\LIMS\logs\mysql_backup.log' -Tail 100"
    Write-Info "Docker 確認: docker compose ps"
}
catch {
    Write-Host ""
    Write-Host "セットアップ中にエラーが発生しました。" -ForegroundColor Red
    Write-Host "詳細: $($_.Exception.Message)" -ForegroundColor DarkGray
    exit 1
}
