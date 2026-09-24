<?php

namespace App\Http\Controllers;

use App\Models\Subscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class SubscriptionEnhancementController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'student_id' => 'required|exists:students,id',
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
            $data['billing_type'] = 'per_lesson';
            $data['lesson_price'] = $data['lesson_price'] ?? $data['amount'];
            $data['amount'] = $data['lesson_price'];
            $data['lesson_count'] = null;
        } else {
            $data['billing_type'] = 'monthly';
            $data['lesson_count'] = $data['lesson_count'] ?? 8;
        }

        return DB::transaction(fn () => response()->json([
            'success' => true,
            'data' => Subscription::create($data)->load(['student', 'payments']),
        ], 201));
    }
}
