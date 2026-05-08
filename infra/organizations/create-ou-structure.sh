#!/usr/bin/env bash
set -euo pipefail

echo "Getting AWS Organization root ID..."

ROOT_ID=$(aws organizations list-roots \
  --query "Roots[0].Id" \
  --output text)

echo "Root ID: $ROOT_ID"

echo "Ensuring Service Control Policies are enabled..."

SCP_STATUS=$(aws organizations list-roots \
  --query "Roots[0].PolicyTypes[?Type=='SERVICE_CONTROL_POLICY'].Status | [0]" \
  --output text)

if [ "$SCP_STATUS" = "ENABLED" ]; then
  echo "Service Control Policies already enabled."
else
  echo "Enabling Service Control Policies..."
  aws organizations enable-policy-type \
    --root-id "$ROOT_ID" \
    --policy-type SERVICE_CONTROL_POLICY
fi

create_ou_if_not_exists() {
  local ou_name="$1"

  EXISTING_OU_ID=$(aws organizations list-organizational-units-for-parent \
    --parent-id "$ROOT_ID" \
    --query "OrganizationalUnits[?Name=='$ou_name'].Id | [0]" \
    --output text)

  if [ "$EXISTING_OU_ID" != "None" ] && [ -n "$EXISTING_OU_ID" ]; then
    echo "OU already exists: $ou_name ($EXISTING_OU_ID)"
  else
    echo "Creating OU: $ou_name"

    aws organizations create-organizational-unit \
      --parent-id "$ROOT_ID" \
      --name "$ou_name" \
      --query "OrganizationalUnit.{Id:Id,Name:Name}" \
      --output table
  fi
}

create_ou_if_not_exists "Security"
create_ou_if_not_exists "Infrastructure"
create_ou_if_not_exists "Workloads"
create_ou_if_not_exists "Sandbox"
create_ou_if_not_exists "Suspended"

echo "OU structure ready."
