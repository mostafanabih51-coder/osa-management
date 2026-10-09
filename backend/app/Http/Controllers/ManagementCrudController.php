<?php
namespace App\Http\Controllers;

use App\Models\{Group, Payment, Subscription, Teacher};
use Illuminate\Http\Request;

class ManagementCrudController extends Controller
{
    public function updateTeacher(Request $r, Teacher $teacher)
    {
        $teacher->update($r->validate([
            'name'=>'sometimes|required',
            'phone'=>'nullable',
            'email'=>'nullable|email',
            'specialization'=>'nullable',
            'hourly_rate'=>'nullable|numeric|min:0',
            'status'=>'nullable'
        ]));
        return response()->json(['success'=>true,'data'=>$teacher->fresh()]);
    }

    public function destroyTeacher(Teacher $teacher)
    {
        $teacher->delete();
        return ['success'=>true];
    }

    public function updateSubscription(Request $r, Subscription $subscription)
    {
        $d=$r->validate([
            'student_id'=>'sometimes|exists:students,id',
            'group_id'=>'nullable|exists:groups,id',
            'subject'=>'sometimes|required',
            'amount'=>'sometimes|numeric|min:0',
            'starts_on'=>'sometimes|date',
            'ends_on'=>'sometimes|date',
            'status'=>'nullable',
            'billing_type'=>'nullable|in:per_lesson,monthly',
            'lesson_price'=>'nullable|numeric|min:0',
            'lesson_count'=>'nullable|integer|min:1|max:100',
            'service_type'=>'nullable|in:private,group'
        ]);

        $hasFinancialHistory = $subscription->payments()->exists() || $subscription->lessonUsages()->exists();
        $lockedFields = ['student_id','group_id','subject','amount','starts_on','ends_on','billing_type','lesson_price','lesson_count','service_type'];
        if ($hasFinancialHistory) {
            foreach ($lockedFields as $field) {
                if (array_key_exists($field, $d) && (string) $d[$field] !== (string) $subscription->{$field}) {
                    return response()->json(['success'=>false,'message'=>'لا يمكن تغيير بيانات التسعير أو ربط الاشتراك بعد تسجيل دفعات أو حصص؛ أنشئ اشتراكًا جديدًا للتغييرات المستقبلية.'],422);
                }
            }
        }

        $start=$d['starts_on'] ?? optional($subscription->starts_on)->format('Y-m-d');
        $end=$d['ends_on'] ?? optional($subscription->ends_on)->format('Y-m-d');
        if ($start && $end && strtotime($end) < strtotime($start)) {
            return response()->json(['message'=>'تاريخ نهاية الاشتراك يجب أن يكون بعد أو مساويًا لتاريخ البداية.'],422);
        }

        $serviceType=$d['service_type'] ?? $subscription->service_type ?? 'group';
        $billingType=$d['billing_type'] ?? $subscription->billing_type ?? ($serviceType==='private'?'per_lesson':'monthly');
        if ($serviceType === 'private') {
            $d['group_id']=null;
            $price=$d['lesson_price'] ?? $subscription->lesson_price ?? $d['amount'] ?? $subscription->amount;
            $d['lesson_price']=$price;
            if ($billingType === 'monthly') {
                $d['billing_type']='monthly'; $d['amount']=$d['amount'] ?? $subscription->amount;
                $d['lesson_count']=$d['lesson_count'] ?? $subscription->lesson_count ?? 8;
            } else {
                $d['billing_type']='per_lesson'; $d['amount']=$price; $d['lesson_count']=null;
            }
        } else {
            $d['billing_type']='monthly'; $d['lesson_price']=null;
            $d['lesson_count']=$d['lesson_count'] ?? $subscription->lesson_count ?? 8;
            $groupId=$d['group_id'] ?? $subscription->group_id;
            if (!$groupId) return response()->json(['message'=>'اختر المجموعة المرتبط بها الطالب.'],422);
            $group=Group::with('students')->findOrFail($groupId);
            $studentId=$d['student_id'] ?? $subscription->student_id; $subject=$d['subject'] ?? $subscription->subject;
            if ((string)$group->subject !== (string)$subject) return response()->json(['message'=>'مادة الاشتراك يجب أن تطابق مادة المجموعة.'],422);
            if (!$group->students->contains('id',(int)$studentId)) return response()->json(['message'=>'أضف الطالب إلى المجموعة أولًا، ثم احفظ الاشتراك.'],422);
            $d['group_id']=$groupId;
        }
        $d['service_type']=$serviceType;
        $d['billing_type']=$billingType==='monthly'?'monthly':($serviceType==='private'?'per_lesson':'monthly');
        $subscription->update($d);
        return response()->json([
            'success'=>true,
            'data'=>$subscription->fresh()->load(['student','group.teacher','group.students','payments'])
        ]);
    }

    public function destroySubscription(Subscription $subscription)
    {
        if ($subscription->payments()->exists() || $subscription->lessonUsages()->exists()) {
            $subscription->update(['status'=>'inactive']);
            return response()->json(['success'=>true,'message'=>'تم إيقاف الاشتراك وأرشفة سجله؛ لا يمكن حذفه بعد وجود دفعات أو حصص مرتبطة.','data'=>$subscription->fresh()],200);
        }
        $subscription->delete();
        return ['success'=>true];
    }

    public function updatePayment(Request $r, Payment $payment)
    {
        $d=$r->validate([
            'student_id'=>'sometimes|exists:students,id',
            'subscription_id'=>'nullable|exists:subscriptions,id',
            'amount'=>'sometimes|numeric|min:0.01',
            'paid_on'=>'sometimes|date',
            'method'=>'nullable',
            'collector'=>'nullable',
            'reference'=>'nullable',
            'notes'=>'nullable'
        ]);
        $studentId=$d['student_id']??$payment->student_id;
        $subscriptionId=$d['subscription_id']??$payment->subscription_id;
        if($subscriptionId&&!Subscription::where('id',$subscriptionId)->where('student_id',$studentId)->exists())
            return response()->json(['message'=>'الاشتراك لا يخص الطالب.'],422);
        $payment->update($d);
        return response()->json(['success'=>true,'data'=>$payment->fresh()->load(['student','subscription'])]);
    }

    public function destroyPayment(Payment $payment)
    {
        $payment->delete();
        return ['success'=>true];
    }
}
