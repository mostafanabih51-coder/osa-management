<?php

namespace App\Http\Controllers;

use App\Models\Group;
use App\Models\Lesson;
use App\Models\LessonSetting;
use App\Models\Student;
use App\Models\Supervisor;
use App\Models\Teacher;
use App\Models\TeacherLessonDue;
use App\Models\SupervisorDue;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class LessonController extends Controller
{
    public function index(Request $request)
    {
        $query = Lesson::with([
            'teacher',
            'supervisor',
            'group',
            'student',
            'teacherDueRecord',
            'supervisorDueRecord',
        ]);

        if ($request->filled('teacher_id')) {
            $query->where('teacher_id', $request->teacher_id);
        }

        if ($request->filled('supervisor_id')) {
            $query->where('supervisor_id', $request->supervisor_id);
        }

        if ($request->filled('group_id')) {
            $query->where('group_id', $request->group_id);
        }

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('date')) {
            $query->whereDate('starts_at', $request->date);
        }

        return response()->json([
            'success' => true,
            'data' => $query->orderBy('starts_at')->get(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => [
                'required',
                Rule::in(['group', 'private']),
            ],

            'teacher_id' => [
                'required',
                'integer',
                'exists:teachers,id',
            ],

            'supervisor_id' => [
                'nullable',
                'integer',
                'exists:supervisors,id',
            ],

            'group_id' => [
                'nullable',
                'integer',
                'exists:groups,id',
            ],

            'student_id' => [
                'nullable',
                'integer',
                'exists:students,id',
            ],

            'subject' => [
                'required',
                'string',
                'max:255',
            ],

            'starts_at' => [
                'required',
                'date',
            ],

            'ends_at' => [
                'required',
                'date',
                'after:starts_at',
            ],

            'zoom_url' => [
                'nullable',
                'string',
            ],

            'status' => [
                'nullable',
                Rule::in(['scheduled', 'completed', 'cancelled']),
            ],

            'teacher_rate' => [
                'nullable',
                'numeric',
                'min:0',
            ],

            'supervisor_rate' => [
                'nullable',
                'numeric',
                'min:0',
            ],

            'notes' => [
                'nullable',
                'string',
            ],
        ]);

        if ($data['type'] === 'group' && empty($data['group_id'])) {
            return response()->json([
                'success' => false,
                'message' => 'group_id is required for group lessons.',
            ], 422);
        }

        if ($data['type'] === 'private' && empty($data['student_id'])) {
            return response()->json([
                'success' => false,
                'message' => 'student_id is required for private lessons.',
            ], 422);
        }

        /*
         * Try to load default rates from lesson settings
         * when rates were not supplied manually.
         */
        if (
            !array_key_exists('teacher_rate', $data) ||
            $data['teacher_rate'] === null
        ) {
            $setting = LessonSetting::where('lesson_type', $data['type'])
                ->where('active', true)
                ->first();

            if ($setting) {
                $data['teacher_rate'] = $setting->teacher_rate;
            }
        }

        if (
            !array_key_exists('supervisor_rate', $data) ||
            $data['supervisor_rate'] === null
        ) {
            $setting = $setting ?? LessonSetting::where(
                'lesson_type',
                $data['type']
            )->where('active', true)->first();

            if ($setting) {
                $data['supervisor_rate'] = $setting->supervisor_rate;
            }
        }

        $data['status'] = $data['status'] ?? 'scheduled';
        $data['teacher_rate'] = $data['teacher_rate'] ?? 0;
        $data['supervisor_rate'] = $data['supervisor_rate'] ?? 0;

        $data['teacher_due'] = $data['teacher_rate'];
        $data['supervisor_due'] = $data['supervisor_rate'];

        $lesson = DB::transaction(function () use ($data) {
            $lesson = Lesson::create($data);

            TeacherLessonDue::create([
                'teacher_id' => $lesson->teacher_id,
                'lesson_id' => $lesson->id,
                'amount' => $lesson->teacher_due,
                'paid_amount' => 0,
                'status' => 'unpaid',
            ]);

            if ($lesson->supervisor_id) {
                SupervisorDue::create([
                    'supervisor_id' => $lesson->supervisor_id,
                    'lesson_id' => $lesson->id,
                    'amount' => $lesson->supervisor_due,
                    'paid_amount' => 0,
                    'status' => 'unpaid',
                ]);
            }

            return $lesson;
        });

        return response()->json([
            'success' => true,
            'message' => 'Lesson created successfully.',
            'data' => $lesson->fresh()->load([
                'teacher',
                'supervisor',
                'group',
                'student',
                'teacherDueRecord',
                'supervisorDueRecord',
            ]),
        ], 201);
    }

    public function show(Lesson $lesson)
    {
        return response()->json([
            'success' => true,
            'data' => $lesson->load([
                'teacher',
                'supervisor',
                'group',
                'student',
                'teacherDueRecord',
                'supervisorDueRecord',
            ]),
        ]);
    }

    public function update(Request $request, Lesson $lesson)
    {
        $data = $request->validate([
            'type' => [
                'sometimes',
                Rule::in(['group', 'private']),
            ],

            'teacher_id' => [
                'sometimes',
                'integer',
                'exists:teachers,id',
            ],

            'supervisor_id' => [
                'nullable',
                'integer',
                'exists:supervisors,id',
            ],

            'group_id' => [
                'nullable',
                'integer',
                'exists:groups,id',
            ],

            'student_id' => [
                'nullable',
                'integer',
                'exists:students,id',
            ],

            'subject' => [
                'sometimes',
                'string',
                'max:255',
            ],

            'starts_at' => [
                'sometimes',
                'date',
            ],

            'ends_at' => [
                'sometimes',
                'date',
            ],

            'zoom_url' => [
                'nullable',
                'string',
            ],

            'status' => [
                'sometimes',
                Rule::in(['scheduled', 'completed', 'cancelled']),
            ],

            'teacher_rate' => [
                'sometimes',
                'numeric',
                'min:0',
            ],

            'supervisor_rate' => [
                'sometimes',
                'numeric',
                'min:0',
            ],

            'notes' => [
                'nullable',
                'string',
            ],
        ]);

        if (
            isset($data['starts_at'], $data['ends_at']) &&
            strtotime($data['ends_at']) <= strtotime($data['starts_at'])
        ) {
            return response()->json([
                'success' => false,
                'message' => 'ends_at must be after starts_at.',
            ], 422);
        }

        if (isset($data['teacher_rate'])) {
            $data['teacher_due'] = $data['teacher_rate'];
        }

        if (isset($data['supervisor_rate'])) {
            $data['supervisor_due'] = $data['supervisor_rate'];
        }

        DB::transaction(function () use ($lesson, $data) {
            $lesson->update($data);

            if (array_key_exists('teacher_rate', $data)) {
                $due = TeacherLessonDue::where(
                    'lesson_id',
                    $lesson->id
                )->first();

                if ($due && (float) $due->paid_amount === 0.0) {
                    $due->amount = $lesson->teacher_due;
                    $due->save();
                }
            }

            if (array_key_exists('supervisor_rate', $data)) {
                $due = SupervisorDue::where(
                    'lesson_id',
                    $lesson->id
                )->first();

                if ($due && (float) $due->paid_amount === 0.0) {
                    $due->amount = $lesson->supervisor_due;
                    $due->save();
                }
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Lesson updated successfully.',
            'data' => $lesson->fresh()->load([
                'teacher',
                'supervisor',
                'group',
                'student',
                'teacherDueRecord',
                'supervisorDueRecord',
            ]),
        ]);
    }

    public function destroy(Lesson $lesson)
    {
        DB::transaction(function () use ($lesson) {
            TeacherLessonDue::where(
                'lesson_id',
                $lesson->id
            )->delete();

            SupervisorDue::where(
                'lesson_id',
                $lesson->id
            )->delete();

            $lesson->delete();
        });

        return response()->json([
            'success' => true,
            'message' => 'Lesson deleted successfully.',
        ]);
    }

    public function complete(Lesson $lesson)
    {
        if ($lesson->status === 'cancelled') {
            return response()->json([
                'success' => false,
                'message' => 'Cancelled lessons cannot be completed.',
            ], 422);
        }

        $lesson->update([
            'status' => 'completed',
            'completed_at' => now(),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Lesson completed successfully.',
            'data' => $lesson->fresh()->load([
                'teacher',
                'supervisor',
                'group',
                'student',
                'teacherDueRecord',
                'supervisorDueRecord',
            ]),
        ]);
    }

    public function cancel(Lesson $lesson)
    {
        if ($lesson->status === 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Completed lessons cannot be cancelled.',
            ], 422);
        }

        $lesson->update([
            'status' => 'cancelled',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Lesson cancelled successfully.',
            'data' => $lesson->fresh()->load([
                'teacher',
                'supervisor',
                'group',
                'student',
                'teacherDueRecord',
                'supervisorDueRecord',
            ]),
        ]);
    }
}
