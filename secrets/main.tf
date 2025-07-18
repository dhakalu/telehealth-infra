resource "random_password" "jwt_secret" {
  length           = 30
  special          = true
  override_special = "!#$%*()-_=+[]{}<>:?"
}

resource "aws_ssm_parameter" "jwt_secret" {
  name      = "/idp/${var.environment}/jwt_secret"
  type      = "SecureString"
  value     = random_password.jwt_secret.result
  overwrite = true
}
