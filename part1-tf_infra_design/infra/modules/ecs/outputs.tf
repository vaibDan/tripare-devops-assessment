output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}

output "cluster_id" {
  value = aws_ecs_cluster.this.id
}
