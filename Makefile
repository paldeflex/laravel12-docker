ifeq (,$(wildcard .env))
$(error .env file is missing. Create .env in project root)
endif

-include .env

.PHONY: help install build up down stop restart logs shell composer artisan migrate fresh test clean redis-cli rebuild

help:
	@echo "Доступные команды:"
	@echo "  make install    - Полная установка проекта с нуля"
	@echo "  make build      - Сборка контейнеров"
	@echo "  make rebuild    - Пересборка контейнеров без кеша"
	@echo "  make up         - Запуск контейнеров"
	@echo "  make down       - Остановка и удаление контейнеров"
	@echo "  make stop       - Остановка контейнеров"
	@echo "  make restart    - Перезапуск контейнеров"
	@echo "  make logs       - Просмотр логов"
	@echo "  make shell      - Вход в PHP контейнер"
	@echo "  make composer   - Выполнить composer команду"
	@echo "  make artisan    - Выполнить artisan команду"
	@echo "  make migrate    - Запуск миграций"
	@echo "  make fresh      - Пересоздание БД с миграциями"
	@echo "  make clean      - Полная очистка"
	@echo "  make status     - Просмотреть активные контейнеры"
	@echo "  make logs-redis - Просмотр логов Redis"
	@echo "  make redis-cli  - Вход в Redis CLI"

install:
	@echo "Начинаем установку Laravel 12..."
	@docker compose down -v
	@sudo rm -rf src
	@mkdir -p src
	@sudo chown -R $${UID:-1000}:$${GID:-1000} src/
	@docker compose up -d --build
	@echo "Ожидание запуска PostgreSQL (5 сек)..."
	@sleep 5
	@echo "Установка Laravel..."
	@docker exec -it laravel_php composer create-project laravel/laravel:^12.0 . --no-interaction
	@echo "Настройка прав доступа..."
	@sudo chown -R $${UID:-1000}:$${GID:-1000} src/
	@echo "Генерация ключа приложения..."
	@docker exec laravel_php php artisan key:generate --force
	@echo "Настройка БД и Redis в .env..."
	@docker exec laravel_php bash -c "\
		cp .env .env.backup && \
		echo 'DB_CONNECTION=pgsql' > .env.tmp && \
		echo 'DB_HOST=$(DB_HOST)' >> .env.tmp && \
		echo 'DB_PORT=$(DB_PORT)' >> .env.tmp && \
		echo 'DB_DATABASE=$(DB_NAME)' >> .env.tmp && \
		echo 'DB_USERNAME=$(DB_USER)' >> .env.tmp && \
		echo 'DB_PASSWORD=$(DB_PASSWORD)' >> .env.tmp && \
		echo '' >> .env.tmp && \
		echo 'REDIS_HOST=$(REDIS_HOST)' >> .env.tmp && \
		echo 'REDIS_PORT=$(REDIS_PORT)' >> .env.tmp && \
		echo 'CACHE_STORE=redis' >> .env.tmp && \
		echo 'SESSION_DRIVER=redis' >> .env.tmp && \
		echo 'QUEUE_CONNECTION=redis' >> .env.tmp && \
		echo '' >> .env.tmp && \
		grep -v '^DB_' .env | grep -v '^REDIS_' | grep -v '^CACHE_STORE' | grep -v '^SESSION_DRIVER' | grep -v '^QUEUE_CONNECTION' >> .env.tmp && \
		mv .env.tmp .env"
	@echo "Проверка подключения к БД..."
	@docker exec laravel_php php -r "for(\$$i=0; \$$i<10; \$$i++) { \
		try { \
			new PDO('pgsql:host=$(DB_HOST);port=$(DB_PORT);dbname=$(DB_NAME)', '$(DB_USER)', '$(DB_PASSWORD)'); \
			echo 'Подключение к БД успешно!'.PHP_EOL; \
			exit(0); \
		} catch(Exception \$$e) { \
			echo 'Попытка '.(\$$i+1).'/10: '.\$$e->getMessage().PHP_EOL; \
			sleep(2); \
		} \
	} exit(1);"
	@echo "Запуск миграций..."
	@docker exec laravel_php php artisan migrate:fresh --force
	@docker exec laravel_php php artisan storage:link
	@echo "Установка завершена!"
	@echo "Проект доступен по адресу: http://localhost"

build:
	@docker compose build

rebuild:
	@docker compose build --no-cache

up:
	@docker compose up -d
	@echo "Контейнеры запущены"

down:
	@docker compose down
	@echo "Контейнеры остановлены и удалены"

stop:
	@docker compose stop
	@echo "Контейнеры остановлены"

restart:
	@docker compose restart
	@echo "Контейнеры перезапущены"

logs:
	@docker compose logs -f

logs-nginx:
	@docker compose logs -f nginx

logs-php:
	@docker compose logs -f php

logs-db:
	@docker compose logs -f postgres

logs-redis:
	@docker compose logs -f redis

shell:
	@docker exec -it laravel_php bash

shell-db:
	@docker exec -it laravel_postgres psql -U $(DB_USER) -d $(DB_NAME)

redis-cli:
	@docker exec -it laravel_redis redis-cli

composer:
	@docker exec -it laravel_php composer $(filter-out $@,$(MAKECMDGOALS))

artisan:
	@docker exec -it laravel_php php artisan $(filter-out $@,$(MAKECMDGOALS))

migrate:
	@docker exec laravel_php php artisan migrate

fresh:
	@docker exec laravel_php php artisan migrate:fresh --seed

clean:
	@printf "Это удалит все данные! Продолжить? [y/N] "
	@read ans; \
	if [ "$$ans" = "y" ] || [ "$$ans" = "Y" ]; then \
		docker compose down -v; \
		sudo rm -rf src/; \
		echo "Проект очищен"; \
	else \
		echo "Отмена очистки"; \
	fi

status:
	@docker compose ps

%:
	@:
