# Phase 5 — Network Foundation

## Simple Explanation

A VPC is like our private land inside AWS.

Inside that land, we create different areas.

Some areas can talk to the internet.

Some areas stay private.

This helps us keep important systems safe.

## What We Built

We created one reusable VPC template.

This template can be used for:

- Dev
- Staging
- Production
- Disaster recovery region

## Public Subnets

Public subnets are places where internet-facing resources can live.

Example:

- Load balancer
- NAT Gateway

Public subnets can reach the internet directly.

## Private App Subnets

Private app subnets are where our application servers will run.

Example:

- EKS worker nodes
- Backend services
- Internal APIs

These resources should not be directly exposed to the internet.

## Private Data Subnets

Private data subnets are where databases will live.

Example:

- RDS
- Cache
- Internal data services

These should be the most protected network areas.

## NAT Gateway

A NAT Gateway lets private app resources reach the internet for updates or package downloads.

But the internet cannot directly reach those private resources.

## Multi-AZ Design

We create subnets in two Availability Zones.

This means if one data center area has a problem, the other one can still work.

## Multi-Region Ready Design

Right now, we only deploy the dev VPC in the primary region.

But the same template can later deploy:

- Prod in the primary region
- Prod disaster recovery in a second region

## Current Region Plan

Primary Region:
us-east-1
Disaster Recovery Region:
eu-west-1
