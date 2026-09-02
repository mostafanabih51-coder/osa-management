<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ApiController;

Route::get('/health', fn () => [
    'status' => 'ok',
    'service' => 'osa-api',
    'version' => '1.1',
]);

Route::post('/login', [ApiController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {

    // Current authenticated user
    Route::get('/user', fn () => request()->user());

    // Authentication
    Route::post('/logout', [ApiController::class, 'logout']);

    // Dashboard
    Route::get('/dashboard', [ApiController::class, 'dashboard']);

    // Students
    Route::apiResource('students', ApiController::class)
        ->only(['index', 'store', 'show', 'update', 'destroy']);

    // Teachers
    Route::get('/teachers', [ApiController::class, 'teachers']);
    Route::post('/teachers', [ApiController::class, 'storeTeacher']);

    // Schedules
    Route::get('/schedules', [ApiController::class, 'schedules']);
    Route::post('/schedules', [ApiController::class, 'storeSchedule']);

    // Attendance
    Route::get('/attendance', [ApiController::class, 'attendance']);
    Route::post('/attendance', [ApiController::class, 'storeAttendance']);

    // Subscriptions
    Route::get('/subscriptions', [ApiController::class, 'subscriptions']);
    Route::post('/subscriptions', [ApiController::class, 'storeSubscription']);

    // Payments
    Route::get('/payments', [ApiController::class, 'payments']);
    Route::post('/payments', [ApiController::class, 'storePayment']);

    // Expenses
    Route::get('/expenses', [ApiController::class, 'expenses']);
    Route::post('/expenses', [ApiController::class, 'storeExpense']);

    // Teacher dues
    Route::get('/teacher-dues', [ApiController::class, 'teacherDues']);

    // Financial reports
    Route::get('/reports/financial', [ApiController::class, 'financialReport']);
});

/*
|--------------------------------------------------------------------------
| New Lessons System
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    Route::get('/lessons', [\App\Http\Controllers\LessonController::class, 'index']);
    Route::post('/lessons', [\App\Http\Controllers\LessonController::class, 'store']);
    Route::get('/lessons/{lesson}', [\App\Http\Controllers\LessonController::class, 'show']);
    Route::put('/lessons/{lesson}', [\App\Http\Controllers\LessonController::class, 'update']);
    Route::patch('/lessons/{lesson}', [\App\Http\Controllers\LessonController::class, 'update']);
    Route::delete('/lessons/{lesson}', [\App\Http\Controllers\LessonController::class, 'destroy']);

    Route::post('/lessons/{lesson}/complete', [\App\Http\Controllers\LessonController::class, 'complete']);
    Route::post('/lessons/{lesson}/cancel', [\App\Http\Controllers\LessonController::class, 'cancel']);

});

/*
|--------------------------------------------------------------------------
| Finance System
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->group(function () {

    // Teacher dues
    Route::get('/finance/teacher-dues', [\App\Http\Controllers\FinanceController::class, 'teacherDues']);

    // Supervisor dues
    Route::get('/finance/supervisor-dues', [\App\Http\Controllers\FinanceController::class, 'supervisorDues']);

    // Bonuses
    Route::get('/finance/bonuses', [\App\Http\Controllers\FinanceController::class, 'bonuses']);
    Route::post('/finance/bonuses', [\App\Http\Controllers\FinanceController::class, 'storeBonus']);

    // Withdrawal settings
    Route::get('/finance/withdrawal-settings', [\App\Http\Controllers\FinanceController::class, 'withdrawalSettings']);
    Route::post('/finance/withdrawal-settings', [\App\Http\Controllers\FinanceController::class, 'updateWithdrawalSetting']);

    // Withdrawal requests
    Route::get('/finance/withdrawals', [\App\Http\Controllers\FinanceController::class, 'withdrawals']);
    Route::post('/finance/withdrawals', [\App\Http\Controllers\FinanceController::class, 'storeWithdrawal']);
    Route::put('/finance/withdrawals/{withdrawal}', [\App\Http\Controllers\FinanceController::class, 'updateWithdrawal']);

    // Finance summary
    Route::get('/finance/summary', [\App\Http\Controllers\FinanceController::class, 'summary']);

});
