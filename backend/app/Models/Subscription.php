<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Subscription extends Model {protected $fillable=['student_id','subject','amount','billing_type','lesson_price','lesson_count','service_type','starts_on','ends_on','status']; protected $casts=['amount'=>'decimal:2','starts_on'=>'date:Y-m-d','ends_on'=>'date:Y-m-d']; public function student(){return $this->belongsTo(Student::class);} public function payments(){return $this->hasMany(Payment::class);} }
