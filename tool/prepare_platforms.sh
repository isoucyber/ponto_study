#!/usr/bin/env bash
# ============================================================
# ARQUIVO: tool/prepare_platforms.sh
# FUNÇÃO: Prepara o projeto para compilar no Android ou no Windows.
#         É executado pelo GitHub Actions (e pode ser usado no seu PC).
#
#   bash tool/prepare_platforms.sh android
#   bash tool/prepare_platforms.sh windows
#
# O que faz:
#   1. Gera a pasta da plataforma (android/ ou windows/) com "flutter create".
#   2. Coloca o nome "Ponto Study" na janela, no menu do celular e no .exe.
#   3. Baixa as dependências e gera o código do banco (Drift).
#   4. Gera os ícones do app a partir de assets/icon/.
# ============================================================
set -euo pipefail

PLATFORM="${1:?Informe a plataforma: android ou windows}"

flutter create --platforms="$PLATFORM" --org com.pontostudy --project-name ponto_study .

if [ "$PLATFORM" = "android" ]; then
  MANIFEST=android/app/src/main/AndroidManifest.xml
  sed -i 's/android:label="ponto_study"/android:label="Ponto Study"/' "$MANIFEST"
  grep -q 'android:label="Ponto Study"' "$MANIFEST"
fi

if [ "$PLATFORM" = "windows" ]; then
  # Título e tamanho inicial da janela.
  sed -i 's/L"ponto_study"/L"Ponto Study"/' windows/runner/main.cpp
  sed -i 's/Win32Window::Size size(1280, 720);/Win32Window::Size size(1280, 820);/' windows/runner/main.cpp
  # Nome do produto exibido nas propriedades do .exe.
  sed -i 's/VALUE "FileDescription", "ponto_study"/VALUE "FileDescription", "Ponto Study"/' windows/runner/Runner.rc
  sed -i 's/VALUE "ProductName", "ponto_study"/VALUE "ProductName", "Ponto Study"/' windows/runner/Runner.rc
  grep -q 'L"Ponto Study"' windows/runner/main.cpp
fi

flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run flutter_launcher_icons
