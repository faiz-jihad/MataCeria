#!/bin/bash
# scripts/setup_production.sh

echo "🚀 Menyiapkan lingkungan produksi MataCeria..."

# 1. Pastikan folder uploads ada
mkdir -p uploads/images
chmod -R 777 uploads

# 2. Build & Up
docker-compose up -d --build

echo "⏳ Menunggu database siap..."
sleep 15

# 3. Restore DB jika backup_db.sql ada
if [ -f "backup_db.sql" ]; then
    echo "📦 Melakukan restore database dari backup_db.sql..."
    docker exec -it postgres_refraksi psql -U user_admin -d postgres -c "DROP DATABASE IF EXISTS db_refraksi;"
    docker exec -it postgres_refraksi psql -U user_admin -d postgres -c "CREATE DATABASE db_refraksi;"
    cat backup_db.sql | docker exec -i postgres_refraksi psql -U user_admin -d db_refraksi
fi

# 4. Sinkronisasi Seeding (Optional)
echo "🌱 Menjalankan seeding data opsional..."
docker exec -it fastapi_refraksi python -m scripts.seed_regional_data

echo "✅ Setup selesai! Backend siap diakses."
