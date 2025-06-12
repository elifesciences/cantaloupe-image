.PHONY: dev
dev: build
	docker compose up --wait

.PHONY: build
build:
	docker compose build

