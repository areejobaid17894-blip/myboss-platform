#!/usr/bin/env bash
# DEPRECATED — local nginx gateway (:8090) removed. Use Apigee or direct service ports.
set -euo pipefail

cat <<'EOF'
deploy-mobile-web.sh is deprecated (nginx gateway removed).

Use instead:

  Backend (Docker):
    ./scripts/deploy-demo-server.sh

  Admin portal:
    cd ../myboss-admin && npm run dev              # local hot reload (:5173)
    cd ../myboss-admin && npm run build:apigee     # Apigee demo build
    open http://127.0.0.1:8081                     # after deploy-demo-server (Docker admin)

  Mobile app:
    cd ../myboss-mobile
    fvm flutter run --dart-define=GATEWAY_ORIGIN=https://api-demo.orange.com --dart-define=ENV=demo

  Mobile web (dev server):
    cd ../myboss-mobile && ./run-local-web.sh

  Docs:
    docs/deployment/APIGEE_CLIENT_URLS.md
EOF

exit 1
