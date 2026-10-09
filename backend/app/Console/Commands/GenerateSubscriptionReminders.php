<?php

namespace App\Console\Commands;

use App\Models\Subscription;
use App\Models\SubscriptionReminder;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

class GenerateSubscriptionReminders extends Command
{
    protected $signature = 'osa:generate-subscription-reminders';
    protected $description = 'Create non-duplicated in-app reminders for renewals, arrears, and per-lesson collection thresholds.';

    public function handle(): int
    {
        $today = Carbon::today();
        $created = 0;

        Subscription::with(['student', 'payments', 'lessonUsages'])->chunkById(100, function ($subscriptions) use ($today, &$created) {
            foreach ($subscriptions as $subscription) {
                $student = $subscription->student;
                $name = $student?->name ?? 'الطالب';
                $subject = $subscription->subject;
                $paid = (float) $subscription->payments->sum('amount');
                $used = $subscription->lessonUsages->count();
                $thresholdForBilling = (int) ($subscription->lesson_count ?? 0);
                $billableLessons = $thresholdForBilling > 0 ? intdiv($used, $thresholdForBilling) * $thresholdForBilling : $used;
                $gross = ($subscription->billing_type ?? 'monthly') === 'per_lesson'
                    ? (float) ($subscription->lesson_price ?? $subscription->amount) * $billableLessons
                    : (float) $subscription->amount;
                $outstanding = max(0, $gross - $paid);

                if (($subscription->billing_type ?? 'monthly') === 'per_lesson') {
                    $threshold = (int) ($subscription->lesson_count ?? 0);
                    if ($threshold > 0 && $used >= $threshold && $outstanding > 0.009) {
                        $cycle = (string) intdiv($used, $threshold);
                        $reminder = SubscriptionReminder::firstOrCreate(
                            ['subscription_id' => $subscription->id, 'reminder_type' => 'collection_due', 'cycle_key' => $cycle],
                            [
                                'title' => 'موعد تحصيل اشتراك بالحصة',
                                'message' => "وصل الطالب {$name} في مادة {$subject} إلى حد التحصيل المتفق عليه ({$threshold} حصة). المبلغ المستحق حاليًا: " . number_format($outstanding, 2) . ' جنيه.',
                                'due_on' => $today->toDateString(),
                            ]
                        );
                        if ($reminder->wasRecentlyCreated) $created++;
                    }
                    continue;
                }

                if (!$subscription->ends_on) continue;
                $end = Carbon::parse($subscription->ends_on)->startOfDay();
                $days = $today->diffInDays($end, false);

                if ($subscription->status === 'active' && $days >= 0 && $days <= 3) {
                    $reminder = SubscriptionReminder::firstOrCreate(
                        ['subscription_id' => $subscription->id, 'reminder_type' => 'renewal_due', 'cycle_key' => $end->toDateString()],
                        [
                            'title' => 'اقتراب تجديد الاشتراك',
                            'message' => "اشتراك الطالب {$name} في مادة {$subject} ينتهي يوم {$end->toDateString()}. يرجى مراجعة التجديد والتواصل مع ولي الأمر عند الحاجة.",
                            'due_on' => $end->toDateString(),
                        ]
                    );
                    if ($reminder->wasRecentlyCreated) $created++;
                } elseif ($end->lt($today) && $outstanding > 0.009) {
                    $reminder = SubscriptionReminder::firstOrCreate(
                        ['subscription_id' => $subscription->id, 'reminder_type' => 'overdue', 'cycle_key' => $end->toDateString()],
                        [
                            'title' => 'اشتراك متأخر ومديونية قائمة',
                            'message' => "اشتراك الطالب {$name} في مادة {$subject} انتهى يوم {$end->toDateString()}، وما زال عليه مبلغ مستحق قدره " . number_format($outstanding, 2) . ' جنيه.',
                            'due_on' => $end->toDateString(),
                        ]
                    );
                    if ($reminder->wasRecentlyCreated) $created++;
                }
            }
        });

        $this->info("Created {$created} reminder(s).");
        return self::SUCCESS;
    }
}
