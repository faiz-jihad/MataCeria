# Makefile untuk MataCeria Backend

.PHONY: help build up down restart logs test seed migrate-db

help:
	@echo "MataCeria Deployment Commands:"
	@echo "  make build        - Membangun image Docker"
	@echo "  make up           - Menjalankan kontainer di background"
	@echo "  make down         - Menghentikan kontainer"
	@echo "  make restart      - Restart seluruh layanan"
	@echo "  make logs         - Melihat log kontainer"
	@echo "  make test         - Menjalankan unit tests"
	@echo "  make seed         - Mengisi data awal (Seeding)"
	@echo "  make restore-db   - WIPE database dan restore dari backup_db.sql (Hati-Hati!)"
	@echo "  make tunnel-url   - Mendapatkan link publik TryCloudflare"

build:
	docker-compose build

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose down && docker-compose up -d --build

logs:
	docker-compose logs -f

test:
	docker exec -it fastapi_refraksi pytest tests/

seed:
	docker exec -it fastapi_refraksi python -m scripts.seed_data
	docker exec -it fastapi_refraksi python -m scripts.seed_articles
	docker exec -it fastapi_refraksi python -m scripts.seed_regional_data

restore-db:
	@echo "⚠️  PERINGATAN: Ini akan menghapus seluruh data di database!"
	@read -p "Apakah Anda yakin? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	docker exec -it postgres_refraksi psql -U user_admin -d postgres -c "DROP DATABASE IF EXISTS db_refraksi;"
	docker exec -it postgres_refraksi psql -U user_admin -d postgres -c "CREATE DATABASE db_refraksi;"
	cat backup_db.sql | docker exec -i postgres_refraksi psql -U user_admin -d db_refraksi
	@echo "✅ Database berhasil di-restore!"

tunnel-url:
	@echo "🌍 Mencari link publik TryCloudflare..."
	@docker logs cloudflared_refraksi 2>&1 | grep -o 'https://.*trycloudflare.com' | tail -n 1
