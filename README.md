# Laravel 12 + Docker (PHP-FPM 8.5, Nginx, PostgreSQL 18, Redis, Xdebug)

## 0. Совместимость

Окружение тестировалось **только на Ubuntu 24.04.3 LTS**.
Корректная работа на других ОС (Windows, macOS, другие дистрибутивы Linux) не гарантируется и может потребовать ручной доработки.

## 1. Подготовка `.env`

1. В корне репозитория создайте файл окружения на основе шаблона:
    ```bash
   cp .env.example .env
    ```
2. При необходимости измените базовые параметры (APP_NAME, APP_URL и т.п.).
3. Убедитесь, что в `.env` заданы переменные для базы данных, которые используются Makefile:

Пример:
```dotenv
DB_NAME=laravel_db
DB_USER=laravel_user
DB_PASSWORD=laravel_user_password
DB_HOST=postgres
DB_PORT=5432

REDIS_HOST=redis
REDIS_PORT=6379
```


Эти значения:
- используются при запуске PostgreSQL и Redis,
- подставляются в `.env` Laravel в процессе `make install`.

## 2. Стек и структура

Стек:
- PHP 8.5 (FPM) — контейнер `laravel_php`
- Nginx — контейнер `laravel_nginx`
- PostgreSQL 18 — контейнер `laravel_postgres`
- Redis — контейнер `laravel_redis`
- Laravel 12 — код в директории `src/`
- Makefile — набор утилитных команд

Основные файлы:
- compose.yaml — конфигурация Docker Compose
- docker/php/Dockerfile — образ PHP + необходимые расширения + Composer
- docker/nginx/default.conf — конфигурация Nginx
- Makefile — команды для управления окружением
- src/ — директория приложения Laravel (создаётся при установке)

## 3. Требования

На хосте должны быть установлены:
- Docker
- Docker Compose
- make
- git (для клонирования репозитория)

## 4. Установка проекта с нуля

Из корня проекта выполните:

```bash
  make install
```

Сценарий выполняет:
1. Останавливает контейнеры и удаляет их
2. Пересоздаёт директорию src/ с корректными правами.
3. Собирает и запускает контейнеры (php, nginx, postgres, redis).
4. Устанавливает Laravel 12 в src/.
5. Обновляет .env Laravel на основе переменных из корневого .env (DB_*, REDIS_*).
6. Настраивает Laravel для использования Redis (CACHE_STORE, SESSION_DRIVER, QUEUE_CONNECTION).
7. Проверяет подключение к базе данных.
8. Запускает миграции (php artisan migrate:fresh --force) и php artisan storage:link.

После успешной установки приложение доступно по адресу:

http://localhost

## 5. Основные команды Makefile

Запуск контейнеров:
```bash
  make up
```

Остановка и удаление контейнеров:
```bash
  make down
```

Пересборка образов:
```bash
  make build
```

Перезапуск всех контейнеров:
```bash
  make restart
```

Логи всех сервисов:
```bash
  make logs
```

Логи отдельных сервисов:
```bash
  make logs-nginx
```

```bash
  make logs-php
```

```bash
  make logs-db
```

```bash
  make logs-redis
```

Доступ в контейнер PHP:
```bash
  make shell
```

Доступ к PostgreSQL внутри контейнера:
```bash
  make shell-db
```

Доступ к Redis CLI:
```bash
  make redis-cli
```

Команды Composer внутри контейнера:
```bash
  make composer about
```

```bash
  make composer install
```

```bash
  make composer dump-autoload
```

Примеры команд Artisan внутри контейнера:

```bash
  make artisan route:list
```

```bash
  make artisan migrate
```

```bash
  make artisan cache:clear
```

Шорткаты для миграций:

```bash
  make migrate
```

```bash
  make fresh
```

## 6. Настройка Xdebug в PhpStorm

В образ PHP включен Xdebug 3 с поддержкой step debugging.

### Настройка сервера

1. Откройте **Settings** (Ctrl+Alt+S) → **PHP** → **Servers**
2. Нажмите **+** для добавления нового сервера
3. Заполните:
   - **Name**: `laravel-docker`
   - **Host**: `localhost`
   - **Port**: `80`
   - **Debugger**: `Xdebug`
4. Включите **Use path mappings**
5. В колонке **Absolute path on the server** для директории `src` укажите `/var/www/html`
6. Нажмите **OK**

### Запуск отладки

1. Установите breakpoint в коде (клик слева от номера строки)
2. Нажмите кнопку **Start Listening for PHP Debug Connections** (иконка телефона в панели инструментов)
3. Откройте страницу в браузере — PhpStorm автоматически остановится на breakpoint

### Отключение Xdebug

Для отключения Xdebug установите в `.env`:

```dotenv
XDEBUG_MODE=off
```

И перезапустите контейнеры: `make restart`

## 7. Полная очистка

Полный сброс окружения и кода приложения:

```bash
  make clean
```

Команда:
- останавливает контейнеры,
- удаляет volumes данного проекта,
- удаляет директорию src/.

> Используйте только если готовы удалить код и данные проекта!