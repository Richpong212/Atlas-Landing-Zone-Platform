#!/usr/bin/env bash
set -euo pipefail

echo "Applying Atlas Kubernetes bootstrap using Kustomize..."

kubectl apply -k deploy/bootstrap/overlays/dev

echo "Bootstrap applied successfully."

kubectl get namespaces
kubectl get limitrange -n dev
kubectl get resourcequota -n dev
kubectl get networkpolicy -n dev
