<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('student_subjects')) {
            Schema::create('student_subjects', function (Blueprint $table) {
                $table->id();
                $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
                $table->string('subject', 150);
                $table->timestamps();
                $table->unique(['student_id', 'subject']);
                $table->index('subject');
            });
        }

        if (!Schema::hasTable('teacher_student_subjects')) {
            Schema::create('teacher_student_subjects', function (Blueprint $table) {
                $table->id();
                $table->foreignId('teacher_id')->constrained('teachers')->cascadeOnDelete();
                $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
                $table->string('subject', 150);
                $table->decimal('teacher_rate', 10, 2)->default(0);
                $table->foreignId('supervisor_id')->nullable()->constrained('supervisors')->nullOnDelete();
                $table->string('status', 50)->default('active');
                $table->timestamps();
                $table->unique(['teacher_id', 'student_id', 'subject']);
                $table->index(['student_id', 'subject']);
            });
        }

        foreach (['teacher_id', 'supervisor_id', 'teacher_rate'] as $column) {
            if (!Schema::hasColumn('groups', $column)) {
                Schema::table('groups', function (Blueprint $table) use ($column) {
                    if ($column === 'teacher_id') {
                        $table->foreignId('teacher_id')->nullable()->after('id')->constrained('teachers')->nullOnDelete();
                    } elseif ($column === 'supervisor_id') {
                        $table->foreignId('supervisor_id')->nullable()->after('teacher_id')->constrained('supervisors')->nullOnDelete();
                    } else {
                        $table->decimal('teacher_rate', 10, 2)->default(0)->after('subject');
                    }
                });
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('groups', 'supervisor_id')) {
            Schema::table('groups', fn (Blueprint $table) => $table->dropForeign(['supervisor_id']));
            Schema::table('groups', fn (Blueprint $table) => $table->dropColumn('supervisor_id'));
        }
        if (Schema::hasColumn('groups', 'teacher_id')) {
            Schema::table('groups', fn (Blueprint $table) => $table->dropForeign(['teacher_id']));
            Schema::table('groups', fn (Blueprint $table) => $table->dropColumn('teacher_id'));
        }
        if (Schema::hasColumn('groups', 'teacher_rate')) {
            Schema::table('groups', fn (Blueprint $table) => $table->dropColumn('teacher_rate'));
        }
        Schema::dropIfExists('teacher_student_subjects');
        Schema::dropIfExists('student_subjects');
    }
};
