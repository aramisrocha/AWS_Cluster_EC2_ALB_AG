resource "aws_iam_role" "role_lab01" {
  name = "example-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "police_lab01" {
  name        = "Police_lab01"
  description = "Police para a instancia no cluster"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:UpdateAutoScalingGroup"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "elasticloadbalancing:RegisterTargets",
          "elasticloadbalancing:DeregisterTargets"
        ],
        Effect = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData"
        ],
        Effect = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "example_policy_attachment" {
  policy_arn = aws_iam_policy.police_lab01.arn
  role       = aws_iam_role.role_lab01.name
}


