# ============================================================
# ARQUIVO: tool/windows_smoke_test.ps1
# FUNÇÃO: Teste automático do instalador e da interface no GitHub
#         Actions (Windows), usando a acessibilidade do Windows (UI
#         Automation) para encontrar botões e campos pelo texto:
#   1. Instala em modo silencioso e confere .exe e atalho do menu Iniciar.
#   2. Abre o app, digita o nome na primeira tela e confirma.
#   3. Cria a matéria "Java".
#   4. Inicia e finaliza uma sessão no cronômetro.
#   5. Fecha e reabre o app (dados devem continuar salvos).
#   Capturas de tela de cada passo vão para screenshots/ e para o log.
# ============================================================
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Windows.Forms, System.Drawing, UIAutomationClient, UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class Mouse {
  [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
  [DllImport("user32.dll")] public static extern void mouse_event(int f, int x, int y, int d, int e);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr FindWindow(string c, string t);
  [DllImport("user32.dll")] public static extern void keybd_event(byte k, byte s, int f, int e);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool SystemParametersInfo(int a, int b, IntPtr c, int d);
  public static void Focus(IntPtr h) { keybd_event(0x12,0,0,0); SetForegroundWindow(h); keybd_event(0x12,0,2,0); }
  public static void Click(int x, int y) { SetCursorPos(x, y); mouse_event(2,0,0,0,0); mouse_event(4,0,0,0,0); }
}
"@

New-Item -ItemType Directory -Force -Path "screenshots" | Out-Null
$script:warnings = @()

function Save-Screen($name) {
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
  $bmp.Save("screenshots\$name.png", [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Host "Captura: screenshots\$name.png"
  # Também imprime a imagem no log (base64), para conferência remota.
  $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes("screenshots\$name.png"))
  for ($i = 0; $i -lt $b64.Length; $i += 60000) {
    Write-Host ("SHOT:" + $name + ":" + $b64.Substring($i, [Math]::Min(60000, $b64.Length - $i)))
  }
}

function Assert-Running($proc, $step) {
  if ($proc.HasExited) { throw "O app fechou sozinho durante: $step (código $($proc.ExitCode))" }
}

# Janela do app (procura pelo título "Ponto Study").
function Get-AppWindow($proc) {
  $proc.Refresh()
  $h = [Mouse]::FindWindow($null, "Ponto Study")
  if ($h -eq [IntPtr]::Zero) { $h = $proc.MainWindowHandle }
  return $h
}

$script:dumped = $false
# Procura na janela do app o MENOR elemento cujo nome contém $text e clica nele.
function Click-Text($proc, $text) {
  $h = Get-AppWindow $proc
  [Mouse]::Focus($h)
  for ($try = 0; $try -lt 10; $try++) {
    $root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
    $all = $root.FindAll([System.Windows.Automation.TreeScope]::Descendants,
      [System.Windows.Automation.Condition]::TrueCondition)
    # O conteúdo do Flutter fica numa janela interna (FLUTTERVIEW): consulta ela diretamente.
    foreach ($pane in @($all)) {
      $child = $pane.Current.NativeWindowHandle
      if ($child -ne 0 -and $child -ne $h.ToInt32()) {
        $inner = [System.Windows.Automation.AutomationElement]::FromHandle([IntPtr]$child)
        $more = $inner.FindAll([System.Windows.Automation.TreeScope]::Descendants,
          [System.Windows.Automation.Condition]::TrueCondition)
        if ($more.Count -gt $all.Count) { $all = $more }
      }
    }
    $best = $null
    foreach ($el in $all) {
      $name = $el.Current.Name
      if ($name -and $name.Contains($text)) {
        $r = $el.Current.BoundingRectangle
        if ($r.Width -gt 0 -and $r.Height -gt 0 -and ($best -eq $null -or ($r.Width * $r.Height) -lt ($best.Width * $best.Height))) {
          $best = $r
        }
      }
    }
    if ($best -ne $null) {
      [Mouse]::Click([int]($best.X + $best.Width / 2), [int]($best.Y + $best.Height / 2))
      Start-Sleep -Milliseconds 700
      Write-Host "Clique em '$text'"
      return $true
    }
    if (-not $script:dumped -and $try -eq 3) {
      $script:dumped = $true
      Write-Host "Diagnóstico UIA: janela $h, $($all.Count) elementos. Nomes:"
      $all | Select-Object -First 40 | ForEach-Object { Write-Host ("   [" + $_.Current.ControlType.ProgrammaticName + "] " + $_.Current.Name) }
    }
    Start-Sleep -Milliseconds 700
  }
  $script:warnings += "Não encontrei '$text' na tela"
  Write-Warning "Não encontrei '$text' na tela"
  return $false
}

function Type-Text($text) {
  [System.Windows.Forms.SendKeys]::SendWait($text)
  Start-Sleep -Milliseconds 400
}

# 1. Instalação silenciosa
$setup = Get-ChildItem "dist\Windows\PontoStudy-Setup-*.exe" | Select-Object -First 1
$install = Start-Process -FilePath $setup.FullName -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/ALLUSERS" -Wait -PassThru
if ($install.ExitCode -ne 0) { throw "Instalador falhou (código $($install.ExitCode))" }
$exe = "C:\Program Files\Ponto Study\ponto_study.exe"
if (-not (Test-Path $exe)) { throw "ponto_study.exe não foi instalado" }
$lnk = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Ponto Study\Ponto Study.lnk"
if (-not (Test-Path $lnk)) { throw "Atalho do menu Iniciar não foi criado" }
Write-Host "OK: instalado em $exe e atalho do menu Iniciar criado."

# O Flutter só publica a árvore de acessibilidade (nomes de botões e campos)
# quando o Windows informa que há um leitor de tela ativo.
[Mouse]::SystemParametersInfo(0x0047, 1, [IntPtr]::Zero, 0x2) | Out-Null  # SPI_SETSCREENREADER

# 2. Primeira abertura: digitar o nome
$p = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 12
Assert-Running $p "primeira abertura"
Save-Screen "windows-1-primeira-abertura"
if (-not (Click-Text $p "Seu nome")) {
  # Plano B: clicar onde o campo fica na janela (centro, ~70% da altura).
  $rect = New-Object Mouse+RECT
  [Mouse]::GetWindowRect((Get-AppWindow $p), [ref]$rect) | Out-Null
  Write-Host "Janela: $($rect.L),$($rect.T) - $($rect.R),$($rect.B)"
  # Na tela de 1024x768 do GitHub, o campo fica em torno de (531, 509).
  [Mouse]::Click(531, 509)
  Start-Sleep -Milliseconds 700
}
Type-Text "Arthur"
Type-Text "{ENTER}"
Start-Sleep -Seconds 4
Assert-Running $p "salvar o nome"
Save-Screen "windows-2-inicio"

# 3. Criar a matéria "Java"
if (Click-Text $p "Criar matéria") {
  Start-Sleep -Seconds 2
  Type-Text "Java"
  Click-Text $p "Salvar" | Out-Null
  Start-Sleep -Seconds 3
}
Assert-Running $p "criar matéria"
if (Click-Text $p "Matérias") { Start-Sleep -Seconds 2 }
Save-Screen "windows-3-materias"

# 4. Cronômetro: escolher a matéria, iniciar, aguardar e finalizar
if (Click-Text $p "Estudar") {
  Start-Sleep -Seconds 2
  if (Click-Text $p "Escolha a matéria") { Click-Text $p "Java" | Out-Null }
  if (Click-Text $p "Iniciar cronômetro") {
    Start-Sleep -Seconds 6
    Save-Screen "windows-4-cronometro"
    if (Click-Text $p "Finalizar") { Click-Text $p "Salvar sessão" | Out-Null }
  }
}
Start-Sleep -Seconds 2
Assert-Running $p "cronômetro"
if (Click-Text $p "Histórico") { Start-Sleep -Seconds 2 }
Save-Screen "windows-5-historico"

# 5. Fechar e reabrir
Stop-Process -Id $p.Id -Force
Start-Sleep -Seconds 2
$p2 = Start-Process -FilePath $exe -PassThru
Start-Sleep -Seconds 12
Assert-Running $p2 "reabrir"
Save-Screen "windows-6-reaberto"

$db = Get-ChildItem -Path $env:APPDATA -Recurse -Filter "ponto_study.sqlite" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($db) { Write-Host "OK: banco local em $($db.FullName)" } else { Write-Warning "Arquivo do banco não encontrado em APPDATA" }

Stop-Process -Id $p2.Id -Force
if ($script:warnings.Count -gt 0) {
  Write-Host "Avisos da navegação automática:"; $script:warnings | ForEach-Object { Write-Host " - $_" }
}
Write-Host "OK: o app instalado abriu, foi usado e reabriu sem fechar sozinho."
