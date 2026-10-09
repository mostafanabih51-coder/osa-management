<?php

namespace App\Http\Controllers;

use App\Models\SubscriptionReminder;
use Illuminate\Http\Request;

class SubscriptionReminderController extends Controller
{
    public function index(Request $request)
    {
        $query = SubscriptionReminder::with(['subscription.student'])->latest();
        if ($request->boolean('unread_only')) $query->whereNull('read_at');
        return response()->json(['success' => true, 'data' => $query->limit(200)->get()]);
    }

    public function markRead(SubscriptionReminder $reminder)
    {
        if (!$reminder->read_at) $reminder->update(['read_at' => now()]);
        return response()->json(['success' => true, 'data' => $reminder->fresh()]);
    }
}
