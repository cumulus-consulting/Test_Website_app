resource "aws_secretsmanager_secret" "secret" {
  name        = var.secret_name
  description = "MongoDB connection info"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "secretversion" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = <<EOF
{
  "username": "${var.mongo_username}",
  "password": "${var.mongo_password}",
  "host": "${var.mongo_host}",
  "port": "${var.mongo_port}",
  "dbname": "${var.mongo_dbname}"
}
EOF
}