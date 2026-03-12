output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr" {
  value = aws_vpc.this.cidr_block
}

output "private_subnet_ids" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "private_route_table_ids" {
  value = [aws_route_table.private.id]
}

output "shared_workload_security_group_id" {
  value = aws_security_group.shared_workloads.id
}
