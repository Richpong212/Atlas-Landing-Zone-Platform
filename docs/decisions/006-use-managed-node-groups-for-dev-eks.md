# Decision 006 — Use EKS Managed Node Groups for Dev

## Decision

We will use EKS managed node groups for the Dev cluster.

## Why

Managed node groups are easier to operate than self-managed worker nodes.

AWS manages the node group lifecycle.

This is a good starting point for the platform.

## Benefits

- Easier cluster setup
- Less operational overhead
- Good for learning and platform foundation
- Works well with future autoscaling

## Tradeoff

Managed node groups give less control than fully self-managed nodes.

For this project, the simplicity is worth it.

## Future

Later, we can add:

- Karpenter
- Spot nodes
- Separate system and application node groups
- Production-grade node hardening

## Step 2 — Check nodes

`kubectl get nodes`

## Step 3 — Check system pods

`kubectl get pods -n kube-system`

## Step 4 — Check cluster info

`kubectl cluster-info`

## Step 5 — Check node group from AWS

`aws eks list-nodegroups \
  --cluster-name atlas-dev-eks-cluster \
  --region us-east-1`
