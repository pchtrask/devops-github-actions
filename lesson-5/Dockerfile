FROM python:3.11-slim
COPY requirements.txt /tmp/requirements.txt
# COPY . /app
RUN pip install --no-cache-dir -r /tmp/requirements.txt && rm -rf /tmp/requirements.txt
# WORKDIR /app
# RUN touch test.txt
EXPOSE 3000
CMD ["python", "demoapp/app.py"]
