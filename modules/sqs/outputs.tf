output "gps_tracking_queue_arn" {
  description = "ARN of the GPS Tracking SQS queue"
  value       = aws_sqs_queue.gps_tracking.arn
}

output "gps_tracking_queue_url" {
  description = "URL of the GPS Tracking SQS queue"
  value       = aws_sqs_queue.gps_tracking.id
}




