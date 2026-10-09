<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SubscriptionReminder extends Model
{
    protected $fillable = ['subscription_id', 'reminder_type', 'cycle_key', 'title', 'message', 'due_on', 'read_at'];
    protected $casts = ['due_on' => 'date:Y-m-d', 'read_at' => 'datetime'];

    public function subscription(): BelongsTo { return $this->belongsTo(Subscription::class); }
}
