<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class StudentResource extends Model
{
 protected $fillable=['student_id','teacher_id','lesson_id','type','title','url','description','published_on'];
 protected $casts=['published_on'=>'date'];
 public function student():BelongsTo{return $this->belongsTo(Student::class);} public function teacher():BelongsTo{return $this->belongsTo(Teacher::class);} public function lesson():BelongsTo{return $this->belongsTo(Lesson::class);}
}
