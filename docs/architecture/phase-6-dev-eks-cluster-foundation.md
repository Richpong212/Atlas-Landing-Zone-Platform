# Phase 6 — Dev EKS Cluster Foundation

## Simple Explanation

EKS is AWS Kubernetes.

Kubernetes helps us run containers.

Instead of running our app directly on one server, we run it inside a cluster.

A cluster is a group of machines working together.

## What We Built

We created a Dev EKS cluster.

This cluster runs inside our Dev VPC.

The worker nodes run inside private app subnets.

That means the nodes are not directly exposed to the internet.

## Main Parts

### EKS Cluster

The EKS cluster is the control center.

It manages Kubernetes.

It decides where pods should run.

### Managed Node Group

The managed node group creates the worker machines.

These machines run our application pods.

AWS helps manage the node group for us.

### Cluster IAM Role

The cluster IAM role allows EKS to manage AWS resources needed by the cluster.

### Node IAM Role

The node IAM role allows worker nodes to talk to AWS services.

For example, nodes need to pull container images from ECR.

### Private Subnets

Worker nodes are deployed into private app subnets.

This keeps them safer because they are not directly open to the internet.

## Why This Matters

This is the start of the platform runtime.

Before this phase, we had the land and network.

Now we have a place to run real applications.

## Multi-Region Thinking

Right now, we deploy Dev EKS only in the primary region.

Later, the same EKS template can be used for:

- Staging cluster
- Prod primary cluster
- Prod disaster recovery cluster
