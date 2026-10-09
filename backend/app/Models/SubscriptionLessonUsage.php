<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionLessonUsage extends Model
{
    protected $fillable = ['subscription_id', 'student_id', 'lesson_id', 'lesson_date', 'service_type'];

    protected $casts = ['lesson_date' => 'date:Y-m-d'];

    public function subscription(): BelongsTo { return $this->belongsTo(Subscription::class); }
    public function student(): BelongsTo { return $this->belongsTo(Student::class); }
    public function lesson(): BelongsTo { return $this->belongsTo(Lesson::class); }
}
