#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

source "$SCRIPT_DIR/config.env"

echo "Deploying Atlas Landing Zone foundation..."
echo "Default region: $AWS_REGION"
echo "Primary region: $PRIMARY_REGION"
echo "DR region: $DR_REGION"

echo "Checking AWS Organizations..."

if aws organizations describe-organization >/dev/null 2>&1; then
  echo "AWS Organization already exists."
else
  echo "AWS Organization not found. Creating organization..."
  aws organizations create-organization --feature-set ALL
fi

ORGANIZATION_ID=$(aws organizations describe-organization \
  --query "Organization.Id" \
  --output text)

echo "Organization ID: $ORGANIZATION_ID"

echo "Creating OU structure..."
"$PROJECT_ROOT/infra/organizations/create-ou-structure.sh"

echo "Validating CloudTrail log bucket template..."
aws cloudformation validate-template \
  --template-body file://"$PROJECT_ROOT/infra/logging/cloudtrail-log-bucket.yaml" \
  --region "$AWS_REGION" >/dev/null

echo "Deploying CloudTrail log bucket..."
aws cloudformation deploy \
  --template-file "$PROJECT_ROOT/infra/logging/cloudtrail-log-bucket.yaml" \
  --stack-name "$CLOUDTRAIL_BUCKET_STACK_NAME" \
  --parameter-overrides \
    EnvironmentName="$PROJECT_NAME" \
    OrganizationId="$ORGANIZATION_ID" \
  --region "$AWS_REGION"

CLOUDTRAIL_BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name "$CLOUDTRAIL_BUCKET_STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='CloudTrailLogBucketName'].OutputValue" \
  --output text)

echo "CloudTrail bucket: $CLOUDTRAIL_BUCKET_NAME"

echo "Validating organization CloudTrail template..."
aws cloudformation validate-template \
  --template-body file://"$PROJECT_ROOT/infra/logging/organization-cloudtrail.yaml" \
  --region "$AWS_REGION" >/dev/null

echo "Ensuring CloudTrail trusted access is enabled..."
aws organizations enable-aws-service-access \
  --service-principal cloudtrail.amazonaws.com || true

TRAIL_STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$ORGANIZATION_TRAIL_STACK_NAME" \
  --region "$AWS_REGION" \
  --query "Stacks[0].StackStatus" \
  --output text 2>/dev/null || true)

if [ "$TRAIL_STACK_STATUS" = "ROLLBACK_COMPLETE" ]; then
  echo "Deleting failed CloudTrail stack before redeploy..."

  aws cloudformation delete-stack \
    --stack-name "$ORGANIZATION_TRAIL_STACK_NAME" \
    --region "$AWS_REGION"

  aws cloudformation wait stack-delete-complete \
    --stack-name "$ORGANIZATION_TRAIL_STACK_NAME" \
    --region "$AWS_REGION"
fi

echo "Deploying organization CloudTrail..."
aws cloudformation deploy \
  --template-file "$PROJECT_ROOT/infra/logging/organization-cloudtrail.yaml" \
  --stack-name "$ORGANIZATION_TRAIL_STACK_NAME" \
  --parameter-overrides \
    CloudTrailLogBucketName="$CLOUDTRAIL_BUCKET_NAME" \
  --region "$AWS_REGION"

echo "Checking CloudTrail status..."
aws cloudtrail get-trail-status \
  --name "$ORGANIZATION_TRAIL_NAME" \
  --region "$AWS_REGION"

echo "Validating reusable VPC template..."
aws cloudformation validate-template \
  --template-body file://"$PROJECT_ROOT/infra/network/vpc.yaml" \
  --region "$PRIMARY_REGION" >/dev/null

echo "Deploying Dev VPC in primary region..."
aws cloudformation deploy \
  --template-file "$PROJECT_ROOT/infra/network/vpc.yaml" \
  --stack-name "$DEV_VPC_STACK_NAME" \
  --parameter-overrides \
    EnvironmentName=dev \
    VPCCidr=10.10.0.0/16 \
    PublicSubnetACidr=10.10.1.0/24 \
    PublicSubnetBCidr=10.10.2.0/24 \
    PrivateAppSubnetACidr=10.10.11.0/24 \
    PrivateAppSubnetBCidr=10.10.12.0/24 \
    PrivateDataSubnetACidr=10.10.21.0/24 \
    PrivateDataSubnetBCidr=10.10.22.0/24 \
  --region "$PRIMARY_REGION"

  ###phase 6

  echo "Getting Dev VPC outputs..."

