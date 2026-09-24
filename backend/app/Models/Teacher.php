<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
class Teacher extends Model
{
 protected $fillable=['user_id','name','phone','email','specialization','hourly_rate','status']; protected $casts=['hourly_rate'=>'decimal:2'];
 public function user():BelongsTo{return $this->belongsTo(User::class);}
 public function schedules():HasMany{return $this->hasMany(Schedule::class);} public function dues():HasMany{return $this->hasMany(TeacherDue::class);} public function lessonDues():HasMany{return $this->hasMany(TeacherLessonDue::class);} public function lessons():HasMany{return $this->hasMany(Lesson::class);} public function assignments():HasMany{return $this->hasMany(TeacherStudentSubject::class);} public function students():BelongsToMany{return $this->belongsToMany(Student::class,'teacher_student_subjects')->withPivot(['subject','lesson_price','teacher_rate','academy_percentage','supervisor_id','status'])->withTimestamps();} public function groups():HasMany{return $this->hasMany(Group::class);}
}
