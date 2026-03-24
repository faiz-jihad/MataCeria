FROM python:3.10-slim

WORKDIR /app

# Kita lewati apt-get update untuk menghindari isu network mirror/repository yang sedang down (Exit Code 100).
# Karena kita menggunakan 'opencv-python-headless' dan 'psycopg2-binary', 
# sebagian besar library system sudah ter-bundle di dalam wheel python.

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Buat folder uploads jika belum ada
RUN mkdir -p uploads/images

EXPOSE 8000

# Jalankan Gunicorn dengan Uvicorn worker
CMD ["gunicorn", "-w", "4", "-k", "uvicorn.workers.UvicornWorker", "app.main:app", "--bind", "0.0.0.0:8000"]