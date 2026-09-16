<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class StudentSubject extends Model
{
 protected $fillable=['student_id','subject','monthly_lessons','completed_lessons','plan_month'];
 protected $casts=['monthly_lessons'=>'integer','completed_lessons'=>'integer'];
 public function student():BelongsTo{return $this->belongsTo(Student::class);}
}
