#!/bin/bash
git config --global --add safe.directory /vercel/path0/flutter
curl -fsSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.32.8-stable.tar.xz | tar -xJ
export PATH="$PWD/flutter/bin:$PATH"
flutter config --enable-web
flutter pub get
