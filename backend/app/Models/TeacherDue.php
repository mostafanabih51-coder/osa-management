<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class TeacherDue extends Model {protected $fillable=['teacher_id','period','hours','rate','amount','paid_amount','status']; protected $casts=['hours'=>'decimal:2','rate'=>'decimal:2','amount'=>'decimal:2','paid_amount'=>'decimal:2']; public function teacher(){return $this->belongsTo(Teacher::class);} }
