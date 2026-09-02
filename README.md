# OSA Management

Online School Academy Management System.

## Project Structure

- `backend/` — Laravel API backend with Sanctum authentication.
- `mobile/` — Flutter management application.

## Backend

The backend runs on Laravel and provides the API used by the Flutter management app.

### cPanel deployment

1. Set the subdomain document root to `backend/public`.
2. In cPanel Terminal:

```bash
cd /path/to/backend
composer install --no-dev --optimize-autoloader
