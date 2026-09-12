# Salesforce + GitHub Actions CI/CD Setup Guide

> **Purpose:** This document is a complete reference for setting up the
> Salesforce CI/CD pipeline we built for the Salesforce LWC Book Store
> project.
>
> It covers both the **Salesforce-side setup** and the **GitHub-side
> setup**, including JWT authentication, External Client App
> configuration, GitHub Secrets, GitHub Actions, pull-request
> validation, branch protection, troubleshooting, and the experiments we
> performed to verify the pipeline.

------------------------------------------------------------------------

## 1. Final Architecture

### 1.1 Branching strategy

The project uses this branching model:

``` text
                    ┌──────────────┐
                    │     master   │
                    │  production  │
                    └──────▲───────┘
                           │
                     Pull Request
                           │
                    ┌──────┴───────┐
                    │   developer  │
                    │ stable/dev   │
                    └──────▲───────┘
                           │
                    Pull Request
                           │
              ┌────────────┴────────────┐
              │                         │
       feature/book-store       feature/another-feature
```

The intended development flow is:

``` text
Create feature branch
        ↓
Develop + test locally
        ↓
Push feature branch
        ↓
Create PR → Developer_Branch
        ↓
GitHub Actions CI
        ↓
Salesforce validation + Apex tests
        ↓
     ┌───┴───┐
     │       │
   FAIL     PASS
     │       │
     ↓       ↓
Merge      Merge
blocked    allowed
```

------------------------------------------------------------------------

## 2. CI/CD Overview

We initially implemented **Continuous Integration (CI)** and later extended the same setup with **Continuous Delivery/Deployment (CD)**. The current learning pipeline uses the `Developer_Branch` as the automatic deployment branch.

### CI

Every pull request targeting `Developer_Branch` runs:

-   Checkout repository
-   Install Salesforce CLI
-   Authenticate to Salesforce using JWT
-   Validate Salesforce metadata
-   Run local Apex tests
-   Check deployment/coverage requirements
-   Report success/failure back to GitHub

No actual Salesforce deployment happens because we use:

``` bash
--dry-run
```

### CD

After a feature PR is successfully validated and merged into `Developer_Branch`, the merge creates a push to `Developer_Branch`, which triggers the CD workflow.

The CD workflow performs: 

- Checkout repository
- Install Salesforce CLI
- Authenticate to Salesforce using JWT
- Validate the deployment with `--dry-run`
- Run `RunLocalTests`
- If validation succeeds, perform the actual deployment
- If validation fails, stop the workflow and do not execute the deployment step

Current CD flow:

``` text
Developer_Branch
       ↓
      push
       ↓
   CD workflow
       ↓
JWT authentication
       ↓
Deployment validation
       ↓
RunLocalTests
       ↓
   ┌────┴────┐
   │         │
 FAIL      PASS
   │         │
   ↓         ↓
 STOP     Deploy
           ↓
      Salesforce Org
```

The first CD target in this learning setup is the same Developer Edition Salesforce org. Production deployment is intentionally left for a later stage.

------------------------------------------------------------------------

# 3. Complete CI/CD Architecture

``` text
┌──────────────────────────────────────────────────────────┐
│                       Developer                          │
│                                                          │
│  VS Code                                                 │
│    │                                                     │
│    ├── Salesforce source                                 │
│    ├── Apex classes/tests                                │
│    └── LWC                                               │
└─────────────────────────┬────────────────────────────────┘
                          │
                          │ git push
                          ▼
┌──────────────────────────────────────────────────────────┐
│                         GitHub                           │
│                                                          │
│  feature/*                                               │
│       │                                                  │
│       │ Pull Request                                     │
│       ▼                                                  │
│  developer                                               │
│       │                                                  │
│       └── GitHub Actions                                 │
│              │                                           │
│              ├── Checkout                                │
│              ├── Install Salesforce CLI                  │
│              ├── JWT authentication                      │
│              ├── Metadata validation                     │
│              └── Apex tests                              │
└─────────────────────────┬────────────────────────────────┘
                          │
                          │ JWT
                          ▼
┌──────────────────────────────────────────────────────────┐
│                     Salesforce                           │
│                                                          │
│  External Client App                                     │
│       │                                                  │
│       ├── Consumer Key                                   │
│       ├── JWT Bearer Flow                                │
│       ├── server.crt                                     │
│       └── Admin-approved users                           │
│                    │                                     │
│                    ▼                                     │
│               CI/CD Salesforce User                         │
│                    │                                     │
│                    ▼                                     │
│          Metadata API / Deployment                       │
└──────────────────────────────────────────────────────────┘
```

