# Part 2: Terraform Environment Handling

Two environments, `dev` and `prod`, both built from the same modules in
[`../part1-tf_infra_design/modules/`](../part1-tf_infra_design/README.md) —
zero duplicated resource code. Only the variable *values* differ per
environment; `main.tf` is structurally identical between `envs/dev` and `envs/prod`.

## Structure

```
part2-tf_env_handling/
└── envs/
    ├── dev/
    │   ├── main.tf            wires network + alb + ecs + rds modules together
    │   ├── variables.tf       dev defaults
    │   ├── providers.tf       backend: terraform-dev.tfstate
    │   ├── dev.tfvars         explicit dev values
    │   └── backend-dev.hcl    example S3 backend config (not active — see below)
    └── prod/
        └── ... (same files, prod values)
```

## What differs between dev and prod, and why

| | dev | prod | why |
|---|---|---|---|
| VPC CIDR | `10.0.0.0/16` | `10.1.0.0/16` | separate ranges, safe to peer later |
| Task size | 256 CPU / 512 MB | 512 CPU / 1024 MB | dev doesn't serve real traffic |
| DB instance | `db.t3.micro` | `db.t3.medium` | cost vs. real load |
| Backup retention | 1 day | 7 days | prod data isn't disposable |
| `deletion_protection` | `false` | `true` | blocks an accidental `terraform destroy` on real data |
| `multi_az` | `false` | `true` | prod needs DB failover; dev doesn't need the 2x cost |
| State file | `terraform-dev.tfstate` | `terraform-prod.tfstate` | dev/prod state can never collide or overwrite each other |

## Backend state

Both environments use `backend "local"` with separate state file names, so this
repo can be reviewed with `terraform plan` and no live AWS access — this
assessment explicitly doesn't require real deployment.

`backend-dev.hcl` / `backend-prod.hcl` document what a real team setup would
use instead: an S3 backend with a per-environment `key` (`dev/terraform.tfstate`
vs `prod/terraform.tfstate` in the same bucket) plus a DynamoDB table for state
locking. Switching to it in a real environment:
```bash
# 1. remove the backend "local" block from providers.tf, replace with:
#      backend "s3" {}
# 2. create the bucket + DynamoDB table once, out of band
# 3. terraform init -backend-config=backend-dev.hcl -migrate-state
```
This isn't wired up live here on purpose — it would make the submission
depend on infrastructure only the candidate has access to.

## How to run

```bash
cd envs/dev   # or envs/prod

export AWS_ACCESS_KEY_ID=fake
export AWS_SECRET_ACCESS_KEY=fake

terraform fmt -recursive
terraform init
terraform validate
terraform plan -var-file=dev.tfvars -refresh=false    # or prod.tfvars in envs/prod
```

Both should report `Plan: 28 to add, 0 to change, 0 to destroy`.

This is also the way to verify Part 1's modules are correct — see
[Part 1's README](../part1-tf_infra_design/README.md#how-to-verify-part-1-actually-works)
for why module correctness is proven here rather than in Part 1 directly.
