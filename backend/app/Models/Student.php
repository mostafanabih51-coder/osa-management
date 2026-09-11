<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Student extends Model
{
    protected $fillable = ['name','phone','parent_name','parent_phone','email','grade','curriculum','status','notes'];

    public function subscriptions() { return $this->hasMany(Subscription::class); }
    public function payments() { return $this->hasMany(Payment::class); }
    public function attendance() { return $this->hasMany(Attendance::class); }
    public function schedules() { return $this->hasMany(Schedule::class); }
    public function lessons() { return $this->hasMany(Lesson::class); }
}
