output "efs_id"              { value = aws_efs_file_system.main.id }
output "efs_arn"             { value = aws_efs_file_system.main.arn }
output "efs_dns_name"        { value = aws_efs_file_system.main.dns_name }
output "efs_access_point_id" { value = aws_efs_access_point.fleetops.id }




