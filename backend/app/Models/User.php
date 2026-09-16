<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    protected $fillable = ['name', 'email', 'password', 'role', 'permissions'];
    protected $hidden = ['password', 'remember_token'];
    protected $appends = ['portal'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'permissions' => 'array',
    ];

    public function hasPermission(string $permission): bool
    {
        if (in_array($this->role, ['admin', 'super_admin', 'owner'], true)) return true;
        return in_array($permission, $this->permissions ?? [], true);
    }

    public function getPortalAttribute(): ?array
    {
        if ($this->role === 'teacher') {
            $teacher = Teacher::where('user_id', $this->id)->first();
            if (!$teacher) return null;
            $students = $teacher->students()->distinct()->get(['students.id','students.name','students.phone','students.grade']);
            $lessons = $teacher->lessons()->with(['student','group'])->orderByDesc('starts_at')->limit(100)->get();
            return ['type'=>'teacher','profile'=>$teacher,'students'=>$students,'assignments'=>$teacher->assignments()->with(['student','supervisor'])->get(),'groups'=>$teacher->groups()->with('students')->get(),'lessons'=>$lessons,'dues'=>$teacher->lessonDues()->with('lesson')->get()];
        }
        if ($this->role === 'supervisor') {
            $supervisor = Supervisor::where('user_id', $this->id)->first();
            if (!$supervisor) return null;
            $lessons = $supervisor->lessons()->with(['teacher','student','group.students'])->orderByDesc('starts_at')->limit(100)->get();
            $studentIds = $lessons->pluck('student_id')->filter();
            foreach ($lessons as $lesson) if ($lesson->group) $studentIds = $studentIds->merge($lesson->group->students->pluck('id'));
            $students = Student::whereIn('id', $studentIds->unique())->get(['id','name','phone','grade']);
            return ['type'=>'supervisor','profile'=>$supervisor,'students'=>$students,'lessons'=>$lessons,'dues'=>$supervisor->dues()->latest()->get()];
        }
        return null;
    }
}
