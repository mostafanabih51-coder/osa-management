<?php
namespace App\Http\Controllers;

use App\Models\{Attendance,Group,Lesson,LessonSetting,Student,StudentSubject,Subscription,SubscriptionLessonUsage,SupervisorDue,TeacherLessonDue,TeacherStudentSubject};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class LessonController extends Controller
{
    private function relations(array $d): void
    {
        if ($d['type'] === 'private') {
            if (empty($d['student_id'])) throw ValidationException::withMessages(['student_id' => 'الطالب مطلوب للحصة الخاصة.']);
            $assignment = TeacherStudentSubject::where(['teacher_id'=>$d['teacher_id'],'student_id'=>$d['student_id'],'subject'=>$d['subject'],'status'=>'active'])->first();
            if (!$assignment) throw ValidationException::withMessages(['relation'=>'اربط الطالب بالمدرس والمادة وحدد سعر المدرس أولًا من صفحة المدرسين.']);
        } else {
            if (empty($d['group_id'])) throw ValidationException::withMessages(['group_id'=>'المجموعة مطلوبة لحصة الجروب.']);
            $g = Group::withCount('students')->find($d['group_id']);
            if (!$g) throw ValidationException::withMessages(['group_id'=>'المجموعة غير موجودة.']);
            if ((int)$g->teacher_id !== (int)$d['teacher_id']) throw ValidationException::withMessages(['teacher_id'=>'مدرس الحصة يجب أن يكون مدرس المجموعة.']);
            if ((string)$g->subject !== (string)$d['subject']) throw ValidationException::withMessages(['subject'=>'مادة الحصة يجب أن تطابق مادة المجموعة.']);
            if (!$g->students_count) throw ValidationException::withMessages(['group_id'=>'أضف طلابًا إلى المجموعة قبل إنشاء الحصة.']);
        }
    }

    public function index(Request $r)
    {
        $q=Lesson::with(['teacher','supervisor','group.teacher','group.supervisor','group.students','student','teacherDueRecord','supervisorDueRecord']);
        foreach(['teacher_id','supervisor_id','group_id','student_id','type','status'] as $f) if($r->filled($f)) $q->where($f,$r->{$f});
        if($r->filled('date')) $q->whereDate('starts_at',$r->date('date'));
        return response()->json(['success'=>true,'data'=>$q->orderBy('starts_at')->get()]);
    }

    public function store(Request $r)
    {
        $d=$r->validate(['type'=>['required',Rule::in(['group','private'])],'teacher_id'=>'required|integer|exists:teachers,id','supervisor_id'=>'nullable|integer|exists:supervisors,id','group_id'=>'nullable|integer|exists:groups,id','student_id'=>'nullable|integer|exists:students,id','subject'=>'required|string|max:255','starts_at'=>'required|date','ends_at'=>'required|date|after:starts_at','zoom_url'=>'nullable|string','status'=>['nullable',Rule::in(['scheduled','completed','cancelled'])],'teacher_rate'=>'nullable|numeric|min:0','supervisor_rate'=>'nullable|numeric|min:0','notes'=>'nullable|string']);
        $this->relations($d);
        if($d['type']==='private' && !Student::whereKey($d['student_id'])->value('allow_lessons_with_debt') && $this->studentOutstandingBalance((int)$d['student_id']) > 0.009) return response()->json(['success'=>false,'message'=>'تم إيقاف الحصص الجديدة لهذا الطالب بسبب وجود مديونية؛ سجّل السداد أو غيّر سياسة الطالب أولًا.'],422);
        if($d['type']==='group') $d['student_id']=null; else $d['group_id']=null;
        $assignment=$d['type']==='private'?TeacherStudentSubject::where(['teacher_id'=>$d['teacher_id'],'student_id'=>$d['student_id'],'subject'=>$d['subject'],'status'=>'active'])->first():null;
        $g=$d['type']==='group'?Group::find($d['group_id']):null;
        if(!array_key_exists('teacher_rate',$d)||$d['teacher_rate']===null) $d['teacher_rate']=$assignment?->teacher_rate??$g?->teacher_rate;
        if(!array_key_exists('supervisor_rate',$d)||$d['supervisor_rate']===null) $d['supervisor_rate']=LessonSetting::where('lesson_type',$d['type'])->where('active',true)->value('supervisor_rate')??0;
        $d['status']=$d['status']??'scheduled'; $d['teacher_rate']=$d['teacher_rate']??0; $d['supervisor_rate']=$d['supervisor_rate']??0; $d['teacher_due']=$d['teacher_rate']; $d['supervisor_due']=$d['supervisor_rate'];
        $lesson=DB::transaction(function()use($d){
            // A scheduled lesson is not earned yet. Create financial dues only when completion is confirmed.
            $l=Lesson::create($d);
            if($l->status==='completed') $this->ensureCompletedLessonDues($l);
            return $l;
        });
        return response()->json(['success'=>true,'data'=>$lesson->fresh()->load(['teacher','supervisor','group.teacher','group.students','student','teacherDueRecord','supervisorDueRecord'])],201);
    }

    public function show(Lesson $lesson){return response()->json(['success'=>true,'data'=>$lesson->load(['teacher','supervisor','group.teacher','group.students','student','teacherDueRecord','supervisorDueRecord'])]);}

    public function update(Request $r,Lesson $lesson)
    {
        $d=$r->validate(['type'=>['sometimes',Rule::in(['group','private'])],'teacher_id'=>'sometimes|integer|exists:teachers,id','supervisor_id'=>'nullable|integer|exists:supervisors,id','group_id'=>'nullable|integer|exists:groups,id','student_id'=>'nullable|integer|exists:students,id','subject'=>'sometimes|string|max:255','starts_at'=>'sometimes|date','ends_at'=>'sometimes|date','zoom_url'=>'nullable|string','status'=>['sometimes',Rule::in(['scheduled','completed','cancelled'])],'teacher_rate'=>'sometimes|numeric|min:0','supervisor_rate'=>'sometimes|numeric|min:0','notes'=>'nullable|string']);
        $td=TeacherLessonDue::where('lesson_id',$lesson->id)->first(); $sd=SupervisorDue::where('lesson_id',$lesson->id)->first();
        $financiallyPaid=(($td&&(float)$td->paid_amount>0)||($sd&&(float)$sd->paid_amount>0));
        $financialFields=['type','teacher_id','supervisor_id','group_id','student_id','subject','teacher_rate','supervisor_rate'];
        if($financiallyPaid) foreach($financialFields as $f) if(array_key_exists($f,$d) && (string)$d[$f] !== (string)$lesson->{$f}) return response()->json(['success'=>false,'message'=>'لا يمكن تغيير بيانات الحصة المالية بعد صرف المستحق.'],422);
        if($lesson->status==='completed' && isset($d['status']) && $d['status']!=='completed') return response()->json(['success'=>false,'message'=>'لا يمكن إعادة فتح حصة مكتملة.'],422);
        $e=array_merge(['type'=>$lesson->type,'teacher_id'=>$lesson->teacher_id,'group_id'=>$lesson->group_id,'student_id'=>$lesson->student_id,'subject'=>$lesson->subject],$d); if($e['type']==='group')$e['student_id']=null;else$e['group_id']=null; $this->relations($e);
        if(strtotime($d['ends_at']??$lesson->ends_at)<=strtotime($d['starts_at']??$lesson->starts_at)) return response()->json(['success'=>false,'message'=>'نهاية الحصة يجب أن تكون بعد البداية.'],422);
        if($e['type']==='group')$d['student_id']=null;else$d['group_id']=null;
        if(isset($d['teacher_rate']))$d['teacher_due']=$d['teacher_rate']; if(isset($d['supervisor_rate']))$d['supervisor_due']=$d['supervisor_rate'];
        $wasCompleted = $lesson->status === 'completed';
        DB::transaction(function()use($lesson,$d,$e,$td,$sd,$wasCompleted){
            $lesson->update($d);
            if($td){$td->teacher_id=$lesson->teacher_id;if((float)$td->paid_amount===0&&array_key_exists('teacher_rate',$d))$td->amount=$lesson->teacher_due;$td->status=(float)$td->paid_amount>=(float)$td->amount?'paid':'unpaid';$td->save();}
            if($lesson->supervisor_id){if(!$sd && $lesson->status==='completed')SupervisorDue::firstOrCreate(['lesson_id'=>$lesson->id],['supervisor_id'=>$lesson->supervisor_id,'amount'=>$lesson->supervisor_due,'paid_amount'=>0,'status'=>'unpaid']);elseif($sd && (float)$sd->paid_amount===0){$sd->supervisor_id=$lesson->supervisor_id;if(array_key_exists('supervisor_rate',$d))$sd->amount=$lesson->supervisor_due;$sd->save();}}elseif($sd && (float)$sd->paid_amount===0){$sd->delete();}
            $lesson->refresh();
            if(!$wasCompleted && $lesson->status==='completed')$this->recordSubscriptionUsage($lesson);
            if($lesson->status==='completed')$this->ensureCompletedLessonDues($lesson);
        });
        return response()->json(['success'=>true,'data'=>$lesson->fresh()->load(['teacher','supervisor','group.teacher','group.students','student','teacherDueRecord','supervisorDueRecord'])]);
    }

    public function destroy(Lesson $lesson)
    {
        if(SubscriptionLessonUsage::where('lesson_id',$lesson->id)->exists())return response()->json(['success'=>false,'message'=>'لا يمكن حذف حصة تم احتسابها ضمن رصيد اشتراك؛ ألغِ الحصة أو صحح سجل الاشتراك أولًا.'],422);
        $paid=TeacherLessonDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists()||SupervisorDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists();
        if($paid)return response()->json(['success'=>false,'message'=>'لا يمكن حذف حصة تم صرف مستحقاتها.'],422);
        DB::transaction(function()use($lesson){TeacherLessonDue::where('lesson_id',$lesson->id)->delete();SupervisorDue::where('lesson_id',$lesson->id)->delete();$lesson->delete();});
        return ['success'=>true];
    }

    private function studentOutstandingBalance(int $studentId): float
    {
        return Subscription::with(['payments', 'lessonUsages'])->where('student_id', $studentId)->get()
            ->sum(function ($subscription) {
                $paid = (float) $subscription->payments->sum('amount');
                $gross = ($subscription->billing_type ?? 'monthly') === 'per_lesson'
                    ? (float) ($subscription->lesson_price ?? $subscription->amount) * $subscription->lessonUsages->count()
                    : (float) $subscription->amount;
                return max(0, $gross - $paid);
            });
    }

    private function countPlanLesson(int $studentId, string $subject, bool $resetOnMonthChange = false): void
    {
        $plan=StudentSubject::where('student_id',$studentId)->where('subject',$subject)->first();
        if(!$plan)return;
        $type=$plan->plan_type??'monthly';$month=now()->format('Y-m');
        if($type==='monthly' && $plan->plan_month!==$month && ($resetOnMonthChange || (int)$plan->completed_lessons >= (int)$plan->monthly_lessons)){$plan->plan_month=$month;$plan->completed_lessons=0;}
        if((int)$plan->completed_lessons < (int)$plan->monthly_lessons){$plan->completed_lessons=(int)$plan->completed_lessons+1;$plan->save();}
    }

    /**
     * Attach each completed lesson to the subscription whose lesson balance it consumes.
     * Private monthly packages carry forward until their lesson count is used; group
     * lessons are charged against the matching month's group subscription for every
     * enrolled student, including students marked absent.
     */
    private function recordSubscriptionUsage(Lesson $lesson): void
    {
        $lessonDate = $lesson->starts_at?->toDateString() ?? now()->toDateString();

        if ($lesson->type === 'private' && $lesson->student_id) {
            $studentId = (int) $lesson->student_id;
            $base = Subscription::where('student_id', $studentId)
                ->where('subject', $lesson->subject)
                ->where('service_type', 'private')
                ->whereIn('status', ['active', 'expired'])
                ->orderBy('starts_on')->orderBy('id');

            $chosen = null;
            foreach ((clone $base)->where('billing_type', 'monthly')->whereNotNull('lesson_count')->get() as $candidate) {
                $used = SubscriptionLessonUsage::where('subscription_id', $candidate->id)->count();
                if ($used < (int) $candidate->lesson_count) { $chosen = $candidate; break; }
            }

            if (!$chosen) {
                $chosen = (clone $base)->where('billing_type', 'per_lesson')
                    ->orderByRaw("CASE WHEN status = 'active' THEN 0 ELSE 1 END")
                    ->orderByDesc('starts_on')->first();
            }

            if ($chosen) {
                SubscriptionLessonUsage::firstOrCreate(
                    ['lesson_id' => $lesson->id, 'student_id' => $studentId],
                    ['subscription_id' => $chosen->id, 'lesson_date' => $lessonDate, 'service_type' => 'private']
                );
            }
            return;
        }

        if ($lesson->type === 'group' && $lesson->group_id) {
            $group = Group::with('students')->find($lesson->group_id);
            if (!$group) return;
            foreach ($group->students as $student) {
                $subscription = Subscription::where('student_id', $student->id)
                    ->where('subject', $lesson->subject)
                    ->where('service_type', 'group')
                    ->where('group_id', $group->id)
                    ->whereIn('status', ['active', 'expired'])
                    ->whereDate('starts_on', '<=', $lessonDate)
                    ->whereDate('ends_on', '>=', $lessonDate)
                    ->orderByDesc('starts_on')->first();
                if (!$subscription) continue;
                SubscriptionLessonUsage::firstOrCreate(
                    ['lesson_id' => $lesson->id, 'student_id' => $student->id],
                    ['subscription_id' => $subscription->id, 'lesson_date' => $lessonDate, 'service_type' => 'group']
                );
            }
        }
    }

    /**
     * Create dues idempotently only for a completed lesson.
     * The lesson_id relationship is the de-duplication key for this workflow.
     */
    private function ensureCompletedLessonDues(Lesson $lesson): void
    {
        TeacherLessonDue::firstOrCreate(
            ['lesson_id' => $lesson->id],
            ['teacher_id' => $lesson->teacher_id, 'amount' => $lesson->teacher_due ?? $lesson->teacher_rate ?? 0, 'paid_amount' => 0, 'status' => 'unpaid']
        );

        if ($lesson->supervisor_id) {
            SupervisorDue::firstOrCreate(
                ['lesson_id' => $lesson->id],
                ['supervisor_id' => $lesson->supervisor_id, 'amount' => $lesson->supervisor_due ?? $lesson->supervisor_rate ?? 0, 'paid_amount' => 0, 'status' => 'unpaid']
            );
        }
    }

    public function complete(Lesson $lesson)
    {
        if($lesson->status==='cancelled')return response()->json(['success'=>false,'message'=>'لا يمكن إكمال حصة ملغاة.'],422);
        if($lesson->status==='completed') {
            // Repair a missing due record on legacy completed lessons without duplicating existing dues.
            DB::transaction(fn() => $this->ensureCompletedLessonDues($lesson));
            return ['success'=>true,'data'=>$lesson->fresh()->load(['teacherDueRecord','supervisorDueRecord']),'message'=>'الحصة مكتملة بالفعل؛ لم يتم احتسابها مرتين.'];
        }
        DB::transaction(function()use($lesson){
            $lesson = Lesson::whereKey($lesson->id)->lockForUpdate()->firstOrFail();
            if($lesson->status==='completed') {
                $this->ensureCompletedLessonDues($lesson);
                return;
            }
            if($lesson->type==='private' && $lesson->student_id)$this->countPlanLesson((int)$lesson->student_id,(string)$lesson->subject);
            if($lesson->type==='group'){$ids=Group::find($lesson->group_id)?->students()->pluck('students.id') ?? collect();foreach($ids as $studentId)$this->countPlanLesson((int)$studentId,(string)$lesson->subject,true);}
            $lesson->update(['status'=>'completed','completed_at'=>now()]);
            $this->recordSubscriptionUsage($lesson->fresh());
            $this->ensureCompletedLessonDues($lesson->fresh());
        });
        return ['success'=>true,'data'=>$lesson->fresh()->load(['teacherDueRecord','supervisorDueRecord'])];
    }

    public function cancel(Lesson $lesson)
    {
        if($lesson->status==='completed')return response()->json(['success'=>false,'message'=>'لا يمكن إلغاء حصة مكتملة.'],422);
        $paid=TeacherLessonDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists()||SupervisorDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists();
        if($paid)return response()->json(['success'=>false,'message'=>'لا يمكن إلغاء حصة تم صرف مستحقاتها.'],422);
        DB::transaction(function()use($lesson){TeacherLessonDue::where('lesson_id',$lesson->id)->delete();SupervisorDue::where('lesson_id',$lesson->id)->delete();$lesson->update(['status'=>'cancelled']);});
        return ['success'=>true,'data'=>$lesson->fresh()];
    }
}
