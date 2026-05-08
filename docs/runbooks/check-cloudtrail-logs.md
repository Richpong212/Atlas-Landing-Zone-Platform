# Runbook — Check CloudTrail Logs

## Purpose

Use this runbook when we need to check AWS activity.

CloudTrail helps us see who changed what in AWS.

## When To Use

Use this when:

- A resource was deleted
- An IAM policy changed
- A user logged in unexpectedly
- A production issue happened
- We need to investigate suspicious activity

## Step 1 — Check Trail Status

```bash
aws cloudtrail get-trail-status \
  --name atlas-organization-trail
```

Step 2 — Check Recent Events
aws cloudtrail lookup-events \
 --max-results 10 \
 --output table
Step 3 — Find Events By Username
aws cloudtrail lookup-events \
 --lookup-attributes AttributeKey=Username,AttributeValue=<USERNAME> \
 --output table

Step 4 — Find Events By Resource

```yaml
aws cloudtrail lookup-events \
--lookup-attributes AttributeKey=ResourceName,AttributeValue=<RESOURCE_NAME> \
--output table
```

Step 5 — Explain The Finding

Answer these questions:

Who made the change?
What did they change?
When did it happen?
Which AWS service was affected?
Was this expected or suspicious?
