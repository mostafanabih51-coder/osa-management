<?php

namespace App\Http\Controllers;

use App\Models\{Group, Subscription};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SubscriptionEnhancementController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
            'group_id' => 'nullable|exists:groups,id',
            'subject' => 'required|string|max:150',
            'service_type' => 'required|in:private,group',
            'billing_type' => 'required|in:per_lesson,monthly',
            'amount' => 'required|numeric|min:0',
            'lesson_price' => 'nullable|numeric|min:0',
            'lesson_count' => 'nullable|integer|min:1|max:100',
            'starts_on' => 'required|date',
            'ends_on' => 'required|date|after_or_equal:starts_on',
            'status' => 'nullable|in:active,inactive,expired',
        ]);

        if ($data['service_type'] === 'private') {
            $data['group_id'] = null;
            $data['lesson_price'] = $data['lesson_price'] ?? $data['amount'];
            if ($data['billing_type'] === 'monthly') {
                $data['lesson_count'] = $data['lesson_count'] ?? 8;
            } else {
                $data['billing_type'] = 'per_lesson';
                $data['amount'] = $data['lesson_price'];
                $data['lesson_count'] = null;
            }
        } else {
            if (empty($data['group_id'])) return response()->json(['message' => 'اختر المجموعة المرتبط بها الطالب قبل حفظ اشتراك الجروب.'], 422);
            $group = Group::with('students')->findOrFail($data['group_id']);
            if ((string) $group->subject !== (string) $data['subject']) return response()->json(['message' => 'مادة الاشتراك يجب أن تطابق مادة المجموعة.'], 422);
            if (!$group->students->contains('id', (int) $data['student_id'])) return response()->json(['message' => 'أضف الطالب إلى المجموعة أولًا، ثم أنشئ الاشتراك.'], 422);
            $data['billing_type'] = 'monthly'; $data['lesson_price'] = null; $data['lesson_count'] = $data['lesson_count'] ?? 8;
        }

        return DB::transaction(fn () => response()->json([
            'success' => true,
            'data' => Subscription::create($data)->load(['student', 'group.teacher', 'group.students', 'payments']),
        ], 201));
    }
}
