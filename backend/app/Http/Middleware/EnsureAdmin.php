<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();
        if (!$user || !in_array($user->role, ['admin', 'super_admin', 'owner', 'technical_admin'], true)) {
            return response()->json(['message' => 'غير مصرح لك بالوصول إلى هذه البيانات.'], 403);
        }
        return $next($request);
    }
}
