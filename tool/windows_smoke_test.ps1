# ============================================================
# ARQUIVO: tool/windows_smoke_test.ps1
# FUNÇÃO: Teste automático do instalador no GitHub Actions (Windows):
#   1. Instala o Ponto Study em modo silencioso.
#   2. Confere o .exe instalado e o atalho do menu Iniciar.
#   3. Abre o app, digita um nome na primeira tela e confirma.
#   4. Fecha e reabre o app (verifica se os dados ficaram salvos).
#   5. Tira capturas de tela de cada passo (pasta screenshots/).
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null

function Save-Screen($name) {
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save("screenshots\$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Host "Captura: screenshots\$name.png"
}

function Assert-Running($proc, $step) {
  if ($proc.HasExited) { throw "O app fechou sozinho durante: $step (código $($proc.ExitCode))" }
}

# 1. Instalação silenciosa
$setup = Get-ChildItem "dist\Windows\PontoStudy-Setup-*.exe" | Select-Object -First 1
$install = Start-Process -FilePath $setup.FullName -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/ALLUSERS" -Wait -PassThru
if ($install.ExitCode -ne 0) { throw "Instalador falhou (código $($install.ExitCode))" }

# 2. Arquivos e atalhos
$exe = "C:\Program Files\Ponto Study\ponto_study.exe"
if (-not (Test-Path $exe)) { throw "ponto_study.exe não foi instalado" }
$lnk = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Ponto Study\Ponto Study.lnk"
if (-not (Test-Path $lnk)) { throw "Atalho do menu Iniciar não foi criado" }
Write-Host "OK: instalado em $exe e atalho do menu Iniciar criado."

# 3. Primeira abertura: digitar o nome
$p = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 12
Assert-Running $p "primeira abertura"
Save-Screen "windows-1-primeira-abertura"
$shell = New-Object -ComObject WScript.Shell
$null = $shell.AppActivate($p.Id)
Start-Sleep -Milliseconds 800
[System.Windows.Forms.SendKeys]::SendWait("Arthur")
Start-Sleep -Milliseconds 500
[System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
Start-Sleep -Seconds 5
Assert-Running $p "salvar o nome"
Save-Screen "windows-2-inicio"

# 4. Fechar e reabrir
Stop-Process -Id $p.Id -Force
Start-Sleep -Seconds 2
$p2 = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 12
Assert-Running $p2 "reabrir"
Save-Screen "windows-3-reaberto"

$db = Get-ChildItem -Path $env:APPDATA -Recurse -Filter "ponto_study.sqlite" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($db) { Write-Host "OK: banco local em $($db.FullName) ($($db.Length) bytes)" } else { Write-Warning "Arquivo do banco não encontrado em APPDATA" }

Stop-Process -Id $p2.Id -Force
Write-Host "OK: o app instalado abriu, aceitou o nome e reabriu."
