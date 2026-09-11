<?php

namespace App\Http\Controllers;

use App\Models\{Attendance, Expense, Group, Payment, Schedule, Student, Subscription, Teacher, TeacherDue, TeacherLessonDue, Supervisor, SupervisorDue, User};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ApiController extends Controller
{
    public function login(Request $request)
    {
        $data = $request->validate(['email' => ['required', 'email'], 'password' => ['required', 'string']]);
        $user = User::whereRaw('LOWER(email) = ?', [strtolower(trim($data['email']))])->first();
        if (!$user || !Hash::check($data['password'], $user->password)) return response()->json(['message' => 'بيانات الدخول غير صحيحة'], 401);
        return response()->json(['token' => $user->createToken('management')->plainTextToken, 'user' => $user]);
    }

    public function logout(Request $request) { $request->user()->currentAccessToken()?->delete(); return ['message' => 'تم تسجيل الخروج']; }

    public function dashboard(Request $request)
    {
        $admin = in_array($request->user()->role, ['admin', 'super_admin', 'owner'], true);
        $data = [
            'academy_name' => 'Online School Academy',
            'students' => Student::count(),
            'active_students' => Student::where('status', 'active')->count(),
            'teachers' => Teacher::where('status', 'active')->count(),
            'today_classes' => Schedule::whereDate('starts_at', now())->where(fn($q) => $q->whereNull('status')->orWhere('status', '!=', 'cancelled'))->count(),
            'today_attendance' => Attendance::whereDate('date', today())->count(),
            'expiring_7_days' => Subscription::whereBetween('ends_on', [today(), today()->addDays(7)])->where('status', 'active')->count(),
        ];
        if ($admin) {
            $data['monthly_income'] = Payment::whereBetween('paid_on', [now()->startOfMonth(), now()->endOfMonth()])->sum('amount');
            $data['monthly_expenses'] = Expense::whereBetween('spent_on', [now()->startOfMonth(), now()->endOfMonth()])->sum('amount');
        }
        return $data;
    }

    public function index() { return Student::latest()->paginate(25); }
    public function store(Request $request) { return Student::create($request->validate(['name'=>'required','phone'=>'nullable','parent_name'=>'nullable','parent_phone'=>'nullable','email'=>'nullable|email','grade'=>'nullable','curriculum'=>'nullable','status'=>'nullable','notes'=>'nullable'])); }
    public function show(Student $student) { return $student; }
    public function update(Request $request, Student $student) { $student->update($request->validate(['name'=>'sometimes|required','phone'=>'nullable','parent_name'=>'nullable','parent_phone'=>'nullable','email'=>'nullable|email','grade'=>'nullable','curriculum'=>'nullable','status'=>'nullable','notes'=>'nullable'])); return $student->fresh(); }
    public function destroy(Student $student) { $student->delete(); return response()->noContent(); }

    public function teachers() { return Teacher::withCount(['schedules'])->latest()->paginate(25); }
    public function storeTeacher(Request $request) { return Teacher::create($request->validate(['name'=>'required','phone'=>'nullable','email'=>'nullable|email','specialization'=>'nullable','hourly_rate'=>'nullable|numeric|min:0','status'=>'nullable'])); }

    public function teacherDetails(Teacher $teacher)
    {
        $teacher->load(['lessons.student','lessons.group','lessons.supervisor','lessonDues.lesson']);
        $dues = $teacher->lessonDues;
        return response()->json(['success'=>true,'data'=>[
            'teacher'=>$teacher,
            'students'=>Student::whereHas('lessons', fn($q) => $q->where('teacher_id', $teacher->id))->distinct()->get(),
            'groups'=>$teacher->lessons->pluck('group')->filter()->unique('id')->values(),
            'due'=>$dues->sum('amount'),'paid'=>$dues->sum('paid_amount'),'remaining'=>max(0,$dues->sum('amount')-$dues->sum('paid_amount')),
        ]]);
    }

    public function supervisors() { return Supervisor::withCount(['lessons'])->latest()->paginate(50); }
    public function storeSupervisor(Request $request) { return Supervisor::create($request->validate(['name'=>'required','phone'=>'nullable','email'=>'nullable|email','status'=>'nullable','user_id'=>'nullable|exists:users,id'])); }

    public function groups()
    {
        return response()->json(['success'=>true,'data'=>Group::withCount('students')->with('students:id,name')->latest()->get()]);
    }

    public function storeGroup(Request $request)
    {
        $data = $request->validate(['name'=>'required|string|max:255','grade'=>'nullable|string|max:100','subject'=>'nullable|string|max:100','status'=>'nullable|string|max:50','notes'=>'nullable|string','student_ids'=>'nullable|array','student_ids.*'=>'integer|exists:students,id']);
        $studentIds = $data['student_ids'] ?? [];
        unset($data['student_ids']);
        $group = DB::transaction(function () use ($data, $studentIds) {
            $group = Group::create($data);
            if ($studentIds) $group->students()->sync($studentIds);
            return $group;
        });
        return response()->json(['success'=>true,'data'=>$group->load('students:id,name')],201);
    }

    public function updateGroup(Request $request, Group $group)
    {
        $data = $request->validate(['name'=>'sometimes|required|string|max:255','grade'=>'nullable|string|max:100','subject'=>'nullable|string|max:100','status'=>'nullable|string|max:50','notes'=>'nullable|string','student_ids'=>'nullable|array','student_ids.*'=>'integer|exists:students,id']);
        DB::transaction(function () use ($group, $data) {
            $studentIds = $data['student_ids'] ?? null;
            unset($data['student_ids']);
            $group->update($data);
            if ($studentIds !== null) $group->students()->sync($studentIds);
        });
        return response()->json(['success'=>true,'data'=>$group->fresh()->load('students:id,name')]);
    }

    public function destroyGroup(Group $group)
    {
        $group->delete();
        return response()->json(['success'=>true,'message'=>'تم حذف المجموعة']);
    }

    public function addStudentToGroup(Request $request, Group $group)
    {
        $data = $request->validate(['student_id'=>'required|integer|exists:students,id']);
        $group->students()->syncWithoutDetaching([$data['student_id']]);
        return response()->json(['success'=>true,'data'=>$group->fresh()->load('students:id,name')]);
    }

    public function removeStudentFromGroup(Group $group, Student $student)
    {
        $group->students()->detach($student->id);
        return response()->json(['success'=>true,'data'=>$group->fresh()->load('students:id,name')]);
    }

    public function schedules(Request $request)
    {
        $query = Schedule::with(['teacher','student'])->orderBy('starts_at');
        if ($request->filled('from')) $query->whereDate('starts_at','>=',$request->date('from'));
        if ($request->filled('to')) $query->whereDate('starts_at','<=',$request->date('to'));
        return $query->paginate(50);
    }

    public function storeSchedule(Request $request)
    {
        $data = $request->validate(['teacher_id'=>'required|exists:teachers,id','student_id'=>'nullable|exists:students,id','group_name'=>'nullable','subject'=>'required','starts_at'=>'required|date','ends_at'=>'required|date|after:starts_at','zoom_url'=>'nullable|url']);
        $conflict = Schedule::where('teacher_id',$data['teacher_id'])->where(fn($q)=>$q->whereNull('status')->orWhere('status','!=','cancelled'))->where('starts_at','<',$data['ends_at'])->where('ends_at','>',$data['starts_at'])->exists();
        abort_if($conflict,422,'يوجد تعارض في جدول المدرس.');
        return Schedule::create($data);
    }

    public function attendance(Request $request)
    {
        $query = Attendance::with(['student','teacher','schedule'])->latest('date');
        if ($request->filled('from')) $query->whereDate('date','>=',$request->date('from'));
        if ($request->filled('to')) $query->whereDate('date','<=',$request->date('to'));
        return $query->paginate(100);
    }

    public function storeAttendance(Request $request)
    {
        $data = $request->validate(['student_id'=>'required|exists:students,id','teacher_id'=>'nullable|exists:teachers,id','schedule_id'=>'nullable|exists:schedules,id','date'=>'required|date','status'=>['required',Rule::in(['present','absent','late','excused'])],'notes'=>'nullable']);
        $data['marked_at']=now(); return Attendance::updateOrCreate(['student_id'=>$data['student_id'],'date'=>$data['date'],'schedule_id'=>$data['schedule_id'] ?? null],$data);
    }

    public function subscriptions(Request $request)
    {
        $query = Subscription::with('student')->latest();
        if ($request->filled('from')) $query->whereDate('starts_on','>=',$request->date('from'));
        if ($request->filled('to')) $query->whereDate('starts_on','<=',$request->date('to'));
        return $query->paginate(50);
    }
    public function storeSubscription(Request $request) { return Subscription::create($request->validate(['student_id'=>'required|exists:students,id','subject'=>'required','amount'=>'required|numeric|min:0','starts_on'=>'required|date','ends_on'=>'required|date|after_or_equal:starts_on','status'=>'nullable'])); }

    public function payments(Request $request)
    {
        $query = Payment::with(['student','subscription'])->latest('paid_on');
        if ($request->filled('from')) $query->whereDate('paid_on','>=',$request->date('from'));
        if ($request->filled('to')) $query->whereDate('paid_on','<=',$request->date('to'));
        return $query->paginate(50);
    }
    public function storePayment(Request $request) { return DB::transaction(fn() => Payment::create($request->validate(['student_id'=>'required|exists:students,id','subscription_id'=>'nullable|exists:subscriptions,id','amount'=>'required|numeric|min:0.01','paid_on'=>'required|date','method'=>'nullable','collector'=>'nullable','reference'=>'nullable','notes'=>'nullable']))); }

    public function expenses(Request $request)
    {
        $query = Expense::latest('spent_on');
        if ($request->filled('from')) $query->whereDate('spent_on','>=',$request->date('from'));
        if ($request->filled('to')) $query->whereDate('spent_on','<=',$request->date('to'));
        return $query->paginate(50);
    }
    public function storeExpense(Request $request) { $data=$request->validate(['category'=>'required','amount'=>'required|numeric|min:0.01','spent_on'=>'required|date','description'=>'nullable']); $data['created_by']=$request->user()->id; return Expense::create($data); }

    public function teacherDues(Request $request) { return TeacherDue::with('teacher')->latest()->paginate(50); }

    public function financialReport(Request $request)
    {
        if ($request->filled('month')) {
            $month = $request->string('month');
            $from = now()->setDate((int)substr($month,0,4),(int)substr($month,5,2),1)->startOfDay();
            $to = $from->copy()->endOfMonth()->endOfDay();
        } else {
            $from = $request->date('from')?->startOfDay() ?? now()->startOfYear()->startOfDay();
            $to = $request->date('to')?->endOfDay() ?? now()->endOfMonth()->endOfDay();
        }
        $income = Payment::whereBetween('paid_on',[$from,$to])->sum('amount');
        $expenses = Expense::whereBetween('spent_on',[$from->toDateString(),$to->toDateString()])->sum('amount');
        $teacherDue = TeacherLessonDue::whereHas('lesson',fn($q)=>$q->whereBetween('starts_at',[$from,$to]))->sum('amount');
        $teacherPaid = TeacherLessonDue::whereHas('lesson',fn($q)=>$q->whereBetween('starts_at',[$from,$to]))->sum('paid_amount');
        $supervisorDue = SupervisorDue::whereHas('lesson',fn($q)=>$q->whereBetween('starts_at',[$from,$to]))->sum('amount');
        $supervisorPaid = SupervisorDue::whereHas('lesson',fn($q)=>$q->whereBetween('starts_at',[$from,$to]))->sum('paid_amount');
        return ['from'=>$from->toDateString(),'to'=>$to->toDateString(),'month'=>$from->format('Y-m'),'income'=>$income,'expenses'=>$expenses,'teacher_dues'=>$teacherDue,'teacher_paid'=>$teacherPaid,'supervisor_dues'=>$supervisorDue,'supervisor_paid'=>$supervisorPaid,'net_operation'=>$income-$expenses];
    }
}
