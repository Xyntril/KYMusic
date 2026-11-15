#!/usr/bin/env bash
#
# Сборка AppImage и tar.gz для Linux x86_64.
#
# Использование:
#   ./scripts/build-appimage.sh        # сборка из уже установленного dist/
#   ./scripts/build-appimage.sh --full # полный цикл: configure -> build -> install -> AppImage + tar.gz
#
# Требования: cmake, ninja, Qt 6, linuxdeploy, linuxdeploy-plugin-qt,
# linuxdeploy-plugin-appimage. Скрипт сам скачивает linuxdeploy-инструменты
# в каталог .tools и переиспользует их при повторных запусках.
#
# AppImage-инструменты всегда извлекаются (--appimage-extract), поэтому
# FUSE на машине не требуется (важно для CI).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${ROOT_DIR}/.tools"
APPDIR="${ROOT_DIR}/build/appdir"
DIST_DIR="${ROOT_DIR}/dist"

LINUXDEPLOY="${TOOLS_DIR}/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT="${TOOLS_DIR}/linuxdeploy-plugin-qt-x86_64.AppImage"
LINUXDEPLOY_APPIMAGE="${TOOLS_DIR}/linuxdeploy-plugin-appimage-x86_64.AppImage"

LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_QT_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-qt/releases/download/continuous/linuxdeploy-plugin-qt-x86_64.AppImage"
LINUXDEPLOY_APPIMAGE_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-appimage/releases/download/1-alpha-20250213-1/linuxdeploy-plugin-appimage-x86_64.AppImage"

VERSION="$(sed -nE '/^project\(/,/^\)/s/.*VERSION[[:space:]]+([0-9.]+).*/\1/p' "${ROOT_DIR}/CMakeLists.txt" | head -1)"
VERSION="${VERSION:-1.0.0}"

APPIMAGE_NAME="KYMusic-${VERSION}-x86_64.AppImage"
TARBALL_NAME="KYMusic-${VERSION}-linux-x86_64.tar.gz"

log() { printf '\033[1;36m[appimage]\033[0m %s\n' "$*"; }

ensure_tool() {
  local path="$1" url="$2"
  local extracted="${path%.AppImage}.squashfs-root"
  if [[ ! -x "${extracted}/AppRun" ]]; then
    log "Downloading $(basename "${path}")..."
    mkdir -p "${TOOLS_DIR}"
    curl -fsSL -o "${path}" "${url}"
    chmod +x "${path}"
    rm -rf "${extracted}"
    (cd "${TOOLS_DIR}" && "${path}" --appimage-extract >/dev/null)
    mv "${TOOLS_DIR}/squashfs-root" "${extracted}"
  fi
}

run_tool() {
  local path="$1"; shift
  "${path%.AppImage}.squashfs-root/AppRun" "$@"
}

main() {
  if [[ "${1:-}" == "--full" ]]; then
    log "Full build: configure -> build -> install"
    cmake -S "${ROOT_DIR}" -B "${ROOT_DIR}/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${DIST_DIR}"
    cmake --build "${ROOT_DIR}/build" --parallel
    rm -rf "${DIST_DIR}" "${APPDIR}"
    cmake --install "${ROOT_DIR}/build"
  fi

  if [[ ! -d "${DIST_DIR}" ]]; then
    log "Directory 'dist/' not found. Run './scripts/build-appimage.sh --full' first or install the build."
    exit 1
  fi

  ensure_tool "${LINUXDEPLOY}" "${LINUXDEPLOY_URL}"
  ensure_tool "${LINUXDEPLOY_QT}" "${LINUXDEPLOY_QT_URL}"
  ensure_tool "${LINUXDEPLOY_APPIMAGE}" "${LINUXDEPLOY_APPIMAGE_URL}"

  # linuxdeploy ищет плагины рядом со своим бинарником (usr/bin внутри
  # squashfs-root) и в $PATH. Кладём ссылку на плагин в оба места.
  ln -sf "${LINUXDEPLOY_QT%.AppImage}.squashfs-root/AppRun" \
    "${LINUXDEPLOY%.AppImage}.squashfs-root/usr/bin/linuxdeploy-plugin-qt"

  ln -sf "${LINUXDEPLOY_QT%.AppImage}.squashfs-root/AppRun" \
    "${TOOLS_DIR}/linuxdeploy-plugin-qt"
  export PATH="${TOOLS_DIR}:${PATH}"

  export VERSION
  export QML_SOURCES_PATHS="${ROOT_DIR}/qml"

  local desktop_file="${DIST_DIR}/share/applications/org.kde.kymusic.desktop"
  if [[ ! -f "${desktop_file}" ]]; then
    if [[ -f "${ROOT_DIR}/build/org.kde.kymusic.desktop" ]]; then
      desktop_file="${ROOT_DIR}/build/org.kde.kymusic.desktop"
    else
      desktop_file="${ROOT_DIR}/build/org.kde.kymusic.desktop"
      mkdir -p "$(dirname "${desktop_file}")"
      cat <<EOF > "${desktop_file}"
[Desktop Entry]
Type=Application
Name=KYMusic
GenericName=Music Player
Comment=Native KDE music player client for Yandex Music
Exec=kymusic
Icon=kymusic
Terminal=false
Categories=Qt;KDE;AudioVideo;Audio;Player;Music;
EOF
    fi
  fi

  local icon_file="${ROOT_DIR}/resources/kymusic.svg"
  if [[ ! -f "${icon_file}" && -f "${DIST_DIR}/share/icons/hicolor/scalable/apps/kymusic.svg" ]]; then
    icon_file="${DIST_DIR}/share/icons/hicolor/scalable/apps/kymusic.svg"
  fi

  log "Bundling AppDir from dist/..."
  rm -rf "${APPDIR}"
  run_tool "${LINUXDEPLOY}" \
    --appdir "${APPDIR}" \
    --executable "${DIST_DIR}/bin/kymusic" \
    --desktop-file "${desktop_file}" \
    --icon-file "${icon_file}" \
    --plugin qt

  log "Building ${APPIMAGE_NAME}..."
  OUTPUT="${ROOT_DIR}/${APPIMAGE_NAME}" run_tool "${LINUXDEPLOY_APPIMAGE}" \
    --appdir "${APPDIR}"

  log "Packaging ${TARBALL_NAME}..."
  mkdir -p "${ROOT_DIR}/pkg/KYMusic"
  cp -a "${DIST_DIR}/." "${ROOT_DIR}/pkg/KYMusic/"
  tar -C "${ROOT_DIR}/pkg" -czf "${ROOT_DIR}/${TARBALL_NAME}" KYMusic
  rm -rf "${ROOT_DIR}/pkg"

  log "Done:"
  log "  AppImage: ${ROOT_DIR}/${APPIMAGE_NAME}"
  log "  Tarball:  ${ROOT_DIR}/${TARBALL_NAME}"
}

main "$@"
