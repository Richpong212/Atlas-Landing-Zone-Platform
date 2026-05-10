# Phase 7 — Kubernetes Bootstrap with Kustomize

## Simple Explanation

Kubernetes needs structure before applications are deployed.

Kustomize helps us organize Kubernetes YAML files.

Instead of copying the same YAML many times, we create a base and then customize it for each environment.

## What We Built

We created a bootstrap structure using Kustomize.

The base contains shared resources.

The dev overlay contains dev-specific rules.

## Base

The base creates shared namespaces:

- dev
- platform
- observability

## Dev Overlay

The dev overlay adds:

- CPU and memory defaults
- Resource quotas
- Default deny ingress network policy
- DNS egress network policy

## Why We Use Kustomize

Kustomize lets us reuse Kubernetes manifests.

This is better than copying files for every environment.

Later, we can add:

- staging overlay
- prod overlay
- prod-dr overlay

## Why Not ArgoCD Yet

ArgoCD is a GitOps tool.

It watches Git and applies Kubernetes changes automatically.

We will add ArgoCD later after we have:

- bootstrap structure
- first workload
- stable manifests

This is cleaner because ArgoCD should manage something meaningful.

## Interview Explanation

I introduced Kustomize first to organize Kubernetes resources into base and environment overlays.

I delayed ArgoCD until the platform had stable manifests and workloads to sync.

This keeps the platform simple at first, but ready for GitOps.
