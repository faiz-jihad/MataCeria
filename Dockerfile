# Stage 1: Build
FROM python:3.10-slim as builder

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    python3-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
# Hapus --no-deps agar semua dependency juga di-bundle ke dalam wheels
RUN pip wheel --no-cache-dir --wheel-dir /app/wheels -r requirements.txt

# Stage 2: Final
FROM python:3.10-slim

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

COPY --from=builder /app/wheels /wheels
COPY --from=builder /app/requirements.txt .
# Hapus instalasi curl yang memakan banyak memori, gunakan urllib.request untuk healthcheck
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt

COPY . .

# Buat folder uploads jika belum ada dan atur permission
RUN mkdir -p uploads/images && chmod -R 777 uploads

# Security: Jalankan sebagai non-root user
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser:appuser /app
USER appuser

ENV WORKERS=1
ENV PORT=8000

EXPOSE 8000

# Jalankan Gunicorn dengan Uvicorn worker (Jumlah worker dan port bisa diatur via env)
# MALLOC_ARENA_MAX=2 membantu mengurangi fragmentasi memori Python
ENV MALLOC_ARENA_MAX=2
CMD ["sh", "-c", "gunicorn -w ${WORKERS} -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:${PORT} --timeout 120"]