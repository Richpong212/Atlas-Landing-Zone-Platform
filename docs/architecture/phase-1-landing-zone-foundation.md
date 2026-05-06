# Phase 1 — AWS Landing Zone Foundation

## Simple Explanation

An AWS Landing Zone is like building a safe city before people move in.

Instead of putting everything into one AWS account, we create different accounts for different jobs.

This keeps the platform clean, safe, and easier to manage.

## Why We Need It

If we put dev, staging, production, logs, and security all in one account, things can become messy.

A mistake in dev could affect production.

A developer could accidentally delete something important.

Logs could be changed or deleted.

Security becomes harder to control.

A landing zone fixes this by creating clear boundaries.

## Our Account Design

We will use multiple AWS accounts:

1. Management Account
   - Controls the AWS Organization
   - Used only for high-level administration

2. Security Account
   - Runs security tools
   - Monitors risky activity

3. Log Archive Account
   - Stores logs from all accounts
   - Keeps audit records safe

4. Shared Services Account
   - Stores shared tools
   - CI/CD roles
   - ECR repositories
   - DNS and platform tooling

5. Dev Account
   - Used for development workloads

6. Staging Account
   - Used for testing before production

7. Prod Account
   - Runs real production workloads

## Why Separate Accounts?

Separate accounts give us stronger isolation.

Dev problems stay in dev.

Production is protected.

Security logs are protected.

Costs are easier to track.

Access is easier to control.

## Environment Flow

Code starts in dev.

If it works, it moves to staging.

If staging is stable, it moves to production.

```text
Developer
   ↓
Dev Account
   ↓
Staging Account
   ↓
Prod Account
```