DEV_VPC_ID=$(aws cloudformation describe-stacks \
  --stack-name "$DEV_VPC_STACK_NAME" \
  --region "$PRIMARY_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue" \
  --output text)

DEV_PRIVATE_APP_SUBNET_A=$(aws cloudformation describe-stacks \
  --stack-name "$DEV_VPC_STACK_NAME" \
  --region "$PRIMARY_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='PrivateAppSubnetA'].OutputValue" \
  --output text)

DEV_PRIVATE_APP_SUBNET_B=$(aws cloudformation describe-stacks \
  --stack-name "$DEV_VPC_STACK_NAME" \
  --region "$PRIMARY_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='PrivateAppSubnetB'].OutputValue" \
  --output text)

echo "Dev VPC ID: $DEV_VPC_ID"
echo "Dev private app subnet A: $DEV_PRIVATE_APP_SUBNET_A"
echo "Dev private app subnet B: $DEV_PRIVATE_APP_SUBNET_B"

echo "Validating EKS template..."
aws cloudformation validate-template \
  --template-body file://"$PROJECT_ROOT/infra/eks/eks-cluster.yaml" \
  --region "$PRIMARY_REGION" >/dev/null

  EKS_STACK_STATUS=$(aws cloudformation describe-stacks \
  --stack-name "$DEV_EKS_STACK_NAME" \
  --region "$PRIMARY_REGION" \
  --query "Stacks[0].StackStatus" \
  --output text 2>/dev/null || true)

if [ "$EKS_STACK_STATUS" = "ROLLBACK_COMPLETE" ] || [ "$EKS_STACK_STATUS" = "REVIEW_IN_PROGRESS" ]; then
  echo "Deleting failed EKS stack before redeploy: $EKS_STACK_STATUS"

  aws cloudformation delete-stack \
    --stack-name "$DEV_EKS_STACK_NAME" \
    --region "$PRIMARY_REGION"

  aws cloudformation wait stack-delete-complete \
    --stack-name "$DEV_EKS_STACK_NAME" \
    --region "$PRIMARY_REGION"
fi

echo "Deploying Dev EKS cluster..."
aws cloudformation deploy \
  --template-file "$PROJECT_ROOT/infra/eks/eks-cluster.yaml" \
  --stack-name "$DEV_EKS_STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    EnvironmentName=dev \
    ClusterName="$DEV_EKS_CLUSTER_NAME" \
    VpcId="$DEV_VPC_ID" \
    PrivateSubnetA="$DEV_PRIVATE_APP_SUBNET_A" \
    PrivateSubnetB="$DEV_PRIVATE_APP_SUBNET_B" \
    KubernetesVersion="$KUBERNETES_VERSION" \
    NodeInstanceType=t3.medium \
    DesiredNodeCount=2 \
    MinNodeCount=1 \
    MaxNodeCount=3 \
  --region "$PRIMARY_REGION"


echo "Validating ECR template..."

aws cloudformation validate-template \
  --template-body file://"$PROJECT_ROOT/infra/ecr/ecr.yaml" \
  --region "$PRIMARY_REGION" >/dev/null
echo "Deploying Dev ECR repositories..."

aws cloudformation deploy \
  --template-file "$PROJECT_ROOT/infra/ecr/ecr.yaml" \
  --stack-name "$DEV_ECR_STACK_NAME" \
  --parameter-overrides \
    EnvironmentName=dev \
  --region "$PRIMARY_REGION"

DEV_API_ECR_URI=$(aws cloudformation describe-stacks \
  --stack-name "$DEV_ECR_STACK_NAME" \
  --region "$PRIMARY_REGION" \
  --query "Stacks[0].Outputs[?OutputKey=='AtlasApiRepositoryUri'].OutputValue" \
  --output text)

echo "Dev API ECR URI: $DEV_API_ECR_URI"

echo "Atlas Landing Zone foundation deployed successfully."
