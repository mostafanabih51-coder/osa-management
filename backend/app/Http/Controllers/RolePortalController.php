<?php

namespace App\Http\Controllers;

use App\Models\{Teacher, Supervisor};
use Illuminate\Http\Request;

class RolePortalController extends Controller
{
    public function me(Request $request)
    {
        $user = $request->user();
        if ($user->role === 'teacher') return $this->teacher($user->id);
        if ($user->role === 'supervisor') return $this->supervisor($user->id);
        return response()->json(['role'=>$user->role,'message'=>'هذا الحساب ليس حساب مدرس أو مشرف.']);
    }

    private function teacher(int $userId)
    {
        $teacher = Teacher::where('user_id',$userId)->firstOrFail();
        $teacher->load(['assignments.student','assignments.supervisor','groups.students','groups.supervisor','lessons.student','lessons.group','lessons.supervisor','lessonDues.lesson']);
        $students = $teacher->students()->distinct()->get();
        return response()->json(['role'=>'teacher','profile'=>$teacher,'students'=>$students,'assignments'=>$teacher->assignments,'groups'=>$teacher->groups,'lessons'=>$teacher->lessons()->orderByDesc('starts_at')->limit(100)->get(),'dues'=>$teacher->lessonDues]);
    }

    private function supervisor(int $userId)
    {
        $supervisor = Supervisor::where('user_id',$userId)->firstOrFail();
        $lessons = $supervisor->lessons()->with(['teacher','student','group'])->orderByDesc('starts_at')->limit(100)->get();
        $studentIds = $lessons->pluck('student_id')->filter()->unique()->values();
        foreach ($lessons as $lesson) if ($lesson->group) $studentIds = $studentIds->merge($lesson->group->students->pluck('id'));
        return response()->json(['role'=>'supervisor','profile'=>$supervisor,'lessons'=>$lessons,'students'=>\App\Models\Student::whereIn('id',$studentIds->unique())->get(),'dues'=>$supervisor->dues()->latest()->get()]);
    }
}
