<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WithdrawalSetting extends Model
{
    protected $fillable = [
        'recipient_type',
        'enabled',
        'minimum_amount',
    ];

    protected $casts = [
        'enabled' => 'boolean',
        'minimum_amount' => 'decimal:2',
    ];
}
