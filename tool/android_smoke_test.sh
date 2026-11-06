#!/usr/bin/env bash
# ============================================================
# ARQUIVO: tool/android_smoke_test.sh
# FUNÇÃO: Teste automático do APK num emulador Android (GitHub Actions).
#   Encontra botões pelo texto (acessibilidade do Android) e:
#   1. instala e abre o app; 2. digita o nome; 3. cria a matéria "Java";
#   4. inicia e finaliza o cronômetro; 5. fecha e reabre o app.
#   Tira capturas de tela de cada passo (pasta screenshots/ e log).
#
#   bash tool/android_smoke_test.sh <pasta-com-o-apk>
# ============================================================
set -euo pipefail

PKG=com.pontostudy.ponto_study
APK=$(ls "$1"/*.apk | head -1)
mkdir -p screenshots
WARN=""

alive() {
  if ! adb shell pidof "$PKG" > /dev/null; then
    echo "ERRO: o app não está em execução ($1)"
    adb logcat -d | grep -iE "flutter|AndroidRuntime|FATAL" | tail -60 || true
    exit 1
  fi
}

# Tira captura de tela e imprime também no log (base64), para conferência remota.
shot() {
  adb exec-out screencap -p > "screenshots/$1.png"
  base64 -w 60000 "screenshots/$1.png" | sed "s/^/SHOT:$1:/"
}

launch() {
  adb shell monkey -p "$PKG" -c android.intent.category.LAUNCHER 1 > /dev/null
}

# Toca no primeiro elemento cujo texto ou descrição contém $1.
tap_text() {
  for _ in 1 2 3 4 5; do
    adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1 || true
    adb pull /sdcard/ui.xml /tmp/ui.xml > /dev/null 2>&1 || true
    local xy
    xy=$(python3 - "$1" <<'PY' || true
import re, sys, xml.etree.ElementTree as ET
want = sys.argv[1]
try:
    nodes = list(ET.parse('/tmp/ui.xml').iter('node'))
except Exception:
    nodes = []
best = None
for n in nodes:
    label = (n.get('text') or '') + ' ' + (n.get('content-desc') or '')
    if want in label:
        x1, y1, x2, y2 = map(int, re.findall(r'\d+', n.get('bounds')))
        area = (x2 - x1) * (y2 - y1)
        # Escolhe o MENOR elemento que contém o texto (o botão, não o card).
        if area > 0 and (best is None or area < best[0]):
            best = (area, (x1 + x2) // 2, (y1 + y2) // 2)
if best:
    print(best[1], best[2])
PY
)
    if [ -n "$xy" ]; then
      adb shell input tap $xy
      echo "Toque em '$1' ($xy)"
      sleep 1.5
      return 0
    fi
    sleep 1.5
  done
  echo "AVISO: não encontrei '$1' na tela"
  WARN="$WARN\n - não encontrei '$1'"
  return 1
}

adb install -r "$APK"
echo "OK: APK instalado."

launch
sleep 15
alive "primeira abertura"
shot android-1-primeira-abertura

adb shell input text "Arthur"
sleep 1
adb shell input keyevent 66
sleep 5
alive "salvar o nome"
shot android-2-inicio

if tap_text "Criar matéria"; then
  sleep 2
  adb shell input text "Java"
  sleep 1
  adb shell input keyevent 111 || true   # fecha o teclado
  tap_text "Salvar" || true
  sleep 3
fi
alive "criar matéria"
tap_text "Matérias" || true
sleep 2
shot android-3-materias

if tap_text "Estudar"; then
  sleep 2
  # Diagnóstico: elementos visíveis na tela do cronômetro.
  adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1 || true
  adb pull /sdcard/ui.xml /tmp/ui.xml > /dev/null 2>&1 || true
  python3 -c "
import xml.etree.ElementTree as ET
for n in ET.parse('/tmp/ui.xml').iter('node'):
    t=(n.get('text') or '')+'|'+(n.get('content-desc') or '')
    if t!='|': print('UI:', n.get('class'), n.get('clickable'), n.get('bounds'), repr(t[:80]))
" || true
  if tap_text "Escolha a matéria"; then tap_text "Java" || true; fi
  if tap_text "Iniciar cronômetro"; then
    sleep 6
    shot android-4-cronometro
    if tap_text "Finalizar"; then tap_text "Salvar sessão" || true; fi
  fi
fi
sleep 2
alive "cronômetro"
tap_text "Início" || true
sleep 2
shot android-5-inicio-apos-estudo

adb shell am force-stop "$PKG"
sleep 2
launch
sleep 12
alive "reabrir"
shot android-6-reaberto

if [ -n "$WARN" ]; then echo -e "Avisos da navegação automática:$WARN"; fi
echo "OK: o app abriu, foi usado e reabriu no emulador sem fechar sozinho."
