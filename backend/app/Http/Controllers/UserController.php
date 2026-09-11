<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

class UserController extends Controller
{
    private const PERMISSIONS = [
        'view_students', 'manage_students',
        'view_teachers', 'manage_teachers',
        'view_supervisors', 'manage_supervisors',
        'view_groups', 'manage_groups',
        'view_schedules', 'manage_schedules',
        'view_attendance', 'manage_attendance',
        'view_subscriptions', 'manage_subscriptions',
        'view_finance', 'manage_finance',
        'view_lessons', 'manage_lessons',
    ];

    public function index(Request $request)
    {
        $this->ensureAdmin($request);

        return response()->json([
            'data' => User::query()
                ->select(['id', 'name', 'email', 'role', 'permissions'])
                ->orderBy('id')
                ->get(),
        ]);
    }

    public function updatePermissions(Request $request, User $user)
    {
        $this->ensureAdmin($request);

        if (in_array($user->role, ['admin', 'super_admin', 'owner'], true)) {
            return response()->json(['message' => 'صلاحيات المالك والمدير الرئيسي ثابتة ولا تحتاج إلى تعديل.'], 422);
        }

        $validated = $request->validate([
            'permissions' => ['required', 'array'],
            'permissions.*' => ['string', 'in:' . implode(',', self::PERMISSIONS)],
        ]);

        $user->permissions = array_values(array_unique($validated['permissions']));
        $user->save();

        return response()->json([
            'message' => 'تم تحديث الصلاحيات بنجاح.',
            'data' => $user->only(['id', 'name', 'email', 'role', 'permissions']),
        ]);
    }

    private function ensureAdmin(Request $request): void
    {
        $role = $request->user()?->role;
        abort_unless(in_array($role, ['admin', 'super_admin', 'owner'], true), 403, 'غير مصرح بإدارة المستخدمين والصلاحيات.');
    }
}
