<?php
namespace App\Http\Controllers;

use App\Models\{Payment, Subscription, Teacher};
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

        $start=$d['starts_on'] ?? optional($subscription->starts_on)->format('Y-m-d');
        $end=$d['ends_on'] ?? optional($subscription->ends_on)->format('Y-m-d');
        if ($start && $end && strtotime($end) < strtotime($start)) {
            return response()->json(['message'=>'تاريخ نهاية الاشتراك يجب أن يكون بعد أو مساويًا لتاريخ البداية.'],422);
        }

        $serviceType=$d['service_type'] ?? $subscription->service_type ?? 'group';
        if ($serviceType === 'private') {
            $d['billing_type']='per_lesson';
            $price=$d['lesson_price'] ?? $subscription->lesson_price ?? $d['amount'] ?? $subscription->amount;
            $d['lesson_price']=$price;
            $d['amount']=$price;
            $d['lesson_count']=null;
        } else {
            $d['billing_type']='monthly';
            $d['lesson_count']=$d['lesson_count'] ?? $subscription->lesson_count ?? 8;
        }
        $d['service_type']=$serviceType;

        $subscription->update($d);
        return response()->json([
            'success'=>true,
            'data'=>$subscription->fresh()->load(['student','payments'])
        ]);
    }

    public function destroySubscription(Subscription $subscription)
    {
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
