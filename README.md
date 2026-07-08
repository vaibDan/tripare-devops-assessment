# DevOps Assessment — Terraform + Database Reliability

Submission for the Tripare AI / Triphoria technical assessment. Six parts,
each in its own folder with a dedicated README covering setup, verification,
and the reasoning behind key design decisions.

## Structure

| Folder | Covers | Status |
|---|---|---|
| [`part1-tf_infra_design/`](part1-tf_infra_design/README.md) | Terraform modules: VPC, ALB, ECS/Fargate, RDS | Complete |
| [`part2-tf_env_handling/`](part2-tf_env_handling/README.md) | `dev`/`prod` environments consuming Part 1's modules | Complete |
| [`part3-tf_plan_github/`](part3-tf_plan_github/README.md) | GitHub Actions: fmt/init/validate/plan on PRs (optional) | Plan runs correctly; PR-comment step has a known permissions issue — see note below |
| [`part4-local_db_test/`](part4-local_db_test/README.md) | Docker Compose Postgres, `hotel_bookings`/`booking_events` schema | Complete |
| [`part5-seed_data_and_indexing/`](part5-seed_data_and_indexing/README.md) | Seed data, query optimization index, before/after benchmark | Complete |
| [`part6-backup_and_restore/`](part6-backup_and_restore/README.md) | Timestamped backup, restore-into-fresh-database, verification | Complete |

## Architecture (Parts 1–2)

```
Internet → ALB (public subnets) → ECS/Fargate (private subnets) → RDS (private subnets)
```

RDS is made private via `publicly_accessible = false` plus a security group
that only accepts traffic from the ECS security group's ID (not a CIDR
range) — the same SG-to-SG pattern chains ALB → ECS. Full reasoning in
Part 1's README.

`dev` and `prod` are built from the exact same modules with different
values (sizing, backup retention, deletion protection, isolated state) — no
duplicated resource code between environments. Full diff table in Part 2's
README.

## Database (Parts 4–6)

Local Postgres via Docker Compose → seed data → an index on the assignment's
target query, benchmarked at three stages (seq scan → bitmap scan → index
only scan, ~7x faster end to end) → backup/restore scripts with a documented
3-step verification process (row counts, schema/index presence, row content).

## Quick start

```bash
# --- Terraform (Parts 1-2), plan-only, no AWS account needed ---
cd part2-tf_env_handling/envs/dev
export AWS_ACCESS_KEY_ID=fake AWS_SECRET_ACCESS_KEY=fake
terraform init && terraform validate && terraform plan -var-file=dev.tfvars -refresh=false
# repeat in ../prod with prod.tfvars

# --- Database (Parts 4-6) ---
cd part4-local_db_test
docker compose up -d
cd ../part5-seed_data_and_indexing
docker exec -i tripare-local-db psql -U appadmin -d appdb < seeds.sql
docker exec -i tripare-local-db psql -U appadmin -d appdb < indexes.sql

cd ../part6-backup_and_restore
./scripts/backup.sh
./scripts/restore.sh
```

## Known limitation

Part 3's fmt/init/validate/plan steps run, but the workflow's final pass/fail check currently reports a failure in CI (exit code 1) that doesn't reproduce when running the same commands locally. Not resolved given the assessment deadline — Part 3 is explicitly optional.
[`part3-tf_plan_github/README.md`](part3-tf_plan_github/README.md).

## Submission checklist (from the assignment)

- [x] Terraform infrastructure code — Part 1
- [x] `dev` and `prod` Terraform environment examples — Part 2
- [x] Docker Compose database setup — Part 4
- [x] SQL migration files — Part 4
- [x] Seed data script — Part 5
- [x] Database backup script — Part 6
- [x] Database restore script — Part 6
- [x] README with setup and verification steps — this file + one per part
