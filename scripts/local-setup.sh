#!/usr/bin/env bash
# local-setup.sh
#
# Installs dependencies for local development.
# Run from the repository root.

set -euo pipefail

echo "==> Installing frontend dependencies"
(cd frontend && npm install)

echo "==> Installing backend dependencies"
(cd backend && npm install)

echo ""
echo "==> Setup complete."
echo ""
echo "Next steps:"
echo "  1. Copy frontend/.env.example to frontend/.env and fill in the values."
echo "     (Run: terraform -chdir=infra/environments/dev output frontend_env_example)"
echo ""
echo "  2. Start the frontend dev server:"
echo "     cd frontend && npm run dev"
echo ""
echo "  3. Build the Lambda package:"
echo "     cd backend && npm run build:package"
