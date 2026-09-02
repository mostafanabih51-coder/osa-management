<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class LessonSetting extends Model
{
    protected $fillable = [
        'name',
        'lesson_type',
        'teacher_rate',
        'supervisor_rate',
        'active',
        'notes',
    ];

    protected $casts = [
        'teacher_rate' => 'decimal:2',
        'supervisor_rate' => 'decimal:2',
        'active' => 'boolean',
    ];
}
