<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('students', 'allow_lessons_with_debt')) {
            Schema::table('students', function (Blueprint $table) {
                $table->boolean('allow_lessons_with_debt')->default(true)->after('status');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('students', 'allow_lessons_with_debt')) {
            Schema::table('students', function (Blueprint $table) {
                $table->dropColumn('allow_lessons_with_debt');
            });
        }
    }
};