------------------------------------------------------------------------

# 4. Authentication Architecture

The most important security concept is that the private key never goes
into Salesforce or GitHub source code.

``` text
                     JWT Authentication

             GitHub Actions Runner
                     │
                     │ server.key
                     │ (PRIVATE)
                     ▼
              Create/sign JWT
                     │
                     ▼
            Salesforce OAuth endpoint
                     │
                     ▼
           External Client App
                     │
                     │ server.crt
                     │ (PUBLIC certificate)
                     ▼
             Verify JWT signature
                     │
                     ▼
                CI/CD User
                     │
                     ▼
             Salesforce access
```

### Key responsibilities

  -----------------------------------------------------------------------
  Item                    Location                Purpose
  ----------------------- ----------------------- -----------------------
  `server.key`            GitHub Secret           Private key used to
                                                  sign JWT

  `server.crt`            Salesforce External     Public certificate used
                          Client App              to verify JWT

  Consumer Key            GitHub Secret           Identifies External
                                                  Client App

  CI username             GitHub Secret           Identifies Salesforce
                                                  user

  Consumer Secret         Not required for this   Do not use it in the
                          JWT CLI flow            JWT command
  -----------------------------------------------------------------------

------------------------------------------------------------------------

# 5. Prerequisites

Before starting:

-   Salesforce Developer Edition / suitable Salesforce org
-   Salesforce CLI (`sf`)
-   VS Code + Salesforce extensions
-   Git
-   GitHub repository
-   Salesforce project using standard Salesforce DX structure
-   A dedicated Salesforce CI/CD user
-   OpenSSL available locally

Typical Salesforce DX structure:

``` text
salesforce-ci/
├── .github/
│   └── workflows/
│       └── salesforce-cicd.yml
├── force-app/
│   └── main/
│       └── default/
├── manifest/
├── sfdx-project.json
└── ...
```

Do **not** put private authentication files inside the repository.

------------------------------------------------------------------------

# 6. Step 1 --- Create a Dedicated Salesforce CI/CD User

Do not use your normal personal Salesforce user for CI/CD.

Go to:

**Setup → Users → Users → New User**

For a learning Developer Edition setup, a System Administrator profile
can be used initially to reduce permission troubleshooting.

Example:

``` text
First Name: CI/CD
Last Name: GitHub
Username: <unique Salesforce username>
```

For production/enterprise usage, replace broad System Administrator
access with least-privilege permissions.

### Why use a separate user?

``` text
Developer account
      ↓
Human development

CI Salesforce user
      ↓
GitHub Actions
```

If your personal account changes, CI should not break.

------------------------------------------------------------------------

# 7. Step 2 --- Generate JWT Certificate and Private Key

Create a directory outside the Salesforce repository:

``` powershell
mkdir salesforce-ci
cd salesforce-ci
```

Generate private key:

``` powershell
openssl genrsa -out server.key 2048
```

Generate certificate:

``` powershell
openssl req -new -x509 -key server.key -sha256 -days 3650 -out server.crt
```

You should have:

``` text
salesforce-ci/
├── server.key
└── server.crt
```

### Security warning

`server.key` is PRIVATE.

Never:

``` text
❌ commit it to Git
❌ push it to GitHub as a repository file
❌ put it in force-app
❌ publish it in documentation
❌ paste the actual key into chat
```

