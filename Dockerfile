# Image minimal Alpine untuk mengurangi attack surface.
FROM python:3.12-alpine

LABEL maintainer="secure-ci-cd-demo"
LABEL org.opencontainers.image.description="Flask demo untuk pipeline CI/CD aman"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY app/requirements.txt .

# Install build dependencies hanya saat instalasi paket Python,
# lalu hapus agar image runtime tetap kecil dan lebih bersih saat scan.
RUN apk add --no-cache --virtual .build-deps \
      gcc \
      musl-dev \
  && pip install --no-cache-dir -r requirements.txt \
  && apk del .build-deps

COPY app/ .

EXPOSE 5000

# Periksa endpoint kesehatan; interval disesuaikan agar tidak terlalu agresif di lingkungan kecil.
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:5000/')" || exit 1

CMD ["python", "app.py"]
