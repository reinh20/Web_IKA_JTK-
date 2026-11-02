#!/bin/sh
#
# Run the app locally for development, pointed at the local backend.
#
# API_BASE_URL is read from config/dev.json and injected into the app via
# String.fromEnvironment('API_BASE_URL') in lib/core/app_config.dart.
# Edit config/dev.json to change the backend the dev app talks to.
#
# Usage:
#   ./run.sh                 # run on chrome against config/dev.json
#   ./run.sh -d <device>     # pass extra flutter args (e.g. another device)
#
set -e

fvm flutter run -d chrome --dart-define-from-file=config/dev.json "$@"