Only the contents of the private key are eventually stored as a GitHub
Actions Secret.

The certificate `server.crt` is the public certificate and is uploaded
to Salesforce.

A useful `.gitignore` safety rule is:

``` gitignore
*.key
*.crt
salesforce-ci/
```

If your certificate is intentionally tracked as part of a controlled
deployment strategy, adjust this carefully. The important rule is:
**never commit the private key.**

------------------------------------------------------------------------

# 8. Step 3 --- Create Salesforce External Client App

Go to:

**Setup → External Client Apps → External Client App Manager**

Create a new External Client App.

Example:

``` text
External Client App Name:
GitHub CI/CD

API Name:
GitHub_CICD
```

Enable OAuth.

------------------------------------------------------------------------

## 8.1 Callback URL

For the configuration used in this learning setup:

``` text
https://login.salesforce.com
```

------------------------------------------------------------------------

## 8.2 OAuth Scope

Initially the API scope was selected:

``` text
Manage user data via APIs (api)
```

During the first JWT login attempt, Salesforce returned:

``` text
refresh_token scope is required
```

Therefore we added:

``` text
Perform requests at any time
(refresh_token, offline_access)
```

Final relevant scopes:

``` text
✅ Manage user data via APIs (api)
✅ Perform requests at any time (refresh_token, offline_access)
```

This was an important troubleshooting step.

------------------------------------------------------------------------

## 8.3 Enable JWT Bearer Flow

In the External Client App's Flow Enablement section:

``` text
Enable JWT Bearer Flow
```

must be enabled.

Do not confuse this with:

``` text
Issue JSON Web Token (JWT)-based access tokens for named users
```

Those are different features.

For our Salesforce CLI JWT authentication, the important flow is:

``` text
JWT Bearer Flow
```

------------------------------------------------------------------------

## 8.4 Upload certificate

Upload:

``` text
server.crt
```

Do NOT upload:

``` text
server.key
```

Salesforce needs the public certificate to verify JWT signatures.

------------------------------------------------------------------------

# 9. Step 4 --- Configure External Client App Policies

Open:

**External Client App Manager → GitHub CI/CD → Policies**

Set:

``` text
Permitted Users:
Admin approved users are pre-authorized
```

This prevents arbitrary users from self-authorizing the application.

------------------------------------------------------------------------

# 10. Step 5 --- Create Permission Set for ECA Access

Create:

**Setup → Permission Sets → New**

Example:

``` text
Label:
GitHub CI/CD Access

API Name:
GitHub_CICD_Access
```

Assign this permission set to the dedicated CI Salesforce user.

Then configure the External Client App policy so that this permission
set is authorized to use the app.

Conceptually:

``` text
GitHub CI Permission Set
          │
          ▼
      CI/CD User
          │
          ▼
External Client App
          │
          ▼
JWT authentication
```

------------------------------------------------------------------------

# 11. Step 6 --- Retrieve Consumer Key

Go to:

**External Client App Manager → GitHub CI/CD → Settings → OAuth Settings**

Retrieve the:

``` text
Consumer Key
```

The Consumer Key is the OAuth Client ID used by Salesforce CLI.

Do not put the actual value in source code.

The Consumer Secret is not required for the JWT command we use.

------------------------------------------------------------------------

# 12. Step 7 --- Test JWT Authentication Locally

This step is extremely important.

Before involving GitHub Actions, prove that Salesforce JWT
authentication works locally.

Example PowerShell command:

``` powershell
sf org login jwt `
  --username "YOUR_CI_USERNAME" `
  --client-id "YOUR_CONSUMER_KEY" `
  --jwt-key-file "C:\path\to\server.key" `
  --instance-url "https://login.salesforce.com" `
  --alias github-cicd-test
