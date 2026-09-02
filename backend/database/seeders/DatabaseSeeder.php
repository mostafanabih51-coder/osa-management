<?php
namespace Database\Seeders; use Illuminate\Database\Seeder; use App\Models\User; use Illuminate\Support\Facades\Hash;
class DatabaseSeeder extends Seeder {public function run(){User::create(['name'=>'OSA Administrator','email'=>'admin@onlineschoolacademy.com','password'=>Hash::make('ChangeMe123!'),'role'=>'super_admin']);}}
