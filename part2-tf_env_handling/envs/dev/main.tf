module "network" {
  source = "../../../part1-tf_infra_design/infra/modules/network"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "alb" {
  source = "../../../part1-tf_infra_design/infra/modules/alb"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
}

module "ecs" {
  source = "../../../part1-tf_infra_design/infra/modules/ecs"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.network.vpc_id
  private_subnet_ids    = module.network.private_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id # <-- chain: ALB SG -> ECS
  target_group_arn      = module.alb.target_group_arn
  container_image       = var.container_image
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
}


module "rds" {
  source = "../../../part1-tf_infra_design/infra/modules/rds"

  project_name            = var.project_name
  environment             = var.environment
  vpc_id                  = module.network.vpc_id
  private_subnet_ids      = module.network.private_subnet_ids
  ecs_security_group_id   = module.ecs.ecs_security_group_id # <-- chain: ECS SG -> RDS
  db_password             = var.db_password
  instance_class          = var.db_instance_class
  backup_retention_period = var.db_backup_retention_period
  deletion_protection     = var.db_deletion_protection
  multi_az                = var.multi_az
}
