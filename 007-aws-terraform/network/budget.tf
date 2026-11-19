# AWS Budgets: Financial Governance & Cost Alert
resource "aws_budgets_budget" "this" {
  count = var.budget_email != "" ? 1 : 0

  name         = "${var.environment}-monthly-cost-budget"
  budget_type  = "COST"
  limit_amount = var.monthly_budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Alert 1: Actual spend reaches 80% of budget limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_email]
  }

  # Alert 2: Forecasted spend is predicted to exceed 100% of budget limit
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_email]
  }
}
