<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = ['name', 'email', 'password', 'role', 'permissions'];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'permissions' => 'array',
    ];

    public function hasPermission(string $permission): bool
    {
        if (in_array($this->role, ['admin', 'super_admin', 'owner'], true)) {
            return true;
        }

        return in_array($permission, $this->permissions ?? [], true);
    }
}
