# Phase 2 — AWS Organizations and Account Structure

## Simple Explanation

AWS Organizations is like the school office.

It helps us manage many AWS accounts from one place.

Instead of putting everything into one AWS account, we create separate accounts for different jobs.

This makes the platform safer and cleaner.

## Our Organizational Units

An Organizational Unit, also called an OU, is like a group.

Accounts inside the same OU can share the same rules.

## OU Design

```text
AWS Organization
│
├── Security OU
│   ├── Log Archive Account
│   └── Audit Account
│
├── Infrastructure OU
│   └── Shared Services Account
│
├── Workloads OU
│   ├── Dev Account
│   ├── Staging Account
│   └── Prod Account
│
├── Sandbox OU
│   └── Experiment Account
│
└── Suspended OU
    └── Closed or disabled accounts
```

Account Purpose
Management Account

This is the main AWS account.

It controls the AWS Organization.

We do not run normal workloads here.

Log Archive Account

This account stores logs from all other accounts.

Logs should be protected because they help us investigate problems.

Audit Account

This account is used by security teams to review other accounts.

It helps us check if the platform is safe.

Shared Services Account

This account stores tools used by many environments.

Examples:

ECR repositories
CI/CD roles
Route 53
Monitoring tools
GitHub Actions OIDC roles
Dev Account

This is where developers test new changes.

It is allowed to be more flexible than production.

Staging Account

This is where we test before production.

It should look close to production.

Prod Account

This runs the real application.

It has the strongest rules.

Sandbox Account

This is for experiments.

It should have strong cost limits.

Suspended OU

This is where closed or unused accounts go.

Why This Matters

This structure protects production.

It also protects logs.

It makes cost tracking easier.

It gives each environment a clear job.
