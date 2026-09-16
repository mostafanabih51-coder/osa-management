<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('student_subjects')) {
            Schema::table('student_subjects', function (Blueprint $table) {
                if (!Schema::hasColumn('student_subjects', 'monthly_lessons')) $table->unsignedInteger('monthly_lessons')->nullable()->after('subject');
                if (!Schema::hasColumn('student_subjects', 'completed_lessons')) $table->unsignedInteger('completed_lessons')->default(0)->after('monthly_lessons');
                if (!Schema::hasColumn('student_subjects', 'plan_month')) $table->string('plan_month', 7)->nullable()->after('completed_lessons');
            });
        }

        if (!Schema::hasTable('student_evaluations')) {
            Schema::create('student_evaluations', function (Blueprint $table) {
                $table->id();
                $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
                $table->foreignId('teacher_id')->nullable()->constrained('teachers')->nullOnDelete();
                $table->foreignId('supervisor_id')->nullable()->constrained('supervisors')->nullOnDelete();
                $table->foreignId('lesson_id')->nullable()->constrained('lessons')->nullOnDelete();
                $table->string('subject', 150)->nullable();
                $table->decimal('score', 5, 2)->nullable();
                $table->string('title', 255)->nullable();
                $table->text('notes')->nullable();
                $table->date('evaluation_date');
                $table->timestamps();
                $table->index(['student_id', 'evaluation_date']);
            });
        }

        if (!Schema::hasTable('student_resources')) {
            Schema::create('student_resources', function (Blueprint $table) {
                $table->id();
                $table->foreignId('student_id')->constrained('students')->cascadeOnDelete();
                $table->foreignId('teacher_id')->nullable()->constrained('teachers')->nullOnDelete();
                $table->foreignId('lesson_id')->nullable()->constrained('lessons')->nullOnDelete();
                $table->string('type', 30)->default('link');
                $table->string('title', 255);
                $table->text('url')->nullable();
                $table->text('description')->nullable();
                $table->date('published_on')->nullable();
                $table->timestamps();
                $table->index(['student_id', 'type']);
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('student_resources');
        Schema::dropIfExists('student_evaluations');
        if (Schema::hasTable('student_subjects')) {
            foreach (['plan_month','completed_lessons','monthly_lessons'] as $column) {
                if (Schema::hasColumn('student_subjects', $column)) Schema::table('student_subjects', fn(Blueprint $table) => $table->dropColumn($column));
            }
        }
    }
};
