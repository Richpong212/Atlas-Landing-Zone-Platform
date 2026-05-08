#!/usr/bin/env bash
set -euo pipefail

ROOT_ID=$(aws organizations list-roots \
  --query "Roots[0].Id" \
  --output text)

SANDBOX_OU_ID=$(aws organizations list-organizational-units-for-parent \
  --parent-id "$ROOT_ID" \
  --query "OrganizationalUnits[?Name=='Sandbox'].Id | [0]" \
  --output text)

if [ "$SANDBOX_OU_ID" = "None" ] || [ -z "$SANDBOX_OU_ID" ]; then
  echo "Sandbox OU not found."
  exit 1
fi

create_policy_if_not_exists() {
  local policy_name="$1"
  local policy_file="$2"
  local description="$3"

  EXISTING_POLICY_ID=$(aws organizations list-policies \
    --filter SERVICE_CONTROL_POLICY \
    --query "Policies[?Name=='$policy_name'].Id | [0]" \
    --output text)

  if [ "$EXISTING_POLICY_ID" != "None" ] && [ -n "$EXISTING_POLICY_ID" ]; then
    echo "$EXISTING_POLICY_ID"
  else
    aws organizations create-policy \
      --name "$policy_name" \
      --description "$description" \
      --type SERVICE_CONTROL_POLICY \
      --content "file://$policy_file" \
      --query "Policy.PolicySummary.Id" \
      --output text
  fi
}

attach_policy_if_not_attached() {
  local policy_id="$1"
  local target_id="$2"

  ATTACHED=$(aws organizations list-policies-for-target \
    --target-id "$target_id" \
    --filter SERVICE_CONTROL_POLICY \
    --query "Policies[?Id=='$policy_id'].Id | [0]" \
    --output text)

  if [ "$ATTACHED" != "None" ] && [ -n "$ATTACHED" ]; then
    echo "Policy already attached: $policy_id"
  else
    echo "Attaching policy: $policy_id to $target_id"
    aws organizations attach-policy \
      --policy-id "$policy_id" \
      --target-id "$target_id"
  fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DENY_LEAVE_POLICY_ID=$(create_policy_if_not_exists \
  "atlas-deny-leaving-organization" \
  "$SCRIPT_DIR/scp-deny-leaving-organization.json" \
  "Deny member accounts from leaving the organization")

DENY_CLOUDTRAIL_POLICY_ID=$(create_policy_if_not_exists \
  "atlas-deny-disabling-cloudtrail" \
  "$SCRIPT_DIR/scp-deny-disabling-cloudtrail.json" \
  "Deny disabling or deleting CloudTrail")

APPROVED_REGIONS_POLICY_ID=$(create_policy_if_not_exists \
  "atlas-approved-regions" \
  "$SCRIPT_DIR/scp-approved-regions.json" \
  "Deny usage outside approved AWS regions")

attach_policy_if_not_attached "$DENY_LEAVE_POLICY_ID" "$SANDBOX_OU_ID"
attach_policy_if_not_attached "$DENY_CLOUDTRAIL_POLICY_ID" "$SANDBOX_OU_ID"
attach_policy_if_not_attached "$APPROVED_REGIONS_POLICY_ID" "$SANDBOX_OU_ID"

echo "Guardrails attached to Sandbox OU only."
