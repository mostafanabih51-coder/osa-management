<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TeacherStudentSubject extends Model
{
    protected $table = 'teacher_student_subjects';
    protected $fillable = ['teacher_id', 'student_id', 'subject', 'teacher_rate', 'supervisor_id', 'status'];
    protected $casts = ['teacher_rate' => 'decimal:2'];

    public function teacher(): BelongsTo { return $this->belongsTo(Teacher::class); }
    public function student(): BelongsTo { return $this->belongsTo(Student::class); }
    public function supervisor(): BelongsTo { return $this->belongsTo(Supervisor::class); }
}
