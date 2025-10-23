# Makefile
.PHONY: up up-staging up-prod down down-staging down-prod build logs clean fresh urls \
        test-email bash-backend bash-frontend migrate seed composer-install \
        frontend-install db-bash redis-cli status backend-logs frontend-logs mailpit-logs

# Default environment (development)
DOCKER_DEV = docker-compose -f docker-compose.yml -f docker-compose.dev.yml
DOCKER_STAGING = docker-compose -f docker-compose.yml -f docker-compose.staging.yml
DOCKER_PROD = docker-compose -f docker-compose.yml -f docker-compose.prod.yml

# ============================================================
# 🚀 Environment Management
# ============================================================

# Start development environment
up:
	$(DOCKER_DEV) up --build

# Start staging environment
up-staging:
	$(DOCKER_STAGING) up -d

# Start production environment
up-prod:
	$(DOCKER_PROD) up -d

# Stop development environment
down:
	$(DOCKER_DEV) down

# Stop staging environment
down-staging:
	$(DOCKER_STAGING) down	

# Stop production environment
down-prod:
	$(DOCKER_PROD) down

# Build images (development)
build:
	$(DOCKER_DEV) build

# Clean up everything
clean:
	$(DOCKER_DEV) down -v --remove-orphans
	docker system prune -f

# ============================================================
# 🧰 Development Utilities
# ============================================================

# Fresh install (backend + frontend)
fresh: down
	$(DOCKER_DEV) build
	$(DOCKER_DEV) up -d backend-database backend-redis mailpit
	sleep 10
	$(DOCKER_DEV) exec backend-app composer install
	$(DOCKER_DEV) exec backend-app php artisan key:generate
	make migrate
	$(DOCKER_DEV) up -d

# View logs (all)
logs:
	$(DOCKER_DEV) logs -f

# View specific service logs
backend-logs:
	$(DOCKER_DEV) logs -f backend-app

frontend-logs:
	$(DOCKER_DEV) logs -f frontend-app

mailpit-logs:
	$(DOCKER_DEV) logs -f mailpit

# ============================================================
# 🌐 Info and Status
# ============================================================

urls:
	@echo ""
	@echo "🌐 Your ShiftPilot Environment URLs"
	@echo "-----------------------------------"
	@echo "Frontend:           http://frontend.localhost"
	@echo "Backend API:        http://backend.localhost"
	@echo "Traefik Dashboard:  http://traefik.localhost:8080"
	@echo "Mailpit:            http://mailpit.localhost"
	@echo ""

status:
	$(DOCKER_DEV) ps

# ============================================================
# 🧩 Backend Commands
# ============================================================

bash-backend:
	$(DOCKER_DEV) exec backend-app bash

migrate:
	$(DOCKER_DEV) exec backend-app php artisan migrate

seed:
	$(DOCKER_DEV) exec backend-app php artisan db:seed

composer-install:
	$(DOCKER_DEV) exec backend-app composer install

test-email:
	$(DOCKER_DEV) exec backend-app php artisan tinker --execute="\
		Mail::raw('Test email from ShiftPilot', function (\$$message) { \
			\$$message->to('test@shiftpilot.localhost')->subject('Test Email'); \
		}); \
		echo 'Test email sent! Check Mailpit at http://mailpit.localhost';"

# ============================================================
# 💻 Frontend Commands
# ============================================================

bash-frontend:
	$(DOCKER_DEV) exec frontend-app sh

frontend-install:
	$(DOCKER_DEV) exec frontend-app npm install

# ============================================================
# 🗄️ Database & Redis
# ============================================================

db-bash:
	$(DOCKER_DEV) exec backend-database mysql -u root -p

redis-cli:
	$(DOCKER_DEV) exec backend-redis redis-cli
