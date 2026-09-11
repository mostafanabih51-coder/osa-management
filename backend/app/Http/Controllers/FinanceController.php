<?php

namespace App\Http\Controllers;

use App\Models\Bonus;
use App\Models\SupervisorDue;
use App\Models\TeacherLessonDue;
use App\Models\WithdrawalRequest;
use App\Models\WithdrawalSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class FinanceController extends Controller
{
    public function teacherDues(Request $request)
    {
        $query = TeacherLessonDue::with(['teacher', 'lesson'])->latest();
        if ($request->filled('teacher_id')) $query->where('teacher_id', $request->integer('teacher_id'));
        if ($request->filled('status')) $query->where('status', $request->string('status'));
        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function supervisorDues(Request $request)
    {
        $query = SupervisorDue::with(['supervisor', 'lesson'])->latest();
        if ($request->filled('supervisor_id')) $query->where('supervisor_id', $request->integer('supervisor_id'));
        if ($request->filled('status')) $query->where('status', $request->string('status'));
        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function bonuses(Request $request)
    {
        $query = Bonus::query()->latest();
        if ($request->filled('recipient_type')) $query->where('recipient_type', $request->string('recipient_type'));
        if ($request->filled('recipient_id')) $query->where('recipient_id', $request->integer('recipient_id'));
        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function storeBonus(Request $request)
    {
        $data = $request->validate([
            'recipient_type' => ['required', Rule::in(['teacher', 'supervisor'])],
            'recipient_id' => 'required|integer',
            'name' => 'required|string|max:255',
            'amount' => 'required|numeric|min:0.01',
            'bonus_date' => 'required|date',
            'notes' => 'nullable|string',
        ]);
        $data['created_by'] = $request->user()->id;
        return response()->json(['success' => true, 'data' => Bonus::create($data)], 201);
    }

    public function withdrawalSettings()
    {
        return response()->json(['success' => true, 'data' => WithdrawalSetting::all()]);
    }

    public function updateWithdrawalSetting(Request $request)
    {
        $data = $request->validate([
            'recipient_type' => ['required', Rule::in(['teacher', 'supervisor'])],
            'enabled' => 'required|boolean',
            'minimum_amount' => 'required|numeric|min:0',
        ]);
        $setting = WithdrawalSetting::updateOrCreate(
            ['recipient_type' => $data['recipient_type']],
            ['enabled' => $data['enabled'], 'minimum_amount' => $data['minimum_amount']]
        );
        return response()->json(['success' => true, 'data' => $setting]);
    }

    public function withdrawals(Request $request)
    {
        $query = WithdrawalRequest::query()->latest();
        foreach (['recipient_type', 'status'] as $field) {
            if ($request->filled($field)) $query->where($field, $request->string($field));
        }
        if ($request->filled('recipient_id')) $query->where('recipient_id', $request->integer('recipient_id'));
        return response()->json(['success' => true, 'data' => $query->get()]);
    }

    public function storeWithdrawal(Request $request)
    {
        $data = $request->validate([
            'recipient_type' => ['required', Rule::in(['teacher', 'supervisor'])],
            'recipient_id' => 'required|integer',
            'amount' => 'required|numeric|min:0.01',
            'notes' => 'nullable|string',
        ]);

        $setting = WithdrawalSetting::where('recipient_type', $data['recipient_type'])->first();
        if ($setting && !$setting->enabled) return response()->json(['success' => false, 'message' => 'السحب مغلق حاليًا.'], 422);
        if ($setting && $data['amount'] < $setting->minimum_amount) return response()->json(['success' => false, 'message' => 'المبلغ أقل من الحد الأدنى للسحب.'], 422);

        $available = $this->availableBalance($data['recipient_type'], (int)$data['recipient_id']);
        if ($data['amount'] > $available) return response()->json(['success' => false, 'message' => 'المبلغ المطلوب أكبر من المستحق المتاح.'], 422);

        $duplicate = WithdrawalRequest::where('recipient_type', $data['recipient_type'])
            ->where('recipient_id', $data['recipient_id'])
            ->whereIn('status', ['pending', 'approved'])
            ->exists();
        if ($duplicate) return response()->json(['success' => false, 'message' => 'يوجد طلب سحب مفتوح بالفعل لهذا المستحق.'], 422);

        $withdrawal = WithdrawalRequest::create($data + ['status' => 'pending']);
        return response()->json(['success' => true, 'data' => $withdrawal], 201);
    }

    public function updateWithdrawal(Request $request, WithdrawalRequest $withdrawal)
    {
        $data = $request->validate([
            'status' => ['required', Rule::in(['pending', 'approved', 'rejected', 'paid'])],
            'notes' => 'nullable|string',
        ]);

        if ($withdrawal->status === 'paid') return response()->json(['success' => false, 'message' => 'لا يمكن تعديل طلب تم صرفه.'], 422);
        if ($data['status'] === 'paid' && $withdrawal->status !== 'approved') return response()->json(['success' => false, 'message' => 'يجب اعتماد الطلب أولًا.'], 422);

        DB::transaction(function () use ($request, $withdrawal, $data) {
            if ($data['status'] === 'paid') {
                $this->applyPayment($withdrawal->recipient_type, (int)$withdrawal->recipient_id, (float)$withdrawal->amount);
                $withdrawal->paid_at = now();
            }
            if ($data['status'] === 'approved') {
                $withdrawal->approved_by = $request->user()->id;
                $withdrawal->approved_at = now();
            }
            $withdrawal->status = $data['status'];
            if (array_key_exists('notes', $data)) $withdrawal->notes = $data['notes'];
            $withdrawal->save();
        });

        return response()->json(['success' => true, 'data' => $withdrawal->fresh()]);
    }

    public function payDue(Request $request, string $type, int $due)
    {
        $amount = $request->validate(['amount' => 'required|numeric|min:0.01'])['amount'];
        if (!in_array($type, ['teacher', 'supervisor'], true)) return response()->json(['message' => 'نوع المستحق غير صحيح.'], 422);
        $model = $type === 'teacher' ? TeacherLessonDue::class : SupervisorDue::class;
        $record = $model::findOrFail($due);
        $remaining = max(0, (float)$record->amount - (float)$record->paid_amount);
        if ($amount > $remaining) return response()->json(['message' => 'المبلغ أكبر من المتبقي على المستحق.'], 422);
        $record->paid_amount = (float)$record->paid_amount + (float)$amount;
        $record->status = ((float)$record->paid_amount >= (float)$record->amount) ? 'paid' : 'partial';
        $record->save();
        return response()->json(['success' => true, 'data' => $record->fresh()]);
    }

    public function summary()
    {
        $teacherDue = TeacherLessonDue::sum('amount');
        $teacherPaid = TeacherLessonDue::sum('paid_amount');
        $supervisorDue = SupervisorDue::sum('amount');
        $supervisorPaid = SupervisorDue::sum('paid_amount');
        $bonuses = Bonus::sum('amount');
        return response()->json(['success' => true, 'data' => [
            'teacher_due' => $teacherDue, 'teacher_paid' => $teacherPaid, 'teacher_remaining' => max(0, $teacherDue - $teacherPaid),
            'supervisor_due' => $supervisorDue, 'supervisor_paid' => $supervisorPaid, 'supervisor_remaining' => max(0, $supervisorDue - $supervisorPaid),
            'bonuses' => $bonuses, 'total_due' => $teacherDue + $supervisorDue, 'total_paid' => $teacherPaid + $supervisorPaid,
            'total_remaining' => max(0, ($teacherDue + $supervisorDue) - ($teacherPaid + $supervisorPaid)),
        ]]);
    }

    private function availableBalance(string $type, int $recipientId): float
    {
        $due = $type === 'teacher'
            ? (float)TeacherLessonDue::where('teacher_id', $recipientId)->sum(DB::raw('amount - paid_amount'))
            : (float)SupervisorDue::where('supervisor_id', $recipientId)->sum(DB::raw('amount - paid_amount'));
        $reserved = (float)WithdrawalRequest::where('recipient_type', $type)
            ->where('recipient_id', $recipientId)
            ->whereIn('status', ['pending', 'approved'])
            ->sum('amount');
        return max(0, $due - $reserved);
    }

    private function applyPayment(string $type, int $recipientId, float $amount): void
    {
        $query = $type === 'teacher'
            ? TeacherLessonDue::where('teacher_id', $recipientId)->whereColumn('paid_amount', '<', 'amount')->orderBy('id')->lockForUpdate()
            : SupervisorDue::where('supervisor_id', $recipientId)->whereColumn('paid_amount', '<', 'amount')->orderBy('id')->lockForUpdate();
        foreach ($query->get() as $record) {
            if ($amount <= 0) break;
            $remaining = max(0, (float)$record->amount - (float)$record->paid_amount);
            $take = min($remaining, $amount);
            $record->paid_amount = (float)$record->paid_amount + $take;
            $record->status = ((float)$record->paid_amount >= (float)$record->amount) ? 'paid' : 'partial';
            $record->save();
            $amount -= $take;
        }
        if ($amount > 0.009) throw new \RuntimeException('المبلغ المطلوب صرفه يتجاوز المستحق المتاح.');
    }
}
