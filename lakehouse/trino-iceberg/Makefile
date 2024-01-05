.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Up env

.PHONY: start-minio
start-minio: ## start minio
	@echo "Up minio"
	docker compose -f docker-compose-minio.yml up -d

.PHONY: start-dependencies
start-dependencies: ## Init env
	@echo "Init env"
	docker compose -f docker-compose-init.yml up

.PHONY: start-hive-metastore
start-hive-metastore: ## Up hive-metastore
	@echo "Up hive-metastore"
	docker compose -f docker-compose-hive.yml up -d

.PHONY: start-trino
start-trino: ## Up trino
	@echo "Up trino"
	docker compose -f docker-compose-trino.yml up -d


.PHONY: start
start: start-minio start-dependencies start-hive-metastore start-trino ## Up env

##@ Down env

.PHONY: down-minio
down-minio: ## Down minio
	@echo "Down minio"
	docker compose -f docker-compose-minio.yml down -v

.PHONY: down-dependencies
down-dependencies: ## Down dependencies
	@echo "Down dependencies"
	docker compose -f docker-compose-init.yml down -v

.PHONY: down-hive-metastore
down-hive-metastore: ## Down hive-metastore
	@echo "Down hive-metastore"
	docker compose -f docker-compose-hive.yml down -v

.PHONY: down-trino
down-trino: ## Down trino
	@echo "Down trino"
	docker compose -f docker-compose-trino.yml down -v

.PHONY: down
down: down-trino down-hive-metastore down-dependencies down-minio ## Down env
