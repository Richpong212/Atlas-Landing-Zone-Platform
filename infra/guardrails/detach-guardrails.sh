#!/usr/bin/env bash
set -euo pipefail

ROOT_ID=$(aws organizations list-roots \
  --query "Roots[0].Id" \
  --output text)

SANDBOX_OU_ID=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --query "OrganizationalUnits[?Name=='Sandbox'].Id | [0]" \
  --output text)

detach_policy_by_name() {
  local policy_name="$1"

  POLICY_ID=$(aws organizations list-policies \
    --filter SERVICE_CONTROL_POLICY \
    --query "Policies[?Name=='$policy_name'].Id | [0]" \
    --output text)

  if [ "$POLICY_ID" = "None" ] || [ -z "$POLICY_ID" ]; then
    echo "Policy not found: $policy_name"
    return
  fi

  echo "Detaching $policy_name from Sandbox OU..."
  aws organizations detach-policy \
    --policy-id "$POLICY_ID" \
    --target-id "$SANDBOX_OU_ID" || true
}

detach_policy_by_name "atlas-deny-leaving-organization"
detach_policy_by_name "atlas-deny-disabling-cloudtrail"
detach_policy_by_name "atlas-approved-regions"

echo "Guardrails detached from Sandbox OU."
