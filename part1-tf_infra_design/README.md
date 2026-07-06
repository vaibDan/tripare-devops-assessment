# Part 1: Terraform Infrastructure Design

Reusable Terraform modules implementing:

```
Internet → ALB (public subnets) → ECS/Fargate (private subnets) → RDS (private subnets)
```

## Structure

```
part1-tf_infra_design/
└── infra/modules/
    ├── network/   VPC, 2 public + 2 private subnets (2 AZs), IGW, NAT Gateway, route tables
    ├── alb/       ALB, target group, listener, ALB security group
    ├── ecs/       ECS cluster, Fargate task definition, service, ECS security group
    └── rds/       RDS instance (Postgres), DB subnet group, RDS security group
```

## The key design decision: making RDS private

RDS is made private and reachable only from ECS via two mechanisms:

1. **`publicly_accessible = false`** on the RDS instance (`modules/rds/main.tf`) — no public endpoint exists at all, regardless of security groups.
2. **Security-group-to-security-group reference.** The RDS security group's ingress rule allows traffic from the **ECS security group's ID**, not a CIDR block:
   ```hcl
   ingress {
     from_port       = 5432
     security_groups = [var.ecs_security_group_id]   # not a cidr_blocks list
   }
   ```
   Only network interfaces belonging to that ECS SG can reach RDS on 5432 — enforced at the network layer, independent of subnet routing.

The identical pattern chains ALB → ECS: the ECS security group only accepts inbound traffic from the ALB security group's ID (`modules/ecs/main.tf`). The ALB security group is the only one in the whole stack open to `0.0.0.0/0`.

## Why these modules have no `provider` or `backend` block

They're reusable building blocks, not a deployable root module — same reason you don't put a database connection string inside a library function. They're wired together and given real values (sizing, backup retention, deletion protection) per-environment in **[`../part2-tf_env_handling/`](../part2-tf_env_handling/README.md)**.

## How to verify Part 1 actually works

Since a bare module has nothing to `plan` against on its own, verification happens in two stages:

1. **In this folder** — lint/type-check the module code in isolation:
   ```bash
   terraform fmt -check -recursive
   terraform validate
   ```
   (`validate` on a plain module directory checks syntax and resource schemas, though a full provider-aware validate needs the wiring in Part 2.)

2. **Through Part 2** — the real proof these modules are correctly built and genuinely reusable: they get called twice, with different values, and both plan cleanly with no duplicated resource logic:
   ```bash
   cd ../part2-tf_env_handling/envs/dev  && terraform init && terraform validate && terraform plan -var-file=dev.tfvars -refresh=false
   cd ../prod                             && terraform init && terraform validate && terraform plan -var-file=prod.tfvars -refresh=false
   ```
   Both should report `Plan: 28 to add, 0 to change, 0 to destroy` with only the security group / instance size / retention values differing.
