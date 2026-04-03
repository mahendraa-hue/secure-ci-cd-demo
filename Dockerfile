# Image minimal untuk menjalankan aplikasi Flask demo.
FROM python:3.12-slim-bookworm

LABEL maintainer="secure-ci-cd-demo"
LABEL org.opencontainers.image.description="Flask demo untuk pipeline CI/CD aman"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app/ .

EXPOSE 5000

# Periksa endpoint kesehatan; interval disesuaikan agar tidak terlalu agresif di lingkungan kecil.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/')" || exit 1

CMD ["python", "app.py"]
