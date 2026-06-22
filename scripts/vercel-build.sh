#!/usr/bin/env bash
set -euo pipefail

FLUTTER_ROOT="$HOME/flutter"

if [ ! -d "$FLUTTER_ROOT" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_ROOT"
fi

export PATH="$FLUTTER_ROOT/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release
