<?php

namespace App\Http\Controllers;

use App\Models\{User, Teacher, Supervisor};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class UserController extends Controller
{
    private const ROLES = ['owner', 'admin', 'technical_admin', 'supervisor', 'teacher', 'staff'];
    private const PERMISSIONS = [
        'view_students', 'manage_students', 'view_teachers', 'manage_teachers',
        'view_supervisors', 'manage_supervisors', 'view_groups', 'manage_groups',
        'view_schedules', 'manage_schedules', 'view_attendance', 'manage_attendance',
        'view_subscriptions', 'manage_subscriptions', 'view_finance', 'manage_finance',
        'view_lessons', 'manage_lessons',
    ];
    private const FINANCE_PERMISSIONS = ['view_finance', 'manage_finance'];
    private const PROTECTED_ROLES = ['owner', 'admin', 'super_admin'];

    public function index(Request $request)
    {
        $this->ensureAdmin($request);
        return response()->json([
            'data' => User::query()->select(['id','name','email','role','permissions'])->orderBy('id')->get(),
            'roles' => self::ROLES,
            'permissions' => self::PERMISSIONS,
        ]);
    }

    public function store(Request $request)
    {
        $this->ensureAdmin($request);
        $validated = $request->validate([
            'name' => ['required','string','max:255'],
            'email' => ['required','email','max:255','unique:users,email'],
            'password' => ['required','string','min:8'],
            'role' => ['required',Rule::in(self::ROLES)],
            'permissions' => ['nullable','array'],
            'permissions.*' => ['string',Rule::in(self::PERMISSIONS)],
        ]);
        $role = $validated['role'];
        if (in_array($role, ['owner','admin'], true) && $request->user()->role !== 'owner') return response()->json(['message' => 'إنشاء Owner أو Admin متاح للـOwner فقط.'], 403);
        $permissions = array_values(array_unique($validated['permissions'] ?? []));
        if ($this->containsFinancePermission($permissions) && $request->user()->role !== 'owner') return response()->json(['message' => 'الصلاحيات المالية الحساسة يملكها الـOwner فقط.'], 403);
        if (in_array($role, ['owner','admin'], true)) $permissions = self::PERMISSIONS;

        $user = DB::transaction(function () use ($validated, $role, $permissions) {
            $user = User::create([
                'name' => $validated['name'], 'email' => $validated['email'], 'password' => $validated['password'],
                'role' => $role, 'permissions' => $permissions,
            ]);
            if ($role === 'teacher') {
                Teacher::create(['user_id'=>$user->id,'name'=>$user->name,'email'=>$user->email,'status'=>'active']);
            } elseif ($role === 'supervisor') {
                Supervisor::create(['user_id'=>$user->id,'name'=>$user->name,'email'=>$user->email,'status'=>'active']);
            }
            return $user;
        });

        return response()->json(['message' => 'تم إنشاء المستخدم وربط الحساب التشغيلي بنجاح.', 'data' => $user->only(['id','name','email','role','permissions'])], 201);
    }

    public function update(Request $request, User $user)
    {
        $this->ensureAdmin($request);
        if (in_array($user->role, self::PROTECTED_ROLES, true) && $user->id !== $request->user()->id) return response()->json(['message' => 'لا يمكن تعديل حساب Owner/Admin من حساب إداري آخر.'], 403);
        $validated = $request->validate([
            'name' => ['sometimes','required','string','max:255'], 'email' => ['sometimes','required','email','max:255',Rule::unique('users','email')->ignore($user->id)],
            'password' => ['sometimes','nullable','string','min:8'], 'role' => ['sometimes',Rule::in(self::ROLES)],
        ]);
        if (array_key_exists('password', $validated) && $validated['password'] === null) unset($validated['password']);
        if (isset($validated['role']) && in_array($validated['role'], ['owner','admin'], true) && $request->user()->role !== 'owner') return response()->json(['message' => 'تغيير الدور إلى Owner/Admin متاح للـOwner فقط.'], 403);
        if (isset($validated['role']) && $user->role === 'super_admin' && $validated['role'] !== 'super_admin' && $request->user()->role !== 'owner') return response()->json(['message' => 'تعديل حساب Super Admin متاح للـOwner فقط.'], 403);

        $oldRole = $user->role;
        $user->fill($validated);
        if (in_array($user->role, ['owner','admin'], true)) $user->permissions = self::PERMISSIONS;
        DB::transaction(function () use ($user, $oldRole) {
            $user->save();
            if ($oldRole !== $user->role) {
                if ($user->role === 'teacher') {
                    Supervisor::where('user_id',$user->id)->update(['user_id'=>null]);
                    Teacher::updateOrCreate(['user_id'=>$user->id], ['name'=>$user->name,'email'=>$user->email,'status'=>'active']);
                } elseif ($user->role === 'supervisor') {
                    Teacher::where('user_id',$user->id)->update(['user_id'=>null]);
                    Supervisor::updateOrCreate(['user_id'=>$user->id], ['name'=>$user->name,'email'=>$user->email,'status'=>'active']);
                }
            }
        });
        return response()->json(['message' => 'تم تحديث المستخدم بنجاح.', 'data' => $user->only(['id','name','email','role','permissions'])]);
    }

    public function destroy(Request $request, User $user)
    {
        $this->ensureAdmin($request);
        if ($user->id === $request->user()->id || in_array($user->role, self::PROTECTED_ROLES, true)) return response()->json(['message' => 'لا يمكن حذف حساب Owner/Admin/Super Admin من هنا.'], 403);
        DB::transaction(function () use ($user) {
            Teacher::where('user_id',$user->id)->update(['user_id'=>null]);
            Supervisor::where('user_id',$user->id)->update(['user_id'=>null]);
            $user->tokens()->delete(); $user->delete();
        });
        return response()->json(['message' => 'تم حذف حساب الدخول مع الاحتفاظ بالسجل التشغيلي.']);
    }

    public function updatePermissions(Request $request, User $user)
    {
        $this->ensureAdmin($request);
        if (in_array($user->role, self::PROTECTED_ROLES, true)) return response()->json(['message' => 'صلاحيات المالك والمدير الرئيسي ثابتة ولا تحتاج إلى تعديل.'], 422);
        $validated = $request->validate(['permissions' => ['required','array'],'permissions.*' => ['string',Rule::in(self::PERMISSIONS)]]);
        $permissions = array_values(array_unique($validated['permissions']));
        $oldFinance = array_values(array_intersect($user->permissions ?? [], self::FINANCE_PERMISSIONS)); $newFinance = array_values(array_intersect($permissions, self::FINANCE_PERMISSIONS)); sort($oldFinance); sort($newFinance);
        if ($oldFinance !== $newFinance && $request->user()->role !== 'owner') return response()->json(['message' => 'منح أو سحب الصلاحيات المالية الحساسة متاح للـOwner فقط.'], 403);
        $user->permissions = $permissions; $user->save();
        return response()->json(['message' => 'تم تحديث الصلاحيات بنجاح.','data' => $user->only(['id','name','email','role','permissions'])]);
    }

    private function containsFinancePermission(array $permissions): bool { return count(array_intersect($permissions, self::FINANCE_PERMISSIONS)) > 0; }
    private function ensureAdmin(Request $request): void { abort_unless(in_array($request->user()?->role, ['admin','super_admin','owner','technical_admin'], true), 403, 'غير مصرح بإدارة المستخدمين والصلاحيات.'); }
}
