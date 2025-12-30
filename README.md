# Laravel 12 + Docker (PHP-FPM 8.4, Nginx, PostgreSQL 18, Redis)

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
- PHP 8.4 (FPM) — контейнер `laravel_php`
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

## 6. Настройка Xdebug и PhpStorm

В образ PHP включен Xdebug 3 с поддержкой step debugging.

### Переменные окружения

В файле `.env` можно настроить следующие параметры:

```dotenv
# Mode: off, develop, coverage, debug, gcstats, profile, trace
XDEBUG_MODE=debug
XDEBUG_CLIENT_HOST=host.docker.internal
XDEBUG_CLIENT_PORT=9003
XDEBUG_SERVER_NAME=laravel-docker
```

- `XDEBUG_MODE=off` — отключает Xdebug (рекомендуется для production)
- `XDEBUG_MODE=debug` — включает step debugging
- `XDEBUG_MODE=coverage` — для code coverage (PHPUnit)

### Настройка PhpStorm

#### Шаг 1: Настройка PHP Interpreter

1. Откройте **Settings** (Ctrl+Alt+S) → **PHP**
2. Нажмите **...** рядом с **CLI Interpreter**
3. Нажмите **+** → **From Docker, Vagrant, VM, WSL, Remote...**
4. Выберите **Docker Compose**
5. В **Configuration file(s)** укажите путь к `compose.yaml`
6. В **Service** выберите `php`
7. Нажмите **OK**

#### Шаг 2: Настройка Debug

1. Откройте **Settings** → **PHP** → **Debug**
2. В секции **Xdebug** проверьте:
   - **Debug port**: `9003`
   - Включена галочка **Can accept external connections**
3. Нажмите **Apply**

#### Шаг 3: Настройка сервера

1. Откройте **Settings** → **PHP** → **Servers**
2. Нажмите **+** для добавления нового сервера
3. Заполните:
   - **Name**: `laravel-docker` (должно совпадать с `XDEBUG_SERVER_NAME` в `.env`)
   - **Host**: `localhost`
   - **Port**: `80`
   - **Debugger**: `Xdebug`
4. Включите **Use path mappings**
5. В колонке **Absolute path on the server** для директории `src` укажите `/var/www/html`
6. Нажмите **OK**

#### Шаг 4: Запуск отладки

1. Установите breakpoint в коде (клик слева от номера строки)
2. Нажмите кнопку **Start Listening for PHP Debug Connections** (иконка телефона в панели инструментов)
3. Откройте страницу в браузере — PhpStorm автоматически остановится на breakpoint

### Отладка через браузер

Для ручного запуска отладки можно использовать расширение браузера:
- Chrome: [Xdebug Helper](https://chrome.google.com/webstore/detail/xdebug-helper/eadndfjplgieldjbigjakmdgkmoaaaoc)
- Firefox: [Xdebug Helper](https://addons.mozilla.org/en-US/firefox/addon/xdebug-helper-for-firefox/)

В настройках расширения укажите IDE key: `PHPSTORM`

### Отладка CLI-команд (Artisan)

Для отладки artisan-команд используйте:

```bash
make shell
php artisan your:command
```

Xdebug автоматически подключится к PhpStorm при выполнении команды.

### Отключение Xdebug

Для повышения производительности в production или при обычной разработке:

1. В файле `.env` установите:
   ```dotenv
   XDEBUG_MODE=off
   ```

2. Перезапустите контейнеры:
   ```bash
   make restart
   ```

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