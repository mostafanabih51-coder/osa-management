<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('student_subjects', 'plan_type')) {
            Schema::table('student_subjects', function (Blueprint $table) {
                $table->string('plan_type', 20)->default('monthly')->after('plan_month');
            });
        }
        if (!Schema::hasColumn('attendance', 'lesson_id')) {
            Schema::table('attendance', function (Blueprint $table) {
                $table->foreignId('lesson_id')->nullable()->after('schedule_id')->constrained('lessons')->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('attendance', 'lesson_id')) {
            Schema::table('attendance', function (Blueprint $table) {
                $table->dropConstrainedForeignId('lesson_id');
            });
        }
        if (Schema::hasColumn('student_subjects', 'plan_type')) {
            Schema::table('student_subjects', function (Blueprint $table) {
                $table->dropColumn('plan_type');
            });
        }
    }
};
