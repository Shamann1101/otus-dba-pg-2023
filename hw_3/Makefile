THIS_FILE := $(lastword $(MAKEFILE_LIST))
.PHONY: help
help h:
	make -pRrq  -f $(THIS_FILE) : 2>/dev/null | awk -v RS= -F: '/^# File/,/^# Finished Make data base/ {if ($$1 !~ "^[#.]") {print $$1}}' | sort | egrep -v -e '^[^[:alnum:]]' -e '^$@$$'

build-up bup:
	docker-compose up -d --build

up u:
	docker-compose up -d

down d:
	docker-compose down

down-up du: down up

postgres-bash pb:
	docker-compose exec postgres bash

seeds s:
	docker-compose cp initdb/entrypoint.sql postgres:/tmp
	source .env && \
	docker-compose exec postgres psql -U $${POSTGRES_USER} -f /tmp/entrypoint.sql -w

client c:
	docker-compose run --rm client

cleanup cl: down
	rm -rf ./tmp
