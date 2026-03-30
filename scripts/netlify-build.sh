#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.41.3}"
FLUTTER_DIR="$HOME/flutter"

echo "==> Installing Flutter $FLUTTER_VERSION"
if [ ! -d "$FLUTTER_DIR" ]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$FLUTTER_DIR/bin/cache/dart-sdk/bin:$PATH"

echo "==> Flutter doctor"
flutter doctor -v

echo "==> Getting dependencies"
flutter pub get

echo "==> Compiling native_executor.js web worker"
dart compile js ./web/native_executor.dart -o ./web/native_executor.js -m

echo "==> Building web"
flutter build web --release --no-tree-shake-icons

echo "==> Copying config"
cp config.sample.json build/web/config.json

echo "==> Build complete. Publish directory: build/web"
