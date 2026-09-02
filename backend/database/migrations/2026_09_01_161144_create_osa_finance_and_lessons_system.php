<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        /*
        |--------------------------------------------------------------------------
        | Groups
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('groups')) {
            Schema::create('groups', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->string('grade', 100)->nullable();
                $table->string('subject', 100)->nullable();
                $table->string('status', 50)->default('active');
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Group Students
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('group_students')) {
            Schema::create('group_students', function (Blueprint $table) {
                $table->id();

                $table->foreignId('group_id')
                    ->constrained('groups')
                    ->cascadeOnDelete();

                $table->foreignId('student_id')
                    ->constrained('students')
                    ->cascadeOnDelete();

                $table->timestamps();

                $table->unique(['group_id', 'student_id']);
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Lesson Settings
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('lesson_settings')) {
            Schema::create('lesson_settings', function (Blueprint $table) {
                $table->id();

                $table->string('name', 150);
                $table->string('lesson_type', 50);

                $table->decimal('teacher_rate', 10, 2)->default(0);
                $table->decimal('supervisor_rate', 10, 2)->default(0);

                $table->boolean('active')->default(true);
                $table->text('notes')->nullable();

                $table->timestamps();

                // Intentionally no index here.
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Supervisors
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('supervisors')) {
            Schema::create('supervisors', function (Blueprint $table) {
                $table->id();

                $table->foreignId('user_id')
                    ->nullable()
                    ->unique()
                    ->constrained('users')
                    ->nullOnDelete();

                $table->string('name');
                $table->string('phone')->nullable();
                $table->string('email')->nullable();
                $table->string('status', 50)->default('active');

                $table->timestamps();
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Teacher User Account
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasColumn('teachers', 'user_id')) {
            Schema::table('teachers', function (Blueprint $table) {
                $table->foreignId('user_id')
                    ->nullable()
                    ->unique()
                    ->after('id')
                    ->constrained('users')
                    ->nullOnDelete();
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Lessons
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('lessons')) {
            Schema::create('lessons', function (Blueprint $table) {
                $table->id();

                /*
                | group = group lesson
                | private = individual lesson
                */
                $table->string('type', 50);

                $table->foreignId('teacher_id')
                    ->constrained('teachers');

                $table->foreignId('supervisor_id')
                    ->nullable()
                    ->constrained('supervisors')
                    ->nullOnDelete();

                $table->foreignId('group_id')
                    ->nullable()
                    ->constrained('groups')
                    ->nullOnDelete();

                $table->foreignId('student_id')
                    ->nullable()
                    ->constrained('students')
                    ->nullOnDelete();

                $table->string('subject', 150);

                $table->dateTime('starts_at');
                $table->dateTime('ends_at');

                $table->text('zoom_url')->nullable();

                /*
                | scheduled / completed / cancelled
                */
                $table->string('status', 50)->default('scheduled');

                /*
                |--------------------------------------------------------------------------
                | Financial Snapshot
                |--------------------------------------------------------------------------
                */
                $table->decimal('teacher_rate', 10, 2)->default(0);
                $table->decimal('supervisor_rate', 10, 2)->default(0);

                $table->decimal('teacher_due', 10, 2)->default(0);
                $table->decimal('supervisor_due', 10, 2)->default(0);

                $table->dateTime('completed_at')->nullable();

                $table->text('notes')->nullable();

                $table->timestamps();

                /*
                | Keep only the most useful indexes.
                | No type/status composite index because the hosting
                | database has a strict maximum index length.
                */
                $table->index(['teacher_id', 'starts_at']);
                $table->index(['supervisor_id', 'starts_at']);
                $table->index(['group_id', 'starts_at']);
                $table->index(['student_id', 'starts_at']);
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Teacher Lesson Dues
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('teacher_lesson_dues')) {
            Schema::create('teacher_lesson_dues', function (Blueprint $table) {
                $table->id();

                $table->foreignId('teacher_id')
                    ->constrained('teachers');

                $table->foreignId('lesson_id')
                    ->constrained('lessons')
                    ->cascadeOnDelete();

                $table->decimal('amount', 10, 2);
                $table->decimal('paid_amount', 10, 2)->default(0);

                $table->string('status', 50)->default('unpaid');

                $table->timestamps();

                $table->unique(['teacher_id', 'lesson_id']);
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Supervisor Lesson Dues
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('supervisor_dues')) {
            Schema::create('supervisor_dues', function (Blueprint $table) {
                $table->id();

                $table->foreignId('supervisor_id')
                    ->constrained('supervisors');

                $table->foreignId('lesson_id')
                    ->constrained('lessons')
                    ->cascadeOnDelete();

                $table->decimal('amount', 10, 2);
                $table->decimal('paid_amount', 10, 2)->default(0);

                $table->string('status', 50)->default('unpaid');

                $table->timestamps();

                $table->unique(['supervisor_id', 'lesson_id']);
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Bonuses
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('bonuses')) {
            Schema::create('bonuses', function (Blueprint $table) {
                $table->id();

                /*
                | teacher / supervisor
                */
                $table->string('recipient_type', 50);

                $table->unsignedBigInteger('recipient_id');

                /*
                | Human-readable bonus name.
                | Example:
                | Attendance Bonus
                | Excellent Performance
                | Ramadan Bonus
                */
                $table->string('name', 150);

                $table->decimal('amount', 10, 2);

                $table->date('bonus_date');

                $table->text('notes')->nullable();

                $table->foreignId('created_by')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete();

                $table->timestamps();

                /*
                | No composite index here because of the hosting
                | database index-length limitation.
                */
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Withdrawal Settings
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('withdrawal_settings')) {
            Schema::create('withdrawal_settings', function (Blueprint $table) {
                $table->id();

                /*
                | teacher / supervisor
                */
                $table->string('recipient_type', 50)->unique();

                /*
                | Administration controls this.
                */
                $table->boolean('enabled')->default(false);

                /*
                | Minimum amount required before withdrawal.
                */
                $table->decimal('minimum_amount', 10, 2)->default(0);

                $table->timestamps();
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Withdrawal Requests
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasTable('withdrawal_requests')) {
            Schema::create('withdrawal_requests', function (Blueprint $table) {
                $table->id();

                /*
                | teacher / supervisor
                */
                $table->string('recipient_type', 50);

                $table->unsignedBigInteger('recipient_id');

                $table->decimal('amount', 10, 2);

                /*
                | pending / approved / rejected / paid
                */
                $table->string('status', 50)->default('pending');

                $table->text('notes')->nullable();

                $table->foreignId('approved_by')
                    ->nullable()
                    ->constrained('users')
                    ->nullOnDelete();

                $table->dateTime('approved_at')->nullable();
                $table->dateTime('paid_at')->nullable();

                $table->timestamps();

                /*
                | Simple indexes only.
                */
                $table->index('recipient_type');
                $table->index('recipient_id');
                $table->index('status');
            });
        }

        /*
        |--------------------------------------------------------------------------
        | Student User Account
        |--------------------------------------------------------------------------
        */
        if (!Schema::hasColumn('students', 'user_id')) {
            Schema::table('students', function (Blueprint $table) {
                $table->foreignId('user_id')
                    ->nullable()
                    ->unique()
                    ->after('id')
                    ->constrained('users')
                    ->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        /*
        |--------------------------------------------------------------------------
        | This migration is an upgrade to an existing production system.
        | Do not automatically destroy academy data.
        |--------------------------------------------------------------------------
        */

        if (Schema::hasColumn('students', 'user_id')) {
            Schema::table('students', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
                $table->dropUnique(['students_user_id_unique']);
                $table->dropColumn('user_id');
            });
        }

        if (Schema::hasColumn('teachers', 'user_id')) {
            Schema::table('teachers', function (Blueprint $table) {
                $table->dropForeign(['user_id']);
                $table->dropUnique(['teachers_user_id_unique']);
                $table->dropColumn('user_id');
            });
        }

        Schema::dropIfExists('withdrawal_requests');
        Schema::dropIfExists('withdrawal_settings');
        Schema::dropIfExists('bonuses');
        Schema::dropIfExists('supervisor_dues');
        Schema::dropIfExists('teacher_lesson_dues');
        Schema::dropIfExists('lessons');
        Schema::dropIfExists('supervisors');
        Schema::dropIfExists('lesson_settings');
        Schema::dropIfExists('group_students');
        Schema::dropIfExists('groups');
    }
};
