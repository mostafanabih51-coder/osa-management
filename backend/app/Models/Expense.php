<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
class Expense extends Model {protected $fillable=['category','amount','spent_on','description','created_by']; protected $casts=['amount'=>'decimal:2','spent_on'=>'date:Y-m-d']; public function creator(){return $this->belongsTo(User::class,'created_by');} }
