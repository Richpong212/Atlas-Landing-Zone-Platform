cat > infra/main/destroy.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.env"

echo "Destroying Atlas Landing Zone foundation..."
echo "Region: $AWS_REGION"

echo "Deleting organization CloudTrail stack..."
aws cloudformation delete-stack \
  --stack-name "$ORGANIZATION_TRAIL_STACK_NAME" \
  --region "$AWS_REGION" || true

aws cloudformation wait stack-delete-complete \
  --stack-name "$ORGANIZATION_TRAIL_STACK_NAME" \
  --region "$AWS_REGION" || true

echo "Emptying CloudTrail S3 bucket..."

CLOUDTRAIL_BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$CLOUDTRAIL_BUCKET_STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudTrailLogBucketName'].OutputValue" \
  --output text 2>/dev/null || true)

if [ -n "$CLOUDTRAIL_BUCKET_NAME" ]; then
  aws s3 rm "s3://$CLOUDTRAIL_BUCKET_NAME" --recursive || true
fi

echo "Deleting Dev VPC stack..."
aws cloudformation delete-stack \
  --stack-name "$DEV_VPC_STACK_NAME" \
  --region "$PRIMARY_REGION" || true

aws cloudformation wait stack-delete-complete \
  --stack-name "$DEV_VPC_STACK_NAME" \
  --region "$PRIMARY_REGION" || true

echo "Deleting CloudTrail log bucket stack..."
aws cloudformation delete-stack \
  --stack-name "$CLOUDTRAIL_BUCKET_STACK_NAME" \
  --region "$AWS_REGION" || true

aws cloudformation wait stack-delete-complete \
  --stack-name "$CLOUDTRAIL_BUCKET_STACK_NAME" \
  --region "$AWS_REGION" || true

echo "Destroy complete."

echo "Note: AWS Organization and OUs are not deleted by this script."
echo "We keep them safe because deleting/moving organization structure should be manual."
EOF