```

Successful output should look similar to:

``` text
Successfully authorized <CI username> with org ID <ORG_ID>
```

Then verify:

``` powershell
sf org display --target-org github-cicd-test
```

### Why test locally first?

This isolates Salesforce authentication from GitHub Actions.

If it fails locally, fix Salesforce authentication first.

If it works locally but fails in GitHub, investigate GitHub
Secrets/workflow handling.

------------------------------------------------------------------------

# 13. Step 8 --- GitHub Actions Secrets

Go to your GitHub repository:

**Settings → Secrets and variables → Actions → New repository secret**

Create these three secrets:

------------------------------------------------------------------------

## `SF_USERNAME`

Value:

``` text
<CI Salesforce username>
```

------------------------------------------------------------------------

## `SF_CLIENT_ID`

Value:

``` text
<External Client App Consumer Key>
```

------------------------------------------------------------------------

## `SF_JWT_KEY`

Value:

The complete contents of `server.key`:

``` text
-----BEGIN PRIVATE KEY-----
...
...
-----END PRIVATE KEY-----
```

Do not store the private key as a normal repository file.

------------------------------------------------------------------------

## Secrets summary

``` text
GitHub Repository
└── Settings
    └── Secrets and variables
        └── Actions
            ├── SF_USERNAME
            ├── SF_CLIENT_ID
            └── SF_JWT_KEY
```

We do not need:

``` text
SF_CLIENT_SECRET
```

for this JWT CLI authentication setup.

------------------------------------------------------------------------

# 14. Step 9 --- Create GitHub Actions Workflow

Create the workflow in VS Code, not manually in the GitHub website.

Path:

``` text
.github/workflows/salesforce-ci.yml
```

Example workflow used for this project:

``` yaml
name: Salesforce CI

on:
  pull_request:
    branches:
      - developer

jobs:
  validate:
    name: Validate Salesforce Changes
    runs-on: ubuntu-latest

    steps:

      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: |
          npm install --global @salesforce/cli
          sf --version

      - name: Authenticate to Salesforce
        env:
          SF_USERNAME: ${{ secrets.SF_USERNAME }}
          SF_CLIENT_ID: ${{ secrets.SF_CLIENT_ID }}
          SF_JWT_KEY: ${{ secrets.SF_JWT_KEY }}
        run: |
          printf '%s' "$SF_JWT_KEY" > server.key

          sf org login jwt \
            --username "$SF_USERNAME" \
            --client-id "$SF_CLIENT_ID" \
            --jwt-key-file server.key \
            --instance-url https://login.salesforce.com \
            --alias ci-org

          rm -f server.key

      - name: Validate deployment
        run: |
          sf project deploy start \
            --source-dir force-app \
            --target-org ci-org \
            --dry-run \
            --test-level RunLocalTests \
            --wait 30
```

------------------------------------------------------------------------

# 15. CD Workflow

The CD workflow is stored separately from the PR-validation workflow:

``` text
.github/workflows/salesforce-cd.yml
```

It triggers when code is pushed to `Developer_Branch`. In this setup, a successful merge into `Developer_Branch` creates that push.

Current workflow:

``` yaml
name: Salesforce CD

on:
  push:
    branches:
      - Developer_Branch

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Install Salesforce CLI
        run: |
          npm install --global @salesforce/cli

      - name: Authenticate to Salesforce
        run: |
          echo "${{ secrets.SF_JWT_KEY }}" > server.key
          chmod 600 server.key

          sf org login jwt \
            --username "${{ secrets.SF_USERNAME }}" \
            --client-id "${{ secrets.SF_CLIENT_ID }}" \
            --jwt-key-file server.key \
            --instance-url "https://login.salesforce.com" \
            --alias cd-org

      - name: Validate deployment
        run: |
          sf project deploy start \
            --source-dir force-app \
            --target-org cd-org \
            --dry-run \
            --test-level RunLocalTests \
            --wait 30

      - name: Deploy to Salesforce
        run: |
          sf project deploy start \
            --source-dir force-app \
            --target-org cd-org \
            --test-level RunLocalTests \
            --wait 30
```

### Why the CD workflow is safe

GitHub Actions runs steps sequentially. If the validation command fails, the job fails at that step and the actual deployment step is not executed.

``` text
Validation with --dry-run
          ↓
      RunLocalTests
          ↓
     PASS → Deploy
     FAIL → Stop
