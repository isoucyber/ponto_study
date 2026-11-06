#!/usr/bin/env bash
# ============================================================
# ARQUIVO: tool/android_smoke_test.sh
# FUNÇÃO: Teste automático do APK num emulador Android (GitHub Actions):
#   instala, abre, digita o nome, fecha, reabre e tira capturas de tela.
#   bash tool/android_smoke_test.sh <pasta-com-o-apk>
# ============================================================
set -euo pipefail

PKG=com.pontostudy.ponto_study
APK=$(ls "$1"/*.apk | head -1)
mkdir -p screenshots

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

adb install -r "$APK"
echo "OK: APK instalado."

launch
sleep 15
alive "primeira abertura"
shot android-1-primeira-abertura

adb shell input text "Arthur"
sleep 2
adb shell input keyevent 66
sleep 6
alive "salvar o nome"
shot android-2-inicio

adb shell am force-stop "$PKG"
sleep 2
launch
sleep 12
alive "reabrir"
shot android-3-reaberto

echo "OK: o app abriu, aceitou o nome e reabriu no emulador."
