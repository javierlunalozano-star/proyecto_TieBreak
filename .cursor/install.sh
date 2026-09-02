#!/usr/bin/env bash
# Idempotent Cloud Agent bootstrap for the TieBreak Flutter app.
# Installs a pinned Flutter SDK (only when missing/mismatched) and fetches
# the project's Dart/Flutter dependencies.
set -euo pipefail

# Keep this in sync with the revision recorded in .metadata / pubspec.lock.
FLUTTER_VERSION="3.47.2"
FLUTTER_HOME="/opt/flutter"
FLUTTER_ARCHIVE="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${FLUTTER_ARCHIVE}"

installed_version() {
  [ -x "${FLUTTER_HOME}/bin/flutter" ] || return 0
  local marker="${FLUTTER_HOME}/bin/cache/flutter.version.json"
  [ -f "${marker}" ] || return 0
  grep -o '"frameworkVersion"[^,]*' "${marker}" | grep -o '[0-9][0-9.]*' | head -1
}

if [ "$(installed_version)" != "${FLUTTER_VERSION}" ]; then
  echo "Installing Flutter ${FLUTTER_VERSION} to ${FLUTTER_HOME}..."
  tmp_archive="$(mktemp --suffix=.tar.xz)"
  curl -fsSL -o "${tmp_archive}" "${FLUTTER_URL}"
  sudo rm -rf "${FLUTTER_HOME}"
  sudo tar -xf "${tmp_archive}" -C /opt
  sudo chown -R "$(id -u):$(id -g)" "${FLUTTER_HOME}"
  rm -f "${tmp_archive}"
else
  echo "Flutter ${FLUTTER_VERSION} already present; skipping download."
fi

# Expose flutter/dart on PATH without mutating shell profiles.
sudo ln -sf "${FLUTTER_HOME}/bin/flutter" /usr/local/bin/flutter
sudo ln -sf "${FLUTTER_HOME}/bin/dart" /usr/local/bin/dart

# Flutter reads its own git checkout to report versions.
git config --global --add safe.directory "${FLUTTER_HOME}" || true

export PATH="${FLUTTER_HOME}/bin:${PATH}"

flutter --version
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --enable-web --no-enable-android --no-enable-linux-desktop >/dev/null

# Prime the web tooling so the first build/run is fast.
flutter precache --web

# Resolve project dependencies against the committed pubspec.lock.
flutter pub get

echo "TieBreak environment ready."
