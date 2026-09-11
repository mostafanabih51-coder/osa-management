<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\ApiController;
use App\Http\Controllers\FinanceController;
use App\Http\Controllers\LessonController;

Route::get('/health', fn () => ['status' => 'ok', 'service' => 'osa-api', 'version' => '1.2']);
Route::post('/login', [ApiController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', fn () => request()->user());
    Route::post('/logout', [ApiController::class, 'logout']);
    Route::get('/dashboard', [ApiController::class, 'dashboard']);

    Route::apiResource('students', ApiController::class)->only(['index', 'store', 'show', 'update', 'destroy']);
    Route::get('/teachers', [ApiController::class, 'teachers']);
    Route::post('/teachers', [ApiController::class, 'storeTeacher']);
    Route::get('/schedules', [ApiController::class, 'schedules']);
    Route::post('/schedules', [ApiController::class, 'storeSchedule']);
    Route::get('/attendance', [ApiController::class, 'attendance']);
    Route::post('/attendance', [ApiController::class, 'storeAttendance']);
    Route::get('/subscriptions', [ApiController::class, 'subscriptions']);
    Route::post('/subscriptions', [ApiController::class, 'storeSubscription']);

    Route::middleware('admin')->group(function () {
        Route::get('/payments', [ApiController::class, 'payments']);
        Route::post('/payments', [ApiController::class, 'storePayment']);
        Route::get('/expenses', [ApiController::class, 'expenses']);
        Route::post('/expenses', [ApiController::class, 'storeExpense']);
        Route::get('/teacher-dues', [ApiController::class, 'teacherDues']);
        Route::get('/reports/financial', [ApiController::class, 'financialReport']);

        Route::get('/finance/teacher-dues', [FinanceController::class, 'teacherDues']);
        Route::get('/finance/supervisor-dues', [FinanceController::class, 'supervisorDues']);
        Route::get('/finance/bonuses', [FinanceController::class, 'bonuses']);
        Route::post('/finance/bonuses', [FinanceController::class, 'storeBonus']);
        Route::get('/finance/withdrawal-settings', [FinanceController::class, 'withdrawalSettings']);
        Route::post('/finance/withdrawal-settings', [FinanceController::class, 'updateWithdrawalSetting']);
        Route::get('/finance/withdrawals', [FinanceController::class, 'withdrawals']);
        Route::post('/finance/withdrawals', [FinanceController::class, 'storeWithdrawal']);
        Route::put('/finance/withdrawals/{withdrawal}', [FinanceController::class, 'updateWithdrawal']);
        Route::get('/finance/summary', [FinanceController::class, 'summary']);
        Route::post('/finance/dues/{type}/{due}/pay', [FinanceController::class, 'payDue']);
    });
});

Route::middleware(['auth:sanctum'])->group(function () {
    Route::get('/lessons', [LessonController::class, 'index']);
    Route::post('/lessons', [LessonController::class, 'store']);
    Route::get('/lessons/{lesson}', [LessonController::class, 'show']);
    Route::put('/lessons/{lesson}', [LessonController::class, 'update']);
    Route::patch('/lessons/{lesson}', [LessonController::class, 'update']);
    Route::delete('/lessons/{lesson}', [LessonController::class, 'destroy']);
    Route::post('/lessons/{lesson}/complete', [LessonController::class, 'complete']);
    Route::post('/lessons/{lesson}/cancel', [LessonController::class, 'cancel']);
});
