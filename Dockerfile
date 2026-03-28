# Stage 1: Build
FROM python:3.10-slim as builder

WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

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
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r requirements.txt

COPY . .

# Buat folder uploads jika belum ada dan atur permission
RUN mkdir -p uploads/images && chmod -R 777 uploads

ENV WORKERS=1
ENV PORT=8000

EXPOSE 8000

# Jalankan Gunicorn dengan Uvicorn worker (Jumlah worker dan port bisa diatur via env)
CMD ["sh", "-c", "gunicorn -w ${WORKERS} -k uvicorn.workers.UvicornWorker app.main:app --bind 0.0.0.0:${PORT} --timeout 120"]