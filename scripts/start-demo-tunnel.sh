#!/usr/bin/env bash
# DEPRECATED — nginx gateway (:8090) removed. Use Orange Apigee for public API access.
set -euo pipefail

cat <<'EOF'
start-demo-tunnel.sh is deprecated.

The local nginx gateway on port 8090 was removed. Client apps use Orange Apigee:

  https://api-demo.orange.com/auth/api/v1/...

For mobile testers, build an Apigee APK:
  cd ../myboss-mobile && ./build-apigee-android.sh

See: docs/deployment/APIGEE_CLIENT_URLS.md
EOF

exit 1
