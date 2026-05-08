# Phase 3 — Security and Logging Foundation

## Simple Explanation

Security and logging are like cameras and security guards for our AWS platform.

If something bad happens, logs help us answer:

- Who did it?
- What did they change?
- When did it happen?
- Which account was affected?

Without logs, we are blind.

## What We Are Building

In this phase, we prepare the security and logging foundation.

We want all AWS accounts to send important activity logs to one safe place.

That safe place is called the Log Archive account.

## Main Security Accounts

### Log Archive Account

This account stores logs from all AWS accounts.

It should be protected.

Normal developers should not be able to delete or change logs.

### Audit Account

This account is used to check security across the organization.

Security tools can run here.

## Services We Will Use

### AWS CloudTrail

CloudTrail records AWS API activity.

Example:

- Someone created an EC2 instance
- Someone deleted an S3 bucket
- Someone changed an IAM policy
- Someone logged into the AWS console

### Amazon GuardDuty

GuardDuty looks for suspicious activity.

Example:

- Strange login behavior
- Possible compromised credentials
- Suspicious network activity

### AWS Security Hub

Security Hub gives us one place to see security findings.

### AWS Config

AWS Config checks if resources follow rules.

Example:

- Is S3 public?
- Is encryption enabled?
- Is CloudTrail enabled?

### IAM Access Analyzer

IAM Access Analyzer helps us find risky access.

Example:

- A bucket shared with the public
- A role trusted by an external account

## Why This Matters

Before we create EKS, databases, and applications, we need visibility.

A real platform must be observable and auditable from the beginning.

Security should not be added at the end.
