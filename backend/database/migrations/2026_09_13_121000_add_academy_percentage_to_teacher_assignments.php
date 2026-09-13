<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        if (!Schema::hasColumn('teacher_student_subjects', 'academy_percentage')) {
            Schema::table('teacher_student_subjects', function (Blueprint $table) {
                $table->decimal('academy_percentage', 5, 2)->default(0)->after('teacher_rate');
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('teacher_student_subjects', 'academy_percentage')) {
            Schema::table('teacher_student_subjects', fn (Blueprint $table) => $table->dropColumn('academy_percentage'));
        }
    }
};
