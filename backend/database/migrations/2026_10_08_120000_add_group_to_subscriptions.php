<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('subscriptions', 'group_id')) {
            Schema::table('subscriptions', function (Blueprint $table) {
                $table->foreignId('group_id')->nullable()->after('student_id')->constrained('groups')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('subscriptions', 'group_id')) {
            Schema::table('subscriptions', function (Blueprint $table) {
                $table->dropConstrainedForeignId('group_id');
            });
        }
    }
};
