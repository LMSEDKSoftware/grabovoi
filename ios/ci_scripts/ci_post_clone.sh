#!/bin/sh
# Post-clone script for Xcode Cloud. Generates Flutter's Generated.xcconfig and
# runs CocoaPods so the iOS build finds all required files.
# See: https://docs.flutter.dev/deployment/cd#xcode-cloud

set -e

# The default execution directory is the ci_scripts directory. Go to repo root.
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter (shallow clone, stable channel)
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Precache iOS artifacts
flutter precache --ios

# Install Flutter dependencies (creates ios/Flutter/Generated.xcconfig)
flutter pub get

# Install CocoaPods and iOS pods (creates Pods/ and Target Support Files)
HOMEBREW_NO_AUTO_UPDATE=1
brew install cocoapods
cd ios && pod install

exit 0
