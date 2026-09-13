<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StudentSubject extends Model
{
    protected $fillable = ['student_id', 'subject'];

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }
}
