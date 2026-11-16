#!/usr/bin/env bash
#
# Скрипт сборки Android APK для KYMusic.
#
# Использование:
#   ./scripts/build-apk.sh
#
# Автоматически находит Android SDK (через ANDROID_HOME, ANDROID_SDK_ROOT
# или локальные пути разработки), компилирует Java-классы плеера, упаковывает
# ресурсы, генерирует classes.dex, собирает, выравнивает (zipalign) и подписывает
# (apksigner) готовый к установке APK-файл.
#

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build-apk"
ANDROID_SRC="${ROOT_DIR}/android"

log() { printf '\033[1;32m[apk-build]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[apk-build:warn]\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m[apk-build:error]\033[0m %s\n' "$*"; exit 1; }

VERSION="$(sed -nE '/^project\(/,/^\)/s/.*VERSION[[:space:]]+([0-9.]+).*/\1/p' "${ROOT_DIR}/CMakeLists.txt" | head -1)"
VERSION="${VERSION:-1.0.0}"
OUTPUT_APK="${ROOT_DIR}/KYMusic-${VERSION}.apk"

# 1. Поиск Android SDK
SDK_DIR="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "${SDK_DIR}" || ! -d "${SDK_DIR}" ]]; then
  CANDIDATES=(
    "${HOME}/PycharmProjects/Shizo95/android/sdk"
    "${HOME}/Android/Sdk"
    "${HOME}/.android/sdk"
    "/opt/android-sdk"
    "/usr/lib/android-sdk"
  )
  for c in "${CANDIDATES[@]}"; do
    if [[ -d "$c" ]]; then
      SDK_DIR="$c"
      break
    fi
  done
fi

if [[ -z "${SDK_DIR}" || ! -d "${SDK_DIR}" ]]; then
  err "Android SDK не найден. Установите ANDROID_HOME или поместите SDK в ~/Android/Sdk"
fi

log "Используется Android SDK: ${SDK_DIR}"

# 2. Поиск build-tools
BUILD_TOOLS_DIR="$(find "${SDK_DIR}/build-tools" -mindepth 1 -maxdepth 1 -type d | sort -V | tail -n 1)"
if [[ -z "${BUILD_TOOLS_DIR}" || ! -d "${BUILD_TOOLS_DIR}" ]]; then
  err "build-tools не найдены внутри ${SDK_DIR}/build-tools"
fi

AAPT2="${BUILD_TOOLS_DIR}/aapt2"
D8="${BUILD_TOOLS_DIR}/d8"
ZIPALIGN="${BUILD_TOOLS_DIR}/zipalign"
APKSIGNER="${BUILD_TOOLS_DIR}/apksigner"

for tool in "${AAPT2}" "${D8}" "${ZIPALIGN}" "${APKSIGNER}"; do
  if [[ ! -x "${tool}" ]]; then
    err "Не найден исполняемый инструмент: ${tool}"
  fi
done

# 3. Поиск android.jar
PLATFORM_DIR="$(find "${SDK_DIR}/platforms" -mindepth 1 -maxdepth 1 -type d -name "android-*" | sort -V | tail -n 1)"
if [[ -z "${PLATFORM_DIR}" || ! -f "${PLATFORM_DIR}/android.jar" ]]; then
  err "android.jar не найден в ${SDK_DIR}/platforms"
fi
ANDROID_JAR="${PLATFORM_DIR}/android.jar"
log "Используется платформа: $(basename "${PLATFORM_DIR}") (${ANDROID_JAR})"

# 4. Подготовка директории сборки
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/classes" "${BUILD_DIR}/res_compiled"

# 5. Компиляция Java исходников
log "Компиляция Java классов..."
javac --release 8 -cp "${ANDROID_JAR}" -d "${BUILD_DIR}/classes" \
  "${ANDROID_SRC}/src/org/kde/kymusic"/*.java

# 6. Конвертация в DEX через d8
log "Генерация classes.dex через D8..."
"${D8}" --output "${BUILD_DIR}" --lib "${ANDROID_JAR}" \
  "${BUILD_DIR}/classes/org/kde/kymusic"/*.class

# 7. Компиляция ресурсов через aapt2
log "Компиляция ресурсов (aapt2 compile)..."
"${AAPT2}" compile --dir "${ANDROID_SRC}/res" -o "${BUILD_DIR}/res.zip"

# 8. Линковка APK (aapt2 link)
log "Линковка APK (aapt2 link)..."
"${AAPT2}" link \
  -I "${ANDROID_JAR}" \
  --manifest "${ANDROID_SRC}/AndroidManifest.xml" \
  "${BUILD_DIR}/res.zip" \
  -o "${BUILD_DIR}/unaligned.apk"

# 9. Добавление classes.dex и метаданных
log "Добавление classes.dex в APK..."
(cd "${BUILD_DIR}" && zip -u -q unaligned.apk classes.dex)

# 10. Выравнивание zipalign 4
log "Выравнивание zip-архива (zipalign 4)..."
"${ZIPALIGN}" -f 4 "${BUILD_DIR}/unaligned.apk" "${BUILD_DIR}/aligned.apk"

# 11. Подпись APK через debug.keystore
KEYSTORE="${HOME}/.android/debug.keystore"
if [[ ! -f "${KEYSTORE}" ]]; then
  log "Генерация debug.keystore..."
  mkdir -p "$(dirname "${KEYSTORE}")"
  keytool -genkey -v -keystore "${KEYSTORE}" -storepass android -alias androiddebugkey \
    -keypass android -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=Android Debug,O=Android,C=US"
fi

log "Подпись APK (apksigner)..."
"${APKSIGNER}" sign \
  --ks "${KEYSTORE}" \
  --ks-pass pass:android \
  --key-pass pass:android \
  --ks-key-alias androiddebugkey \
  --out "${OUTPUT_APK}" \
  "${BUILD_DIR}/aligned.apk"

# 12. Верификация подписи
log "Верификация APK..."
"${APKSIGNER}" verify --verbose "${OUTPUT_APK}" >/dev/null

log "Готово! Собран рабочий APK:"
log "  -> ${OUTPUT_APK}"
ls -lh "${OUTPUT_APK}"
