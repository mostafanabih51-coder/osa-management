<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Schedule extends Model { protected $fillable=['teacher_id','student_id','group_name','subject','starts_at','ends_at','zoom_url','status']; protected $casts=['starts_at'=>'datetime','ends_at'=>'datetime']; public function teacher(){return $this->belongsTo(Teacher::class);} public function student(){return $this->belongsTo(Student::class);} public function attendance(){return $this->hasMany(Attendance::class);} }
