<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Teacher extends Model { protected $fillable=['name','phone','email','specialization','hourly_rate','status']; protected $casts=['hourly_rate'=>'decimal:2']; public function schedules(){return $this->hasMany(Schedule::class);} public function dues(){return $this->hasMany(TeacherDue::class);} }
