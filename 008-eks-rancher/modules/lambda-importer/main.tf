# Lambda Importer Packaging & Function Definition

locals {
  build_dir = "${path.module}/.build"
}

# Package pure-Python dependencies (PyYAML) for Lambda arm64 runtime
resource "terraform_data" "package_build" {
  triggers_replace = {
    source_hash = filemd5("${path.module}/src/importer.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      rm -rf "${local.build_dir}" && mkdir -p "${local.build_dir}" && \
      cp "${path.module}/src/importer.py" "${local.build_dir}/importer.py" && \
      pip3 install --quiet --platform manylinux2014_aarch64 --implementation cp --python-version 3.12 --only-binary=:all: --target "${local.build_dir}" pyyaml
    EOT
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${path.module}/lambda_importer.zip"

  depends_on = [terraform_data.package_build]
}

resource "aws_lambda_function" "this" {
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = "importer.lambda_handler"
  runtime          = "python3.12"
  architectures    = ["arm64"]
  timeout          = 60
  memory_size      = 256
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = {
      WORKLOAD_CLUSTER_NAME = var.workload_cluster_name
      RANCHER_URL_PARAM     = var.rancher_url_ssm_param
      RANCHER_PASS_PARAM    = var.rancher_password_ssm_param
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy.this,
    aws_eks_access_policy_association.lambda,
  ]
}