```

The same three GitHub Secrets used by CI are reused by CD:

``` text
SF_USERNAME
SF_CLIENT_ID
SF_JWT_KEY
```

No separate Salesforce authentication mechanism is required for the first CD implementation.

------------------------------------------------------------------------

# 16. What Each Workflow Step Does

## Checkout

``` yaml
uses: actions/checkout@v4
```

Downloads the repository contents into the GitHub runner.

------------------------------------------------------------------------

## Install Salesforce CLI

``` bash
npm install --global @salesforce/cli
```

Installs the Salesforce CLI required for authentication and deployment
validation.

------------------------------------------------------------------------

## Recreate private key temporarily

``` bash
printf '%s' "$SF_JWT_KEY" > server.key
```

GitHub Secret:

``` text
SF_JWT_KEY
```

is temporarily converted into:

``` text
server.key
```

inside the GitHub runner.

------------------------------------------------------------------------

## JWT authentication

``` bash
sf org login jwt
```

Authenticates without browser interaction.

------------------------------------------------------------------------

## Remove private key

``` bash
rm -f server.key
```

The temporary key is removed from the runner after authentication.

------------------------------------------------------------------------

## Validate deployment

``` bash
sf project deploy start \
  --source-dir force-app \
  --target-org ci-org \
  --dry-run \
  --test-level RunLocalTests \
  --wait 30
```

`--dry-run` means:

> Validate the deployment but do not actually deploy the metadata.

`RunLocalTests` runs local Apex tests during validation.

------------------------------------------------------------------------

# 17. Step 10 --- Commit Workflow to Feature Branch

The workflow itself should be version controlled.

From VS Code:

``` bash
git add .github/workflows/salesforce-ci.yml
git commit -m "Add Salesforce CI workflow"
git push origin feature/book-store
```

The repository should contain:

``` text
salesforce-ci/
├── .github/
│   └── workflows/
│       └── salesforce-cicd.yml
├── force-app/
├── manifest/
├── sfdx-project.json
└── ...
```

------------------------------------------------------------------------

# 18. Step 11 --- Create Pull Request

Create:

``` text
feature/book-store
        ↓
developer
```

Because the workflow contains:

``` yaml
on:
  pull_request:
    branches:
      - developer
```

the workflow runs automatically for PRs targeting `Developer_Branch`.

------------------------------------------------------------------------

# 19. First CI Failure We Encountered

The first successful infrastructure run initially failed because overall
Apex coverage was below Salesforce's required deployment threshold.

The important result was:

``` text
Metadata deployment: 30/30
Apex tests: 28/28 passed
Overall coverage: 66%
Required: 75%
```

Therefore:

``` text
Authentication       ✅
Metadata validation  ✅
Tests                ✅
Coverage             ❌
```

This proved that the CI pipeline itself was working.

### Important lesson

A single class having good coverage does not necessarily mean the entire
deployment satisfies Salesforce's coverage requirement.

For example:

``` text
BookController       81%
Other Apex classes   lower coverage
-----------------------------
Overall              66%
```

The deployment gate evaluates the relevant Salesforce deployment/test
requirements, not just the one feature's test class.

------------------------------------------------------------------------

# 20. Do Not Disable Tests Just to Make CI Green

Do NOT change the workflow to:

``` text
NoTestRun
```

just to make the check pass.

The purpose of CI is to catch problems.

The better solution is to:

``` text
Improve test coverage
        ↓
Run CI again
        ↓
