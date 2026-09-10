#!/usr/bin/env bash
set -euo pipefail

# ----------------------------------------
# IT Tools Infrastructure Teardown
# ----------------------------------------

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo
echo "========================================"
echo "      IT TOOLS AWS TEARDOWN"
echo "========================================"
echo
echo "WARNING:"
echo "This process will destroy all AWS resources"
echo "created specifically for the IT Tools project."
echo
echo "Shared AWS resources such as the twrz.co.uk"
echo "hosted zone and unrelated infrastructure"
echo "must remain untouched."
echo

# ----------------------------------------
# First confirmation
# ----------------------------------------

read -rp "Type DESTROY to continue: " CONFIRMATION

if [[ "$CONFIRMATION" != "DESTROY" ]]; then
  echo
  echo "Destroy cancelled."
  exit 0
fi

# ----------------------------------------
# Final confirmation
# ----------------------------------------

echo
echo "Are you sure?"
echo "This will remove the deployed IT Tools infrastructure."
echo

read -rp "Type yes to confirm: " FINAL_CONFIRMATION

if [[ "$FINAL_CONFIRMATION" != "yes" ]]; then
  echo
  echo "Destroy cancelled."
  exit 0
fi

# ----------------------------------------
# Destroy main infrastructure
# ----------------------------------------

echo
echo "========================================"
echo "Destroying main application infrastructure"
echo "========================================"
echo

cd "$PROJECT_ROOT/infra"

terraform init \
  -backend-config="bucket=it-tools-terraform-state-bdee587c"

terraform destroy -auto-approve

echo
echo "Main infrastructure destroyed."

# ----------------------------------------
# Destroy bootstrap infrastructure
# ----------------------------------------

echo
echo "========================================"
echo "Destroying bootstrap infrastructure"
echo "========================================"
echo

cd "$PROJECT_ROOT/bootstrap"

terraform init

terraform destroy -auto-approve

echo
echo "========================================"
echo "Terraform teardown completed"
echo "========================================"
echo
echo "Running final AWS verification..."

"$PROJECT_ROOT/scripts/verify-destroy.sh"