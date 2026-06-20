output "eks_node_role_arn"           { value = aws_iam_role.eks_node.arn }
output "eks_node_instance_profile"   { value = aws_iam_instance_profile.eks_node.name }
output "app_irsa_role_arn"           { value = aws_iam_role.app_service_account.arn }
output "lambda_role_arn"             { value = aws_iam_role.lambda.arn }
output "github_actions_role_arn"     { value = aws_iam_role.github_actions.arn }
output "github_actions_ecr_role_arn" { value = aws_iam_role.github_actions_ecr.arn }
output "devops_agent_role_arn"       { value = aws_iam_role.devops_agent.arn }




