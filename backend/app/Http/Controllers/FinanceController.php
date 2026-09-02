<?php

namespace App\Http\Controllers;

use App\Models\Bonus;
use App\Models\Supervisor;
use App\Models\SupervisorDue;
use App\Models\Teacher;
use App\Models\TeacherLessonDue;
use App\Models\WithdrawalRequest;
use App\Models\WithdrawalSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FinanceController extends Controller
{
    public function teacherDues(Request $request)
    {
        $query = TeacherLessonDue::with(['teacher', 'lesson']);

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        return response()->json([
            'success' => true,
            'data' => $query->latest()->get(),
        ]);
    }

    public function supervisorDues(Request $request)
    {
        $query = SupervisorDue::with(['supervisor', 'lesson']);

        if ($request->filled('supervisor_id')) {
            $query->where('supervisor_id', $request->supervisor_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        return response()->json([
            'success' => true,
            'data' => $query->latest()->get(),
        ]);
    }

    public function bonuses(Request $request)
    {
        $query = Bonus::query();

        if ($request->filled('recipient_type')) {
            $query->where('recipient_type', $request->recipient_type);
        }

        if ($request->filled('recipient_id')) {
            $query->where('recipient_id', $request->recipient_id);
        }

        return response()->json([
            'success' => true,
            'data' => $query->latest()->get(),
        ]);
    }

    public function storeBonus(Request $request)
    {
        $data = $request->validate([
            'recipient_type' => 'required|in:teacher,supervisor',
            'recipient_id' => 'required|integer',
            'name' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0',
            'bonus_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);

        $data['created_by'] = $request->user()->id;

        $bonus = Bonus::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Bonus created successfully',
            'data' => $bonus,
        ], 201);
    }

    public function withdrawalSettings()
    {
        return response()->json([
            'success' => true,
            'data' => WithdrawalSetting::all(),
        ]);
    }

    public function updateWithdrawalSetting(Request $request)
    {
        $data = $request->validate([
            'recipient_type' => 'required|in:teacher,supervisor',
            'enabled' => 'required|boolean',
            'minimum_amount' => 'required|numeric|min:0',
        ]);

        $setting = WithdrawalSetting::updateOrCreate(
            ['recipient_type' => $data['recipient_type']],
            [
                'enabled' => $data['enabled'],
                'minimum_amount' => $data['minimum_amount'],
            ]
        );

        return response()->json([
            'success' => true,
            'data' => $setting,
        ]);
    }

    public function withdrawals(Request $request)
    {
        $query = WithdrawalRequest::query();

        if ($request->filled('recipient_type')) {
            $query->where('recipient_type', $request->recipient_type);
        }

        if ($request->filled('recipient_id')) {
            $query->where('recipient_id', $request->recipient_id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        return response()->json([
            'success' => true,
            'data' => $query->latest()->get(),
        ]);
    }

    public function storeWithdrawal(Request $request)
    {
        $data = $request->validate([
            'recipient_type' => 'required|in:teacher,supervisor',
            'recipient_id' => 'required|integer',
            'amount' => 'required|numeric|min:0.01',
            'notes' => 'nullable|string',
        ]);

        $setting = WithdrawalSetting::where(
            'recipient_type',
            $data['recipient_type']
        )->first();

        if ($setting && !$setting->enabled) {
            return response()->json([
                'success' => false,
                'message' => 'Withdrawals are currently disabled.',
            ], 422);
        }

        if ($setting && $data['amount'] < $setting->minimum_amount) {
            return response()->json([
                'success' => false,
                'message' => 'Amount is below the minimum withdrawal amount.',
            ], 422);
        }

        $withdrawal = WithdrawalRequest::create($data);

        return response()->json([
            'success' => true,
            'message' => 'Withdrawal request created successfully',
            'data' => $withdrawal,
        ], 201);
    }

    public function updateWithdrawal(Request $request, WithdrawalRequest $withdrawal)
    {
        $data = $request->validate([
            'status' => 'required|in:pending,approved,rejected,paid',
            'notes' => 'nullable|string',
        ]);

        $update = [
            'status' => $data['status'],
            'notes' => $data['notes'] ?? $withdrawal->notes,
        ];

        if ($data['status'] === 'approved') {
            $update['approved_by'] = $request->user()->id;
            $update['approved_at'] = now();
        }

        if ($data['status'] === 'paid') {
            $update['paid_at'] = now();
        }

        $withdrawal->update($update);

        return response()->json([
            'success' => true,
            'data' => $withdrawal->fresh(),
        ]);
    }

    public function summary()
    {
        $teacherDue = TeacherLessonDue::sum('amount');
        $teacherPaid = TeacherLessonDue::sum('paid_amount');

        $supervisorDue = SupervisorDue::sum('amount');
        $supervisorPaid = SupervisorDue::sum('paid_amount');

        $bonuses = Bonus::sum('amount');

        return response()->json([
            'success' => true,
            'data' => [
                'teacher_due' => $teacherDue,
                'teacher_paid' => $teacherPaid,
                'teacher_remaining' => $teacherDue - $teacherPaid,

                'supervisor_due' => $supervisorDue,
                'supervisor_paid' => $supervisorPaid,
                'supervisor_remaining' => $supervisorDue - $supervisorPaid,

                'bonuses' => $bonuses,

                'total_due' => $teacherDue + $supervisorDue,
                'total_paid' => $teacherPaid + $supervisorPaid,
                'total_remaining' =>
                    ($teacherDue + $supervisorDue)
                    - ($teacherPaid + $supervisorPaid),
            ],
        ]);
    }
}
