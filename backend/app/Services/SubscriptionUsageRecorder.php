<?php

namespace App\Services;

use App\Models\Group;
use App\Models\Lesson;
use App\Models\Subscription;
use App\Models\SubscriptionLessonUsage;

class SubscriptionUsageRecorder
{
    public function record(Lesson $lesson): int
    {
        $lessonDate = $lesson->starts_at?->toDateString() ?? now()->toDateString();
        $created = 0;

        if ($lesson->type === 'private' && $lesson->student_id) {
            $studentId = (int) $lesson->student_id;
            if (SubscriptionLessonUsage::where('lesson_id', $lesson->id)->where('student_id', $studentId)->exists()) return 0;

            $base = Subscription::where('student_id', $studentId)
                ->where('subject', $lesson->subject)
                ->where('service_type', 'private')
                ->whereIn('status', ['active', 'expired'])
                ->whereDate('starts_on', '<=', $lessonDate)
                ->orderBy('starts_on')->orderBy('id');

            $chosen = null;
            foreach ((clone $base)->where('billing_type', 'monthly')->whereNotNull('lesson_count')->get() as $candidate) {
                $used = SubscriptionLessonUsage::where('subscription_id', $candidate->id)->count();
                if ($used < (int) $candidate->lesson_count) { $chosen = $candidate; break; }
            }

            if (!$chosen) {
                $chosen = (clone $base)->where('billing_type', 'per_lesson')->reorder()
                    ->orderByRaw("CASE WHEN status = 'active' THEN 0 ELSE 1 END")
                    ->orderByDesc('starts_on')->first();
            }

            if ($chosen) {
                $usage = SubscriptionLessonUsage::firstOrCreate(
                    ['lesson_id' => $lesson->id, 'student_id' => $studentId],
                    ['subscription_id' => $chosen->id, 'lesson_date' => $lessonDate, 'service_type' => 'private']
                );
                if ($usage->wasRecentlyCreated) $created++;
            }
            return $created;
        }

        if ($lesson->type === 'group' && $lesson->group_id) {
            $group = Group::with('students')->find($lesson->group_id);
            if (!$group) return 0;
            foreach ($group->students as $student) {
                if (SubscriptionLessonUsage::where('lesson_id', $lesson->id)->where('student_id', $student->id)->exists()) continue;
                $subscription = Subscription::where('student_id', $student->id)
                    ->where('subject', $lesson->subject)
                    ->where('service_type', 'group')
                    ->where('group_id', $group->id)
                    ->whereIn('status', ['active', 'expired'])
                    ->whereDate('starts_on', '<=', $lessonDate)
                    ->whereDate('ends_on', '>=', $lessonDate)
                    ->orderByDesc('starts_on')->first();
                if (!$subscription) continue;
                $usage = SubscriptionLessonUsage::firstOrCreate(
                    ['lesson_id' => $lesson->id, 'student_id' => $student->id],
                    ['subscription_id' => $subscription->id, 'lesson_date' => $lessonDate, 'service_type' => 'group']
                );
                if ($usage->wasRecentlyCreated) $created++;
            }
        }

        return $created;
    }
}
