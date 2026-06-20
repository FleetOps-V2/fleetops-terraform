output "zone_id"      { value = aws_route53_zone.main.zone_id }
output "zone_name"    { value = aws_route53_zone.main.name }

output "name_servers" {
  description = "Copy these 4 NS records into GoDaddy DNS settings to delegate fleetops.website to Route53"
  value       = aws_route53_zone.main.name_servers
}




