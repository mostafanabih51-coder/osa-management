<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->string('billing_type', 30)->default('monthly')->after('amount');
            $table->decimal('lesson_price', 10, 2)->nullable()->after('billing_type');
            $table->unsignedInteger('lesson_count')->nullable()->after('lesson_price');
            $table->string('service_type', 30)->default('group')->after('lesson_count');
        });
    }

    public function down(): void
    {
        Schema::table('subscriptions', function (Blueprint $table) {
            $table->dropColumn(['billing_type', 'lesson_price', 'lesson_count', 'service_type']);
        });
    }
};
