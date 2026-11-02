#!/bin/sh
#
# Build the Flutter web app for PRODUCTION with the API base URL baked into
# the compiled JS.
#
# The URL is read from config/prod.json and injected via
# --dart-define-from-file, then read in code by
# String.fromEnvironment('API_BASE_URL') in lib/core/app_config.dart.
# The value is the backend host WITHOUT a trailing /api (the code adds /api).
#
# Usage:
#   ./build.sh                 # build with config/prod.json
#   ./build.sh --wasm          # pass extra flutter build args
#
# To change the production API URL, edit config/prod.json.
#
set -e

echo "Building web with config/prod.json:"
cat config/prod.json
echo ""

fvm flutter build web --dart-define-from-file=config/prod.json "$@"

echo ""
echo "Done. Output in build/web/"
