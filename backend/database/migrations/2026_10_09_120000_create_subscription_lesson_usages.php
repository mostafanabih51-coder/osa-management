<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasTable('subscription_lesson_usages')) {
            Schema::create('subscription_lesson_usages', function (Blueprint $table) {
                $table->id();
                $table->foreignId('subscription_id')->constrained('subscriptions')->cascadeOnDelete();
                $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
                $table->foreignId('lesson_id')->constrained('lessons')->restrictOnDelete();
                $table->date('lesson_date');
                $table->string('service_type', 20);
                $table->timestamps();
                $table->unique(['lesson_id', 'student_id']);
                $table->index(['subscription_id', 'lesson_date']);
                $table->index(['student_id', 'lesson_date']);
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasTable('subscription_lesson_usages')) {
            Schema::dropIfExists('subscription_lesson_usages');
        }
    }
};
