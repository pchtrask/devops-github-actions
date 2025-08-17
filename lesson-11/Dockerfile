FROM python:3.9-slim

# Intentional vulnerability: Running as root user
WORKDIR /app

# Copy requirements and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Intentional vulnerability: Exposing internal port
EXPOSE 5000

# Intentional vulnerability: No health checks or proper signal handling
CMD ["python", "app.py"]
