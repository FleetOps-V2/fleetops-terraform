output "redis_endpoint_param"       { value = aws_ssm_parameter.redis_endpoint.name }
output "cors_origins_param"         { value = aws_ssm_parameter.cors_allowed_origins.name }
output "spring_profile_param"       { value = aws_ssm_parameter.spring_profile.name }




