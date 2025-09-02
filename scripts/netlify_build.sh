#!/usr/bin/env bash
set -e

echo "⏳ Cloning Flutter SDK…"
if [ ! -d flutter ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable
fi

export PATH="$PWD/flutter/bin:$PATH"

echo "✅ Flutter version: $(flutter --version | head -n1)"

echo "🔧 Enabling web support…"
flutter config --enable-web

echo "📦 Fetching packages…"
flutter pub get

echo "🚀 Building Flutter web release…"
flutter build web --release
