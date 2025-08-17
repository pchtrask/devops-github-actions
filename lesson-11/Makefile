# DevSecOps Demo Makefile
# Provides easy commands for running SAST, DAST, and application management

.PHONY: help install run test sast dast clean docker-build docker-run stop

# Default target
help:
	@echo "DevSecOps Demo - Available Commands:"
	@echo ""
	@echo "Setup:"
	@echo "  make install     - Install dependencies and security tools"
	@echo ""
	@echo "Application:"
	@echo "  make run         - Start the vulnerable application"
	@echo "  make test        - Test application endpoints"
	@echo "  make stop        - Stop the application"
	@echo ""
	@echo "Security Testing:"
	@echo "  make sast        - Run Static Application Security Testing"
	@echo "  make dast        - Run Dynamic Application Security Testing"
	@echo "  make security    - Run both SAST and DAST"
	@echo ""
	@echo "Docker:"
	@echo "  make docker-build - Build Docker image"
	@echo "  make docker-run   - Run application in Docker"
	@echo ""
	@echo "Cleanup:"
	@echo "  make clean       - Clean up reports and temporary files"

# Install dependencies and security tools
install:
	@echo "Installing dependencies..."
	pip install -r requirements.txt
	pip install bandit[toml] safety
	@echo "✅ Installation complete!"

# Start the vulnerable application
run:
	@echo "Starting vulnerable microservice..."
	@echo "⚠️  This application contains intentional vulnerabilities!"
	@echo "🌐 Application will be available at http://localhost:5000"
	python app.py

# Test application endpoints
test:
	@echo "Testing application endpoints..."
	python test_app.py

# Run SAST (Static Application Security Testing)
sast:
	@echo "Running SAST with Bandit..."
	./run_sast.sh

# Run DAST (Dynamic Application Security Testing)
dast:
	@echo "Running DAST with OWASP ZAP..."
	@echo "⚠️  Make sure the application is running first (make run)"
	./run_dast.sh

# Run both SAST and DAST
security: sast dast
	@echo "✅ Security testing complete!"
	@echo "📊 Check the reports/ directory for detailed results"

# Build Docker image
docker-build:
	@echo "Building Docker image..."
	docker build -t vulnerable-app .
	@echo "✅ Docker image built: vulnerable-app"

# Run application in Docker
docker-run:
	@echo "Running application in Docker..."
	@echo "🌐 Application will be available at http://localhost:5000"
	docker run -p 5000:5000 vulnerable-app

# Stop running processes
stop:
	@echo "Stopping application processes..."
	pkill -f "python app.py" || true
	docker stop $$(docker ps -q --filter ancestor=vulnerable-app) || true
	@echo "✅ Processes stopped"

# Clean up reports and temporary files
clean:
	@echo "Cleaning up..."
	rm -rf reports/
	rm -f users.db
	rm -f *.pyc
	rm -rf __pycache__/
	rm -rf .pytest_cache/
	docker rmi vulnerable-app || true
	@echo "✅ Cleanup complete!"

# Development helpers
dev-setup: install
	@echo "Setting up development environment..."
	pip install pytest black flake8
	@echo "✅ Development environment ready!"

# Run application in background for testing
run-bg:
	@echo "Starting application in background..."
	python app.py &
	@sleep 5
	@echo "✅ Application started in background"

# Quick security check (fast SAST only)
quick-check:
	@echo "Running quick security check..."
	bandit -r . -ll
	safety check

# Generate security report
report: security
	@echo "Generating security summary report..."
	@mkdir -p reports
	@echo "# DevSecOps Security Report" > reports/summary.md
	@echo "Generated on: $$(date)" >> reports/summary.md
	@echo "" >> reports/summary.md
	@echo "## SAST Results" >> reports/summary.md
	@if [ -f reports/bandit-report.txt ]; then \
		echo "Bandit scan completed - see bandit-report.txt" >> reports/summary.md; \
	fi
	@echo "" >> reports/summary.md
	@echo "## DAST Results" >> reports/summary.md
	@echo "OWASP ZAP scan results - see ZAP reports" >> reports/summary.md
	@echo "✅ Security report generated: reports/summary.md"
