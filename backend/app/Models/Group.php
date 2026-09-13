<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Group extends Model
{
    protected $fillable = ['name','grade','subject','teacher_id','supervisor_id','teacher_rate','status','notes'];
    protected $casts = ['teacher_rate' => 'decimal:2'];

    public function teacher(): BelongsTo { return $this->belongsTo(Teacher::class); }
    public function supervisor(): BelongsTo { return $this->belongsTo(Supervisor::class); }
    public function students(): BelongsToMany { return $this->belongsToMany(Student::class, 'group_students')->withTimestamps(); }
    public function lessons(): HasMany { return $this->hasMany(Lesson::class); }
}
