# Decision 005 — Use Reusable Multi-Region VPC Template

## Decision

We will use one reusable VPC template instead of creating separate templates for dev, staging, production, and disaster recovery.

## Why

A separate template for every environment creates duplication.

Duplication makes the platform harder to maintain.

A reusable template keeps the network design consistent.

## Current Deployment

For now, we deploy only the dev VPC in the primary region.

## Future Deployment

Later, we can reuse the same template for:

- Staging VPC
- Production primary VPC
- Production disaster recovery VPC

## Region Strategy

Primary region:
us-east-1

## Disaster recovery region:

eu-west-1

## Benefits

- Less duplicated code
- Easier maintenance
- Cleaner scaling
- Multi-region ready

# Tradeoff

The template needs more parameters.

But this is worth it because it makes the platform reusable.
