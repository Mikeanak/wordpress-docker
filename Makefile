cleanup: ## Stop and remove containers, remove db volume
	docker compose -f local_setup.yaml down --volumes --remove-orphans || true
	docker volume rm $$(docker volume ls -q --filter name=wordpress-docker_db-data) 2>/dev/null || true
# Default
.DEFAULT_GOAL := help

help: ## Show this help message
	@echo "Available make targets:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## ' Makefile | \
		awk -F ':|##' '{ printf "  \033[36m%-20s\033[0m %s\n", $$1, $$3 }'


# Use docker buildx platform format: os/arch
PLATFORM ?= linux/amd64


build: ## Build the WordPress container (override with PLATFORM)
	docker buildx build --load --platform $(PLATFORM) -t wordpress-local .


db: ## Build the MySQL container (override with PLATFORM)
	docker buildx build --load --platform $(PLATFORM) -f Dockerfile.mysql -t mysql-local .

test: ## Run local test setup (builds containers, generates creds, compose up)
	./scripts/test_setup.sh
