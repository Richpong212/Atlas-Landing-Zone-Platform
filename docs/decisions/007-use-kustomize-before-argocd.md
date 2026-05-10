# Decision 007 — Use Kustomize Before ArgoCD

## Decision

We will use Kustomize for Kubernetes manifest management before introducing ArgoCD.

## Why

Kustomize gives us a clean structure for base and environment overlays.

ArgoCD should come after the manifests are stable.

## Benefits

- Cleaner Kubernetes structure
- Easier environment management
- Better GitOps foundation
- Less complexity too early

## Tradeoff

We still apply manifests manually for now.

This is acceptable because we are still building the platform foundation.

## Future

ArgoCD will be introduced after the first workload is deployed.
