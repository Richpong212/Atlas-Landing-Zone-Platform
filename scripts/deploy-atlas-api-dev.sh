#!/usr/bin/env bash
set -euo pipefail

AWS_REGION="us-east-1"
AWS_ACCOUNT_ID="307946673392"
ECR_REPOSITORY="atlas-dev-api"
IMAGE_TAG="v1"

ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}"

echo "Logging into ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login \
  --username AWS \
  --password-stdin "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

echo "Building atlas-api image..."
docker build -t atlas-api:"$IMAGE_TAG" services/atlas-api

echo "Tagging image..."
docker tag atlas-api:"$IMAGE_TAG" "$ECR_URI:$IMAGE_TAG"

echo "Pushing image to ECR..."
docker push "$ECR_URI:$IMAGE_TAG"

echo "Updating Kustomize image..."
cd deploy/k8s/overlays/dev
kustomize edit set image atlas-api="$ECR_URI:$IMAGE_TAG"
cd ../../../..

echo "Applying Kubernetes manifests..."
kubectl apply -k deploy/k8s/overlays/dev

echo "Waiting for rollout..."
kubectl rollout status deployment/atlas-api -n dev

echo "Atlas API deployed successfully."
kubectl get pods -n dev
kubectl get svc -n dev
