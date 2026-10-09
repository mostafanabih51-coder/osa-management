<?php

namespace App\Console\Commands;

use App\Models\Lesson;
use App\Services\SubscriptionUsageRecorder;
use Illuminate\Console\Command;

class ReconcileSubscriptionLessonUsage extends Command
{
    protected $signature = 'osa:reconcile-subscription-lesson-usage';
    protected $description = 'Idempotently backfill the new subscription lesson-usage ledger from completed lessons. Run manually after a database backup.';

    public function handle(SubscriptionUsageRecorder $recorder): int
    {
        $created = 0;
        Lesson::where('status', 'completed')->orderBy('starts_at')->orderBy('id')->chunk(100, function ($lessons) use ($recorder, &$created) {
            foreach ($lessons as $lesson) $created += $recorder->record($lesson);
        });
        $this->info("Created {$created} subscription lesson-usage record(s). Existing records were preserved.");
        return self::SUCCESS;
    }
}
