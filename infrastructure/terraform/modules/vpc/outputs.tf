output "vpc_id" {
  value = aws_vpc.this.id
  
}



output "public_subnet_ids" {
  description = "A list of all public subnet IDs"
  value       = [for s in aws_subnet.public_subnet : s.id]
}

output "private_subnet_ids" {
  description = "A list of all private subnet IDs"
  value       = [for s in aws_subnet.private_subnet : s.id]
}
