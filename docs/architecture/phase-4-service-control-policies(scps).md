Yes. Next is:

# Phase 4 — Guardrails and Governance

Guardrails are **rules for the AWS organization**.

AWS SCPs are used as **coarse-grained guardrails**. They do not grant permissions; they only define the maximum permissions an account can use. ([AWS Documentation][1])

## What we create in Phase 4

```text
infra/guardrails/
├── scp-deny-leaving-organization.json
├── scp-deny-disabling-cloudtrail.json
├── scp-approved-regions.json
├── attach-guardrails.sh
└── detach-guardrails.sh
```

We will start safely:

```text
✅ Create SCP policy files
✅ Create attach/detach scripts
✅ Wire them into main deploy/destroy
⚠️ Attach only to Sandbox first
```

Do **not attach strict SCPs to root yet**. AWS recommends testing SCPs carefully before applying them broadly. ([AWS Documentation][1])

---

## 1. Create files

```bash
mkdir -p infra/guardrails

touch infra/guardrails/scp-deny-leaving-organization.json
touch infra/guardrails/scp-deny-disabling-cloudtrail.json
touch infra/guardrails/scp-approved-regions.json
touch infra/guardrails/attach-guardrails.sh
touch infra/guardrails/detach-guardrails.sh

chmod +x infra/guardrails/attach-guardrails.sh
chmod +x infra/guardrails/detach-guardrails.sh
```

---

## 2. Deny accounts from leaving organization

```bash
cat > infra/guardrails/scp-deny-leaving-organization.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyLeavingOrganization",
      "Effect": "Deny",
      "Action": [
        "organizations:LeaveOrganization"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

---

## 3. Deny disabling CloudTrail

```bash
cat > infra/guardrails/scp-deny-disabling-cloudtrail.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyDisablingCloudTrail",
      "Effect": "Deny",
      "Action": [
        "cloudtrail:StopLogging",
        "cloudtrail:DeleteTrail",
        "cloudtrail:UpdateTrail"
      ],
      "Resource": "*"
    }
  ]
}
EOF
```

---

## 4. Approved regions SCP

AWS supports denying access based on `aws:RequestedRegion`, but some global services must be excluded. ([AWS Documentation][2])

```bash
cat > infra/guardrails/scp-approved-regions.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyOutsideApprovedRegions",
      "Effect": "Deny",
      "NotAction": [
        "iam:*",
        "organizations:*",
        "route53:*",
        "cloudfront:*",
        "support:*",
        "budgets:*",
        "billing:*",
        "account:*"
      ],
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "us-east-1",
            "eu-west-1"
          ]
        }
      }
    }
  ]
}
EOF
```

---

## 5. Attach script

```bash
cat > infra/guardrails/attach-guardrails.sh <<'EOF'
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
EOF
```

---

## 6. Detach script

```bash
cat > infra/guardrails/detach-guardrails.sh <<'EOF'
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
EOF
```

---

## 7. Run it

```bash
./infra/guardrails/attach-guardrails.sh
```

Verify:

```bash
aws organizations list-policies-for-target \
  --target-id ou-63sg-fcv70j2e \
  --filter SERVICE_CONTROL_POLICY \
  --output table
```

---

## 8. Commit

```bash
git add .
git commit -m "Phase 4: add initial organization guardrails"
```

Phase 4 starts with **Sandbox only** because that is how real platform teams work: test guardrails before enforcing them everywhere.

[1]: https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_policies_scps_examples.html?utm_source=chatgpt.com "Service control policy examples - AWS Organizations"
[2]: https://docs.aws.amazon.com/controltower/latest/userguide/region-deny.html?utm_source=chatgpt.com "Configure the Region deny control - AWS Control Tower"
