<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
class Student extends Model
{
 protected $fillable=['name','phone','parent_name','parent_phone','email','grade','curriculum','status','notes'];
 public function subscriptions():HasMany{return $this->hasMany(Subscription::class);} public function payments():HasMany{return $this->hasMany(Payment::class);} public function attendance():HasMany{return $this->hasMany(Attendance::class);} public function schedules():HasMany{return $this->hasMany(Schedule::class);} public function lessons():HasMany{return $this->hasMany(Lesson::class);} public function subjects():HasMany{return $this->hasMany(StudentSubject::class);} public function teacherAssignments():HasMany{return $this->hasMany(TeacherStudentSubject::class);} public function evaluations():HasMany{return $this->hasMany(StudentEvaluation::class);} public function resources():HasMany{return $this->hasMany(StudentResource::class);} public function teachers():BelongsToMany{return $this->belongsToMany(Teacher::class,'teacher_student_subjects')->withPivot(['subject','teacher_rate','academy_percentage','supervisor_id','status'])->withTimestamps();} public function groups():BelongsToMany{return $this->belongsToMany(Group::class,'group_students')->withTimestamps();}
}
