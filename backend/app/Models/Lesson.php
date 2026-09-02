<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Lesson extends Model
{
    protected $fillable = [
        'type',
        'teacher_id',
        'supervisor_id',
        'group_id',
        'student_id',
        'subject',
        'starts_at',
        'ends_at',
        'zoom_url',
        'status',
        'teacher_rate',
        'supervisor_rate',
        'teacher_due',
        'supervisor_due',
        'completed_at',
        'notes',
    ];

    protected $casts = [
        'starts_at' => 'datetime',
        'ends_at' => 'datetime',
        'completed_at' => 'datetime',
        'teacher_rate' => 'decimal:2',
        'supervisor_rate' => 'decimal:2',
        'teacher_due' => 'decimal:2',
        'supervisor_due' => 'decimal:2',
    ];

    public function teacher(): BelongsTo
    {
        return $this->belongsTo(Teacher::class);
    }

    public function supervisor(): BelongsTo
    {
        return $this->belongsTo(Supervisor::class);
    }

    public function group(): BelongsTo
    {
        return $this->belongsTo(Group::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    /*
     * Financial record generated for this lesson.
     */
    public function teacherDue(): HasOne
    {
        return $this->hasOne(
            TeacherLessonDue::class,
            'lesson_id'
        );
    }

    /*
     * Financial record generated for the supervisor.
     */
    public function supervisorDue(): HasOne
    {
        return $this->hasOne(
            SupervisorDue::class,
            'lesson_id'
        );
    }
}
