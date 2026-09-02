<?php
use Illuminate\Support\Facades\Route;
Route::get('/', fn () => response()->json(['name'=>'Online School Academy Management API','status'=>'ok','version'=>'1.1']));
