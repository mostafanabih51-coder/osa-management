<?php

namespace App\Http\Controllers;

use App\Models\{Attendance, Expense, Payment, Schedule, Student, Subscription, Teacher, TeacherDue, User};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rule;

class ApiController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $email = strtolower(trim($data['email']));
        $user = User::whereRaw('LOWER(email) = ?', [$email])->first();

        if (!$user || !Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'بيانات الدخول غير صحيحة'], 401);
        }

        return response()->json([
            'token' => $user->createToken('management')->plainTextToken,
            'user' => $user,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();
        return ['message' => 'Logged out'];
    }

    public function dashboard()
    {
        return [
            'students' => Student::count(),
            'active_students' => Student::where('status', 'active')->count(),
            'teachers' => Teacher::where('status', 'active')->count(),
            'today_classes' => Schedule::whereDate('starts_at', now())->count(),
            'today_attendance' => Attendance::whereDate('date', today())->count(),
            'monthly_income' => Payment::whereBetween('paid_on', [now()->startOfMonth(), now()->endOfMonth()])->sum('amount'),
            'monthly_expenses' => Expense::whereBetween('spent_on', [now()->startOfMonth(), now()->endOfMonth()])->sum('amount'),
            'expiring_7_days' => Subscription::whereBetween('ends_on', [today(), today()->addDays(7)])->where('status', 'active')->count(),
        ];
    }

    public function index()
    {
        return Student::latest()->paginate(25);
    }

    public function store(Request $request)
    {
        return Student::create($request->validate([
            'name' => 'required',
            'phone' => 'nullable',
            'parent_name' => 'nullable',
            'parent_phone' => 'nullable',
            'email' => 'nullable|email',
            'grade' => 'nullable',
            'curriculum' => 'nullable',
            'status' => 'nullable',
            'notes' => 'nullable',
        ]));
    }

    public function show(Student $student)
    {
        return $student;
    }

    public function update(Request $request, Student $student)
    {
        $data = $request->validate([
            'name' => 'sometimes|required',
            'phone' => 'nullable',
            'parent_name' => 'nullable',
            'parent_phone' => 'nullable',
            'email' => 'nullable|email',
            'grade' => 'nullable',
            'curriculum' => 'nullable',
            'status' => 'nullable',
            'notes' => 'nullable',
        ]);
        $student->update($data);
        return $student->fresh();
    }

    public function destroy(Student $student)
    {
        $student->delete();
        return response()->noContent();
    }

    public function teachers()
    {
        return Teacher::latest()->paginate(25);
    }

    public function storeTeacher(Request $request)
    {
        return Teacher::create($request->validate([
            'name' => 'required',
            'phone' => 'nullable',
            'email' => 'nullable|email',
            'specialization' => 'nullable',
            'hourly_rate' => 'nullable|numeric|min:0',
            'status' => 'nullable',
        ]));
    }

    public function schedules()
    {
        return Schedule::with(['teacher', 'student'])->orderBy('starts_at')->paginate(50);
    }

    public function storeSchedule(Request $request)
    {
        $data = $request->validate([
            'teacher_id' => 'required|exists:teachers,id',
            'student_id' => 'nullable|exists:students,id',
            'group_name' => 'nullable',
            'subject' => 'required',
            'starts_at' => 'required|date',
            'ends_at' => 'required|date|after:starts_at',
            'zoom_url' => 'nullable|url',
        ]);

        $conflict = Schedule::where('teacher_id', $data['teacher_id'])
            ->where('starts_at', '<', $data['ends_at'])
            ->where('ends_at', '>', $data['starts_at'])
            ->exists();

        abort_if($conflict, 422, 'Teacher schedule conflict');
        return Schedule::create($data);
    }

    public function attendance()
    {
        return Attendance::with(['student', 'teacher', 'schedule'])->latest('date')->paginate(100);
    }

    public function storeAttendance(Request $request)
    {
        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
            'teacher_id' => 'nullable|exists:teachers,id',
            'schedule_id' => 'nullable|exists:schedules,id',
            'date' => 'required|date',
            'status' => ['required', Rule::in(['present', 'absent', 'late', 'excused'])],
            'notes' => 'nullable',
        ]);
        $data['marked_at'] = now();
        return Attendance::create($data);
    }

    public function subscriptions()
    {
        return Subscription::with('student')->latest()->paginate(50);
    }

    public function storeSubscription(Request $request)
    {
        return Subscription::create($request->validate([
            'student_id' => 'required|exists:students,id',
            'subject' => 'required',
            'amount' => 'required|numeric|min:0',
            'starts_on' => 'required|date',
            'ends_on' => 'required|date|after_or_equal:starts_on',
            'status' => 'nullable',
        ]));
    }

    public function payments()
    {
        return Payment::with(['student', 'subscription'])->latest('paid_on')->paginate(50);
    }

    public function storePayment(Request $request)
    {
        return Payment::create($request->validate([
            'student_id' => 'required|exists:students,id',
            'subscription_id' => 'nullable|exists:subscriptions,id',
            'amount' => 'required|numeric|min:0',
            'paid_on' => 'required|date',
            'method' => 'nullable',
            'collector' => 'nullable',
            'reference' => 'nullable',
            'notes' => 'nullable',
        ]));
    }

    public function expenses()
    {
        return Expense::latest('spent_on')->paginate(50);
    }

    public function storeExpense(Request $request)
    {
        return Expense::create($request->validate([
            'category' => 'required',
            'amount' => 'required|numeric|min:0',
            'spent_on' => 'required|date',
            'description' => 'nullable',
        ]));
    }

    public function teacherDues()
    {
        return TeacherDue::with('teacher')->latest()->paginate(50);
    }

    public function financialReport()
    {
        return [
            'income' => Payment::sum('amount'),
            'expenses' => Expense::sum('amount'),
            'teacher_dues' => TeacherDue::sum('amount'),
            'teacher_paid' => TeacherDue::sum('paid_amount'),
        ];
    }
}
