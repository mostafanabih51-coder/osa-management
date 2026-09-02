<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Payment extends Model {protected $fillable=['student_id','subscription_id','amount','paid_on','method','collector','reference','notes']; protected $casts=['amount'=>'decimal:2','paid_on'=>'date:Y-m-d']; public function student(){return $this->belongsTo(Student::class);} public function subscription(){return $this->belongsTo(Subscription::class);} }