Pass legitimate Salesforce quality gate
```

------------------------------------------------------------------------

# 21. Step 12 --- GitHub Branch Protection / Ruleset

CI failing is not enough if GitHub still lets someone merge.

We therefore configured branch protection/ruleset for the `Developer_Branch`
branch.

Go to:

**Repository → Settings → Rules → Rulesets**

Create a branch ruleset.

Example:

``` text
Name:
Protect developer
```

Target:

``` text
developer
```

------------------------------------------------------------------------

## Recommended rules

### Require pull request

Enable:

``` text
Require a pull request before merging
```

This prevents normal direct changes to `Developer_Branch`.

------------------------------------------------------------------------

### Require status checks

Enable:

``` text
Require status checks to pass before merging
```

Select:

``` text
Validate Salesforce Changes
```

This is the job name from:

``` yaml
jobs:
  validate:
    name: Validate Salesforce Changes
```

GitHub may display the full check as:

``` text
Salesforce CI / Validate Salesforce Changes (pull_request)
```

Make this check required.

------------------------------------------------------------------------

### Require branch to be up to date

Enable:

``` text
Require branches to be up to date before merging
```

This ensures the feature branch is validated against the current target
branch before merging.

------------------------------------------------------------------------

### Prevent bypassing

Enable the option that prevents bypassing the above rules where
appropriate.

This is particularly useful for a learning exercise because it lets you
prove that even an administrator cannot casually merge a failing PR when
the rule is configured to block bypass.

------------------------------------------------------------------------

# 22. Final PR Security Flow

After branch protection:

``` text
feature/book-store
        │
        │ Pull Request
        ▼
     developer
        │
        ▼
┌─────────────────────────────┐
│       GitHub Actions        │
│                             │
│ Checkout                    │
│ JWT authentication          │
│ Salesforce validation       │
│ RunLocalTests               │
│ Coverage/deployment checks  │
└──────────────┬──────────────┘
               │
          ┌────┴────┐
          │         │
       SUCCESS    FAILURE
          │         │
          ▼         ▼
       Required   Required
       check ✅   check ❌
          │         │
          ▼         ▼
      Merge OK   Merge BLOCKED
```

------------------------------------------------------------------------

# 23. Intentional Failure Test

To prove branch protection actually works, we intentionally broke a
test.

Example:

``` apex
System.assertEquals(
    'THIS_SHOULD_FAIL',
    result,
    'Intentional CI failure'
);
```

Then:

``` bash
git add .
git commit -m "Test CI branch protection"
git push origin feature/book-store
```

GitHub Actions correctly reported:

``` text
Deploying Metadata       42/42 (100%)
Running Tests
Successful: 37
Failed: 1

BookControllerTest.testSearchBooks_success
Assertion Failed: Intentional CI failure

Status: Failed
Error: Process completed with exit code 1
```

This proved:

``` text
Code compilation          ✅
Metadata validation       ✅
Tests executed            ✅
One test failed           ❌
GitHub CI                 ❌
```

And because the CI check is required:

``` text
CI failure
    ↓
Required check failed
    ↓
Merge blocked
```

------------------------------------------------------------------------

# 24. Restore the Test

After confirming the branch protection behavior, restore the original
passing assertion.

Then:

``` bash
git add .
git commit -m "Restore passing test"
git push origin feature/book-store
```

GitHub Actions runs again.

Expected:

``` text
Salesforce CI
     ↓
Tests pass
     ↓
Coverage passes
     ↓
Required check ✅
     ↓
Merge allowed
```

------------------------------------------------------------------------

# 25. Why CI Was Fast in This Project

The first successful pipeline completed in roughly 49 seconds.

This is normal for a small Salesforce project.

An enterprise Salesforce CI pipeline can take significantly longer
because it may contain:

``` text
Large metadata repository
Hundreds/thousands of Apex tests
Static analysis
PMD
SonarQube
Security scanning
Dependency checks
Packages
Multiple validation jobs
Multiple Salesforce environments
Deployment orchestration
```

Our current pipeline intentionally does only:

``` text
Checkout
 ↓
Salesforce CLI
 ↓
JWT authentication
 ↓
Metadata validation
 ↓
