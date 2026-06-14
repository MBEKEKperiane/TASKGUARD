# ─── TaskGuard AI – Docker shortcuts ─────────────────────────────────────────
# Prerequisites: Docker Desktop running, .env file created from .env.example
#
# Usage:
#   make          → show this help
#   make up       → start dev stack (builds if needed)
#   make down     → stop and remove containers
#   make logs     → tail backend logs
#   make shell    → open a shell inside the backend container
#   make db-shell → open psql inside the database container
#   make migrate  → run pending Prisma migrations
#   make studio   → open Prisma Studio (localhost:5555)
#   make prod-up  → start production stack

.PHONY: help up down logs shell db-shell migrate studio prod-up prod-down reset

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

up: ## Start development stack (hot-reload enabled)
	docker compose up --build

up-d: ## Start development stack in background
	docker compose up --build -d

down: ## Stop and remove dev containers
	docker compose down

logs: ## Tail backend logs
	docker compose logs -f backend

shell: ## Open shell in backend container
	docker compose exec backend sh

db-shell: ## Open psql in database container
	docker compose exec db psql -U $${POSTGRES_USER:-taskguard} $${POSTGRES_DB:-taskguard_db}

migrate: ## Run pending Prisma migrations
	docker compose exec backend npx prisma migrate deploy

studio: ## Open Prisma Studio (http://localhost:5555)
	docker compose exec backend npx prisma studio --port 5555 --browser none

reset: ## ⚠️  Drop database and re-run all migrations (dev only)
	docker compose exec backend npx prisma migrate reset --force

prod-up: ## Start production stack in background
	docker compose -f docker-compose.prod.yml up --build -d

prod-down: ## Stop production stack
	docker compose -f docker-compose.prod.yml down

prod-logs: ## Tail production backend logs
	docker compose -f docker-compose.prod.yml logs -f backend
