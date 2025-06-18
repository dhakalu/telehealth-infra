resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-ecs-cluster"
}

resource "aws_ssm_parameter" "ecs_cluster_name" {
  name  = "/http/${var.environment}/ecs_cluster_name"
  type  = "String"
  value = aws_ecs_cluster.main.name
}