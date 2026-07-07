# Part 3 (Optional): Terraform Plan in GitHub Actions

## Where the actual workflow file lives

**`.github/workflows/terraform-plan.yml`** — at the repo root, not in this
folder. GitHub Actions only discovers workflows in that exact path; it can't
be relocated into a `part3-...` subfolder. This folder holds the explanation.

## What the workflow does, step by step

Triggers on any Pull Request that touches Part 1 or Part 2's Terraform code.
Runs the pipeline **twice per PR** — once for `dev`, once for `prod` — since
they're separate root modules (see `part2-tf_env_handling/README.md`).

| Step | What it does | Why |
|---|---|---|
| `terraform fmt -check -recursive` | Fails if any file isn't formatted per Terraform's standard style | Catches style issues automatically instead of relying on manual review |
| `terraform init -backend=false` | Downloads the AWS provider, skips configuring real backend storage | This workflow only plans, never applies — no need for real state storage in CI |
| `terraform validate` | Checks syntax, types, required arguments | Catches typos/misconfigurations before a human ever reads the plan |
| `terraform plan -var-file=<env>.tfvars` | Shows what *would* be created | The actual deliverable — run with dummy AWS credentials (`AWS_ACCESS_KEY_ID=fake`), since the assignment explicitly states real deployment isn't required |

## How the plan gets shared on the PR

Posted as a **PR comment**, via `actions/github-script`, one comment per
environment (`dev` and `prod` separately). Each comment shows a quick
pass/fail summary table for all four steps, plus the full plan output inside
a collapsible `<details>` block — visible without leaving the PR page, but
collapsed by default so it doesn't dominate the PR thread.

## Design choices worth being able to explain

- **`continue-on-error: true` on `fmt` and `plan`, but not `init`/`validate`**
  — if `init` or `validate` fails, there's nothing meaningful to show in a
  comment (the config is broken), so the job should just fail normally. But
  `fmt`/`plan` failing is still useful information worth *posting*, so the
  workflow captures the outcome, posts it, and only fails the job afterward
  in a final explicit step.
- **`concurrency` group per PR number** — if someone pushes twice quickly,
  the first run cancels instead of both finishing and posting two
  overlapping comments.
- **Dummy AWS credentials, no real secrets used** — consistent with Part
  1/2's local `terraform plan` setup (`skip_credentials_validation` etc. in
  `providers.tf`); this workflow never touches a real AWS account.

## What I'd change for a real production setup (not needed here)

- Real AWS credentials via GitHub OIDC (no long-lived secrets), scoped to a
  read-only plan role.
- A real S3 + DynamoDB backend (see `backend-dev.hcl`/`backend-prod.hcl` in
  Part 2) instead of `-backend=false`, so plan reflects real existing state.
- Branch protection requiring this workflow to pass before merge.
