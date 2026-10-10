# Готовит SSH-ключ ed25519 для подключения к серверу Hermes.
# Запускать НА СВОЁМ КОМПЬЮТЕРЕ (Windows, PowerShell), там где стоит Hermes Desktop:
#
#   powershell -ExecutionPolicy Bypass -File .\setup-ssh-key.ps1
#
# Существующий ключ не перезаписывается. Приватная часть никуда не выводится.

$ErrorActionPreference = "Stop"

$sshDir = Join-Path $HOME ".ssh"
$key    = Join-Path $sshDir "id_ed25519"
$pub    = "$key.pub"
$comment = "hermes-$env:USERNAME@$env:COMPUTERNAME"

if (-not (Test-Path $sshDir)) { New-Item -ItemType Directory -Path $sshDir | Out-Null }

if (Test-Path $key) {
    Write-Host "==> Ключ уже есть, беру существующий: $key"
} else {
    Write-Host "==> Создаю новый ключ ed25519: $key"
    # Без парольной фразы, чтобы Hermes Desktop мог открыть ключ сам.
    ssh-keygen -t ed25519 -a 100 -C $comment -f $key -N '""'
}

# ssh-agent как служба Windows
try {
    $svc = Get-Service ssh-agent -ErrorAction Stop
    if ($svc.StartType -eq 'Disabled') { Set-Service ssh-agent -StartupType Automatic }
    if ($svc.Status -ne 'Running')     { Start-Service ssh-agent }
    Write-Host "==> Добавляю ключ в ssh-agent"
    ssh-add $key
    ssh-add -l
} catch {
    Write-Warning "ssh-agent недоступен: $($_.Exception.Message). Ключ всё равно создан — ssh будет читать его из файла."
}

Write-Host ""
Write-Host "================ ПУБЛИЧНЫЙ КЛЮЧ ($pub) ================"
Get-Content $pub
Write-Host "======================================================="
Write-Host ""
Write-Host "Приватный ключ лежит в $key и остаётся только на этом компьютере."
Write-Host "Дальше, когда появится сервер:"
Write-Host "  type `"$pub`" | ssh root@SERVER_IP `"mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys`""
Write-Host "  ssh -i `"$key`" root@SERVER_IP"
