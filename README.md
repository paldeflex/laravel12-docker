# Laravel 12 + Docker (PHP-FPM 8.4, Nginx, PostgreSQL, Redis, Xdebug)

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

# UID/GID пользователя хоста (для корректных прав на файлы)
# Узнать свои значения: id -u и id -g
UID=1000
GID=1000
```


Эти значения:
- используются при запуске PostgreSQL и Redis,
- подставляются в `.env` Laravel в процессе `make install`.

## 2. Стек и структура

Стек:
- PHP 8.4 (FPM) — контейнер `laravel_php`
- Nginx 1.27 (Alpine) — контейнер `laravel_nginx`
- PostgreSQL 17 (Alpine) — контейнер `laravel_postgres`
- Redis 7 (Alpine) — контейнер `laravel_redis`
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
5. Генерирует ключ приложения (APP_KEY).
6. Обновляет .env Laravel на основе переменных из корневого .env (DB_*, REDIS_*).
7. Настраивает Laravel для использования Redis (CACHE_STORE, SESSION_DRIVER, QUEUE_CONNECTION).
8. Проверяет подключение к базе данных.
9. Запускает миграции (php artisan migrate:fresh --force) и php artisan storage:link.

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

Пересборка образов без кеша (после изменений в Dockerfile):
```bash
  make rebuild
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

В образ PHP включен Xdebug 3 с поддержкой step debugging в режиме trigger.

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
3. Активируйте отладку одним из способов:
   - Установите расширение браузера **Xdebug Helper** и включите Debug режим
   - Или добавьте `?XDEBUG_SESSION=1` к URL
   - Или используйте cookie `XDEBUG_SESSION=PHPSTORM`
4. Откройте страницу в браузере — PhpStorm остановится на breakpoint

### Режим trigger vs always-on

По умолчанию Xdebug работает в режиме `trigger` — отладка активируется только при наличии триггера (расширение браузера, параметр URL или cookie). Это повышает производительность, так как без триггера Xdebug не пытается подключиться к IDE.

Если вы хотите, чтобы отладка запускалась автоматически при каждом запросе, измените в `docker/php/xdebug.ini`:

```ini
xdebug.start_with_request=yes
```

И пересоберите контейнеры: `make rebuild`

### Отключение Xdebug

Для отключения Xdebug установите в `.env`:

```dotenv
XDEBUG_MODE=off
```

И перезапустите контейнеры: `make restart`

## 7. Оптимизации Docker-образа

Образ PHP оптимизирован для минимального размера:
- Используется `--no-install-recommends` при установке пакетов
- Сборочные зависимости удаляются после компиляции расширений
- Кеш apt очищается
- Composer зафиксирован на версии 2.x

## 8. Полная очистка

Полный сброс окружения и кода приложения:

```bash
  make clean
```

Команда:
- останавливает контейнеры,
- удаляет volumes данного проекта,
- удаляет директорию src/.

> Используйте только если готовы удалить код и данные проекта!
