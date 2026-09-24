<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('teacher_student_subjects', 'lesson_price')) {
            Schema::table('teacher_student_subjects', function (Blueprint $table) {
                $table->decimal('lesson_price', 10, 2)->nullable()->after('subject');
            });
        }

        DB::statement("UPDATE teacher_student_subjects SET lesson_price = CASE WHEN academy_percentage > 0 AND academy_percentage < 100 THEN ROUND(teacher_rate / (1 - academy_percentage / 100), 2) ELSE teacher_rate END WHERE lesson_price IS NULL");
    }

    public function down(): void
    {
        if (Schema::hasColumn('teacher_student_subjects', 'lesson_price')) {
            Schema::table('teacher_student_subjects', fn (Blueprint $table) => $table->dropColumn('lesson_price'));
        }
    }
};