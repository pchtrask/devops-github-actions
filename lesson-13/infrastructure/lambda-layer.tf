# Create a simple psycopg2 layer using local build
resource "null_resource" "build_psycopg2_layer" {
  triggers = {
    # Rebuild if the build script changes
    build_script = filebase64("${path.module}/create_psycopg2_layer.py")
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      
      echo "Building psycopg2 Lambda layer..."
      
      # Create temporary directory for layer
      LAYER_DIR=$(mktemp -d)
      cd "$LAYER_DIR"
      
      # Create layer structure
      mkdir -p python/lib/python3.11/site-packages
      
      # Install psycopg2-binary
      echo "Installing psycopg2-binary..."
      pip install psycopg2-binary==2.9.9 -t python/lib/python3.11/site-packages/ --no-deps --quiet
      
      # Clean up unnecessary files
      echo "Cleaning up unnecessary files..."
      find python/ -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
      find python/ -name "*.pyc" -delete 2>/dev/null || true
      find python/ -name "*.pyo" -delete 2>/dev/null || true
      find python/ -name "*.dist-info" -type d -exec rm -rf {} + 2>/dev/null || true
      
      # Create zip file
      echo "Creating layer zip file..."
      zip -r "${path.module}/psycopg2-layer.zip" python/ -q
      
      # Cleanup temporary directory
      cd "${path.module}"
      rm -rf "$LAYER_DIR"
      
      echo "psycopg2 layer built successfully at ${path.module}/psycopg2-layer.zip"
    EOT
  }
}

# Lambda layer using the built package
resource "aws_lambda_layer_version" "psycopg2" {
  depends_on = [null_resource.build_psycopg2_layer]
  
  filename         = "psycopg2-layer.zip"
  layer_name       = "devops-lesson-13-psycopg2"
  description      = "PostgreSQL adapter for Python (psycopg2)"
  source_code_hash = filebase64sha256("psycopg2-layer.zip")
  
  compatible_runtimes      = [ "python3.12"]
  compatible_architectures = ["x86_64"]
}