Apex tests
```

------------------------------------------------------------------------

# 26. Security Checklist

## Salesforce

``` text
☑ Dedicated CI user
☑ External Client App
☑ JWT Bearer Flow enabled
☑ server.crt uploaded
☑ Admin-approved users
☑ CI permission set
☑ CI user assigned permission set
☑ API OAuth scope
☑ refresh_token/offline_access scope
```

## Local machine

``` text
☑ server.key generated
☑ server.key kept outside repository
☑ JWT authentication tested locally
```

## GitHub

``` text
☑ SF_USERNAME secret
☑ SF_CLIENT_ID secret
☑ SF_JWT_KEY secret
☑ Workflow stored in .github/workflows/
☑ PR trigger configured
☑ Developer_Branch protected
☑ Salesforce CI required
☑ Direct merge blocked when CI fails
```

------------------------------------------------------------------------

# 27. Things That Must Never Be Committed

Never commit:

``` text
server.key
```

Never commit:

``` text
Consumer Secret
```

Never hardcode:

``` text
Consumer Key
Salesforce password
Security token
JWT private key
API keys
```

Use:

``` text
GitHub Secrets
Salesforce Named Credentials
External Credentials
Environment variables
```

depending on the use case.

------------------------------------------------------------------------

# 28. Troubleshooting

## Error: `refresh_token scope is required`

If JWT login returns:

``` text
refresh_token scope is required
```

go to the External Client App OAuth scopes and add:

``` text
Perform requests at any time
(refresh_token, offline_access)
```

Then save and retry.

------------------------------------------------------------------------

## Error: `External client app is not installed in this org`

This can appear together with OAuth authorization errors in the newer
External Client App model.

First verify:

``` text
External Client App enabled
JWT Bearer Flow enabled
Certificate uploaded
Admin-approved users configured
CI permission set assigned
Required OAuth scopes configured
```

If the error persists after those checks, investigate the External
Client App installation/authorization state for the specific org rather
than changing the JWT key.

------------------------------------------------------------------------

## JWT authentication fails

Check:

``` text
Username = CI Salesforce user
Consumer Key = correct External Client App
server.key = matching private key
server.crt = certificate generated from matching key
Instance URL = correct Salesforce login URL
```

The public/private key pair must match.

------------------------------------------------------------------------

## GitHub authentication fails but local authentication works

Check:

``` text
SF_USERNAME
SF_CLIENT_ID
SF_JWT_KEY
```

especially the formatting of `SF_JWT_KEY`.

The secret must contain the complete key:

``` text
-----BEGIN PRIVATE KEY-----
...
-----END PRIVATE KEY-----
```

------------------------------------------------------------------------

## Tests pass but validation fails because of coverage

Check overall Apex coverage and existing test classes.

Do not automatically switch to `NoTestRun`.

------------------------------------------------------------------------

## CI passes but PR can still merge when it shouldn't

Check:

``` text
Repository
 → Settings
 → Rules
 → Rulesets
