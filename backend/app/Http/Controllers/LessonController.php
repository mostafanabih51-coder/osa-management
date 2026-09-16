<?php
namespace App\Http\Controllers;

use App\Models\{Group,Lesson,LessonSetting,SupervisorDue,TeacherLessonDue,TeacherStudentSubject};
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
        if($d['type']==='group') $d['student_id']=null; else $d['group_id']=null;
        $assignment=$d['type']==='private'?TeacherStudentSubject::where(['teacher_id'=>$d['teacher_id'],'student_id'=>$d['student_id'],'subject'=>$d['subject'],'status'=>'active'])->first():null;
        $g=$d['type']==='group'?Group::find($d['group_id']):null;
        if(!array_key_exists('teacher_rate',$d)||$d['teacher_rate']===null) $d['teacher_rate']=$assignment?->teacher_rate??$g?->teacher_rate;
        if(!array_key_exists('supervisor_rate',$d)||$d['supervisor_rate']===null) $d['supervisor_rate']=LessonSetting::where('lesson_type',$d['type'])->where('active',true)->value('supervisor_rate')??0;
        $d['status']=$d['status']??'scheduled'; $d['teacher_rate']=$d['teacher_rate']??0; $d['supervisor_rate']=$d['supervisor_rate']??0; $d['teacher_due']=$d['teacher_rate']; $d['supervisor_due']=$d['supervisor_rate'];
        $lesson=DB::transaction(function()use($d){$l=Lesson::create($d);TeacherLessonDue::create(['teacher_id'=>$l->teacher_id,'lesson_id'=>$l->id,'amount'=>$l->teacher_due,'paid_amount'=>0,'status'=>'unpaid']);if($l->supervisor_id)SupervisorDue::create(['supervisor_id'=>$l->supervisor_id,'lesson_id'=>$l->id,'amount'=>$l->supervisor_due,'paid_amount'=>0,'status'=>'unpaid']);return $l;});
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
        DB::transaction(function()use($lesson,$d,$e,$td,$sd){$lesson->update($d);if($td){$td->teacher_id=$lesson->teacher_id;if((float)$td->paid_amount===0&&array_key_exists('teacher_rate',$d))$td->amount=$lesson->teacher_due;$td->status=(float)$td->paid_amount>=(float)$td->amount?'paid':'unpaid';$td->save();}if($lesson->supervisor_id){if(!$sd)SupervisorDue::create(['supervisor_id'=>$lesson->supervisor_id,'lesson_id'=>$lesson->id,'amount'=>$lesson->supervisor_due,'paid_amount'=>0,'status'=>'unpaid']);elseif((float)$sd->paid_amount===0){$sd->supervisor_id=$lesson->supervisor_id;if(array_key_exists('supervisor_rate',$d))$sd->amount=$lesson->supervisor_due;$sd->save();}}elseif($sd){$sd->delete();}});
        return response()->json(['success'=>true,'data'=>$lesson->fresh()->load(['teacher','supervisor','group.teacher','group.students','student','teacherDueRecord','supervisorDueRecord'])]);
    }

    public function destroy(Lesson $lesson)
    {
        $paid=TeacherLessonDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists()||SupervisorDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists();
        if($paid)return response()->json(['success'=>false,'message'=>'لا يمكن حذف حصة تم صرف مستحقاتها.'],422);
        DB::transaction(function()use($lesson){TeacherLessonDue::where('lesson_id',$lesson->id)->delete();SupervisorDue::where('lesson_id',$lesson->id)->delete();$lesson->delete();});
        return ['success'=>true];
    }

    public function complete(Lesson $lesson){if($lesson->status==='cancelled')return response()->json(['success'=>false,'message'=>'لا يمكن إكمال حصة ملغاة.'],422);$lesson->update(['status'=>'completed','completed_at'=>now()]);return ['success'=>true,'data'=>$lesson->fresh()];}

    public function cancel(Lesson $lesson)
    {
        if($lesson->status==='completed')return response()->json(['success'=>false,'message'=>'لا يمكن إلغاء حصة مكتملة.'],422);
        $paid=TeacherLessonDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists()||SupervisorDue::where('lesson_id',$lesson->id)->where('paid_amount','>',0)->exists();
        if($paid)return response()->json(['success'=>false,'message'=>'لا يمكن إلغاء حصة تم صرف مستحقاتها.'],422);
        DB::transaction(function()use($lesson){TeacherLessonDue::where('lesson_id',$lesson->id)->delete();SupervisorDue::where('lesson_id',$lesson->id)->delete();$lesson->update(['status'=>'cancelled']);});
        return ['success'=>true,'data'=>$lesson->fresh()];
    }
}
