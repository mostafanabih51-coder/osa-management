<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
class TeacherStudentSubject extends Model
{
 protected $table='teacher_student_subjects';
 protected $fillable=['teacher_id','student_id','subject','lesson_price','teacher_rate','academy_percentage','supervisor_id','status'];
 protected $casts=['lesson_price'=>'decimal:2','teacher_rate'=>'decimal:2','academy_percentage'=>'decimal:2'];
 public function teacher():BelongsTo{return $this->belongsTo(Teacher::class);}
 public function student():BelongsTo{return $this->belongsTo(Student::class);}
 public function supervisor():BelongsTo{return $this->belongsTo(Supervisor::class);}
 public function getTotalLessonPriceAttribute():float{return round((float)$this->lesson_price,2);}
 public function getTeacherNetAttribute():float{return round((float)$this->teacher_rate,2);}
 public function getAcademyAmountAttribute():float{return round((float)$this->lesson_price*(float)$this->academy_percentage/100,2);}
}
