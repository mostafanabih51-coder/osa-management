<?php
namespace App\Http\Controllers;
use App\Models\{Payment,Subscription,Teacher};
use Illuminate\Http\Request;
class ManagementCrudController extends Controller
{
 public function updateTeacher(Request $r,Teacher $teacher){$teacher->update($r->validate(['name'=>'sometimes|required','phone'=>'nullable','email'=>'nullable|email','specialization'=>'nullable','hourly_rate'=>'nullable|numeric|min:0','status'=>'nullable']));return response()->json(['success'=>true,'data'=>$teacher->fresh()]);}
 public function destroyTeacher(Teacher $teacher){$teacher->delete();return['success'=>true];}
 public function updateSubscription(Request $r,Subscription $subscription){$d=$r->validate(['student_id'=>'sometimes|exists:students,id','subject'=>'sometimes|required','amount'=>'sometimes|numeric|min:0','starts_on'=>'sometimes|date','ends_on'=>'sometimes|date|after_or_equal:starts_on','status'=>'nullable','billing_type'=>'nullable|in:per_lesson,monthly','lesson_price'=>'nullable|numeric|min:0','lesson_count'=>'nullable|integer|min:1|max:100','service_type'=>'nullable|in:private,group']);if(isset($d['student_id'])&&$d['student_id']!=$subscription->student_id){$subscription->student_id=$d['student_id'];} $subscription->update($d);return response()->json(['success'=>true,'data'=>$subscription->fresh()->load(['student','payments'])]);}
 public function destroySubscription(Subscription $subscription){$subscription->delete();return['success'=>true];}
 public function updatePayment(Request $r,Payment $payment){$d=$r->validate(['student_id'=>'sometimes|exists:students,id','subscription_id'=>'nullable|exists:subscriptions,id','amount'=>'sometimes|numeric|min:0.01','paid_on'=>'sometimes|date','method'=>'nullable','collector'=>'nullable','reference'=>'nullable','notes'=>'nullable']);$studentId=$d['student_id']??$payment->student_id;$subscriptionId=$d['subscription_id']??$payment->subscription_id;if($subscriptionId&&!Subscription::where('id',$subscriptionId)->where('student_id',$studentId)->exists())return response()->json(['message'=>'الاشتراك لا يخص الطالب.'],422);$payment->update($d);return response()->json(['success'=>true,'data'=>$payment->fresh()->load(['student','subscription'])]);}
 public function destroyPayment(Payment $payment){$payment->delete();return['success'=>true];}
}