```

Verify:

``` text
☑ Developer_Branch is targeted
☑ Require pull request
☑ Require status checks
☑ Validate Salesforce Changes is selected
☑ Branch must be up to date
☑ Bypass behavior is configured as intended
```

------------------------------------------------------------------------

# 29. Current Workflow vs Future Production Workflow

## Current

``` text
feature/*
    ↓
PR → Developer_Branch
    ↓
GitHub Actions
    ↓
JWT
    ↓
Dry-run Salesforce deployment
    ↓
RunLocalTests
    ↓
Required check
    ↓
Merge
```

## Future

We can evolve this into:

``` text
feature/*
    ↓
PR → Developer_Branch
    ↓
CI validation
    ├── Salesforce metadata validation
    ├── Apex tests
    ├── Code quality
    └── Security checks
    ↓
Merge
    ↓
developer
    ↓
Deployment to Dev/UAT
    ↓
Validation
    ↓
PR → master
    ↓
Production approval
    ↓
Production deployment
```

------------------------------------------------------------------------

# 30. Recommended Future Improvements

Do these later rather than making the first pipeline unnecessarily
complicated.

### Level 1 --- Current

``` text
PR
 ↓
Salesforce validation
 ↓
Apex tests
```

### Level 2

Add:

``` text
Changed metadata detection
Better test selection
PMD/static analysis
Code quality checks
```

### Level 3

Add:

``` text
Automatic deployment to Developer/UAT
```

### Level 4

Add:

``` text
developer → master
Production approval
Production deployment
Rollback strategy
```

### Level 5

Add enterprise-grade features:

``` text
Scratch org strategy
Unlocked packages
Environment-specific secrets
Deployment manifests
Release tagging
Security scanning
Audit/reporting
```

------------------------------------------------------------------------

# 31. Quick Setup Checklist

When setting this up again from scratch:

``` text
[ ] Create Salesforce CI user
[ ] Generate server.key
[ ] Generate server.crt
[ ] Create External Client App
[ ] Enable OAuth
[ ] Configure callback URL
[ ] Add api scope
[ ] Add refresh_token/offline_access scope
[ ] Enable JWT Bearer Flow
[ ] Upload server.crt
[ ] Set Admin approved users
[ ] Create CI permission set
[ ] Assign permission set to CI user
[ ] Authorize permission set in External Client App
[ ] Retrieve Consumer Key
[ ] Test sf org login jwt locally
[ ] Create SF_USERNAME GitHub Secret
[ ] Create SF_CLIENT_ID GitHub Secret
[ ] Create SF_JWT_KEY GitHub Secret
[ ] Create .github/workflows/salesforce-ci.yml
[ ] Push workflow
[ ] Create feature → Developer_Branch PR
[ ] Confirm CI runs
[ ] Confirm tests execute
[ ] Protect Developer_Branch
[ ] Make Salesforce CI required
[ ] Test intentional failure
[ ] Confirm merge is blocked
[ ] Restore passing test
[ ] Confirm CI passes
[ ] Create/verify salesforce-cd.yml
[ ] Confirm CD triggers on Developer_Branch push
[ ] Confirm CD validation runs RunLocalTests
[ ] Confirm successful validation deploys to Salesforce
[ ] Confirm failed validation stops before deployment
[ ] Merge feature
```

------------------------------------------------------------------------

# 32. Final Mental Model

If you forget everything else, remember this:

``` text
                 SALESFORCE CI/CD

Developer
   │
   │ git push
   ▼
Feature Branch
   │
   │ Pull Request
   ▼
GitHub
   │
   │ GitHub Actions
   ▼
Authenticate
   │
   │ JWT
   ▼
External Client App
   │
   │ server.crt verifies
   ▼
CI/CD Salesforce User
   │
   ▼
Salesforce Metadata API
   │
   ├── Validate metadata
   ├── Run Apex tests
   └── Check deployment requirements
   │
   ▼
GitHub Status Check
   │
   ├───────────────┐
   │               │
   ▼               ▼
 PASS            FAIL
   │               │
   ▼               ▼
Merge           Block Merge
```

### The three most important security rules

``` text
1. Private key stays secret.
2. CI uses a dedicated Salesforce user.
3. A failing required CI check must block the PR.
```

------------------------------------------------------------------------

## Useful Salesforce CLI command

JWT login:

``` bash
sf org login jwt \
  --username "YOUR_CI_USERNAME" \
  --client-id "YOUR_CONSUMER_KEY" \
  --jwt-key-file "server.key" \
  --instance-url "https://login.salesforce.com" \
  --alias ci-org
```

Verify:

``` bash
sf org display --target-org ci-org
```

Validate:

``` bash
sf project deploy start \
  --source-dir force-app \
  --target-org ci-org \
  --dry-run \
  --test-level RunLocalTests \
  --wait 30
```

------------------------------------------------------------------------

## Important Note

This document describes the **working learning setup we built**.
Salesforce's External Client App and OAuth features continue to evolve,
so if a future Salesforce org presents a slightly different UI, use the
same underlying concepts:

``` text
External Client App
+ JWT Bearer Flow
+ Public certificate
+ Preauthorization
+ CI user
+ OAuth scopes
```

Then adapt the UI labels to the version of Salesforce you're using.
