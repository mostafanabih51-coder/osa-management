<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasTable('subscription_reminders')) {
            Schema::create('subscription_reminders', function (Blueprint $table) {
                $table->id();
                $table->foreignId('subscription_id')->constrained('subscriptions')->cascadeOnDelete();
                $table->string('reminder_type', 30);
                $table->string('cycle_key', 32);
                $table->string('title', 255);
                $table->text('message');
                $table->date('due_on')->nullable();
                $table->timestamp('read_at')->nullable();
                $table->timestamps();
                $table->unique(['subscription_id', 'reminder_type', 'cycle_key']);
                $table->index(['read_at', 'created_at']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('subscription_reminders');
    }
};
