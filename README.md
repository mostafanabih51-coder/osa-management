# Online School Academy Management System v1.1

## Structure
- `backend/` Laravel 11 + Sanctum API
- `mobile/` Flutter management application

## cPanel deployment
1. Upload `backend` outside the public web root if possible.
2. Set the subdomain document root to `backend/public`.
3. In cPanel Terminal: `cd /path/to/backend`
4. Run: `composer install --no-dev --optimize-autoloader`
5. Copy `.env.example` to `.env` and set MySQL credentials.
6. Run: `php artisan key:generate`
7. Run: `php artisan migrate --seed`
8. Run: `php artisan storage:link`
9. Test: `https://admin.muteatalriyadiaat.com/` and `/api/health`.

## Initial admin
Email: `admin@onlineschoolacademy.com`
Password: `ChangeMe123!`
Change this immediately after first login.
