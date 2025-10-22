# EventBridge Rule for weekly suggestions
resource "aws_cloudwatch_event_rule" "weekly_suggestions" {
  name                = "${var.lambda_function_name}-weekly"
  description         = "Trigger weekly suggestions for GroupMe bot"
  schedule_expression = var.schedule_expression
}

# EventBridge Target - Lambda function
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.weekly_suggestions.name
  target_id = "WeeklySuggestionsLambda"
  arn       = aws_lambda_function.bot.arn

  input = jsonencode({
    source = "aws.events"
    detail = {
      type = "scheduled_suggestion"
    }
  })
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bot.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_suggestions.arn
}
