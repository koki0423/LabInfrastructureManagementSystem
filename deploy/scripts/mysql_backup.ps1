$ErrorActionPreference = "Stop"

$containerName = "lims-db"
$dbName = "lims_v1"
$dbUser = "root"
$dbPassword = "test1234"
$retentionDays = 7

$limsDirectory = Join-Path ([Environment]::GetFolderPath("LocalApplicationData")) "LIMS"
$backupDirectory = Join-Path $limsDirectory "db-backups"
$logDirectory = Join-Path $limsDirectory "logs"
$logPath = Join-Path $logDirectory "mysql_backup.log"

New-Item -Path $backupDirectory -ItemType Directory -Force | Out-Null
New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null

function Write-BackupLog {
    param(
        [string]$Message
    )

    $line = "[{0}] {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Message
    Add-Content -LiteralPath $logPath -Value $line
}

try {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        throw "必要なコマンドが見つかりません: docker"
    }

    $containerNames = & docker ps --format "{{.Names}}"
    if ($LASTEXITCODE -ne 0) {
        throw "docker ps の実行に失敗しました。Docker Desktop が起動しているか確認してください。"
    }

    if ($containerNames -notcontains $containerName) {
        throw "対象コンテナが起動していません: $containerName"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $temporarySqlPath = Join-Path $backupDirectory ".${dbName}_${timestamp}.sql.tmp"
    $temporaryGzipPath = Join-Path $backupDirectory ".${dbName}_${timestamp}.sql.gz.tmp"
    $temporaryErrorPath = Join-Path $backupDirectory ".${dbName}_${timestamp}.err.tmp"
    $finalPath = Join-Path $backupDirectory "${dbName}_${timestamp}.sql.gz"

    Write-BackupLog "backup start: $finalPath"

    $dumpCommand = "exec mysqldump -u$dbUser -p$dbPassword --single-transaction --quick --routines --triggers $dbName"
    $dockerArguments = "exec $containerName sh -c `"$dumpCommand`""
    $process = Start-Process `
        -FilePath "docker" `
        -ArgumentList $dockerArguments `
        -NoNewWindow `
        -Wait `
        -PassThru `
        -RedirectStandardOutput $temporarySqlPath `
        -RedirectStandardError $temporaryErrorPath

    if ($process.ExitCode -ne 0) {
        $errorDetail = Get-Content -LiteralPath $temporaryErrorPath -Raw -ErrorAction SilentlyContinue
        throw "mysqldump に失敗しました。$errorDetail"
    }

    $inputStream = [System.IO.File]::OpenRead($temporarySqlPath)
    $outputStream = [System.IO.File]::Create($temporaryGzipPath)
    $gzipStream = [System.IO.Compression.GzipStream]::new(
        $outputStream,
        [System.IO.Compression.CompressionLevel]::Optimal,
        $false
    )

    try {
        $inputStream.CopyTo($gzipStream)
    }
    finally {
        $gzipStream.Dispose()
        $outputStream.Dispose()
        $inputStream.Dispose()
    }

    Move-Item -LiteralPath $temporaryGzipPath -Destination $finalPath -Force
    Remove-Item -LiteralPath $temporarySqlPath, $temporaryErrorPath -Force -ErrorAction SilentlyContinue
    Write-BackupLog "backup done: $finalPath"

    $expiration = (Get-Date).AddDays(-$retentionDays)
    Get-ChildItem -LiteralPath $backupDirectory -Filter "*.sql.gz" -File |
        Where-Object { $_.LastWriteTime -lt $expiration } |
        Remove-Item -Force

    Write-BackupLog "cleanup done: deleted backups older than $retentionDays days"
}
catch {
    if ($null -ne $temporarySqlPath) {
        Remove-Item -LiteralPath $temporarySqlPath, $temporaryGzipPath, $temporaryErrorPath -Force -ErrorAction SilentlyContinue
    }

    Write-BackupLog "ERROR: $($_.Exception.Message)"
    throw
}
