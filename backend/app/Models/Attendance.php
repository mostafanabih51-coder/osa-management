<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Attendance extends Model {protected $table='attendance';protected $fillable=['student_id','teacher_id','schedule_id','date','status','marked_at','notes']; protected $casts=['date'=>'date:Y-m-d','marked_at'=>'datetime']; public function student(){return $this->belongsTo(Student::class);} public function teacher(){return $this->belongsTo(Teacher::class);} public function schedule(){return $this->belongsTo(Schedule::class);} }
