# Decision 002 — Organize AWS Accounts by Purpose

## Decision

We will organize AWS accounts by purpose using AWS Organizations and Organizational Units.

## Structure

- Security OU
- Infrastructure OU
- Workloads OU
- Sandbox OU
- Suspended OU

## Why

Each account should have a clear responsibility.

Security tools should not live inside application accounts.

Production should not be mixed with development.

Logs should be protected in a separate account.

## Benefits

- Stronger isolation
- Better security
- Cleaner billing
- Easier auditing
- Easier scaling
- Better production safety

## Tradeoff

More accounts means more setup work.

But this is how real cloud platforms are managed.
