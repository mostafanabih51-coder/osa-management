<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class StudentEvaluation extends Model
{
 protected $fillable=['student_id','teacher_id','supervisor_id','lesson_id','subject','score','title','notes','evaluation_date'];
 protected $casts=['score'=>'decimal:2','evaluation_date'=>'date'];
 public function student():BelongsTo{return $this->belongsTo(Student::class);} public function teacher():BelongsTo{return $this->belongsTo(Teacher::class);} public function supervisor():BelongsTo{return $this->belongsTo(Supervisor::class);} public function lesson():BelongsTo{return $this->belongsTo(Lesson::class);}
}
