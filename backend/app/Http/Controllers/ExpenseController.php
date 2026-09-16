<?php
namespace App\Http\Controllers;

use App\Models\Expense;
use Illuminate\Http\Request;

class ExpenseController extends Controller
{
    public function update(Request $request, Expense $expense)
    {
        $data = $request->validate([
            'category'=>'sometimes|required|string|max:255',
            'amount'=>'sometimes|required|numeric|min:0.01',
            'spent_on'=>'sometimes|required|date',
            'description'=>'nullable|string',
        ]);
        $expense->update($data);
        return response()->json(['success'=>true,'data'=>$expense->fresh()]);
    }

    public function destroy(Expense $expense)
    {
        $expense->delete();
        return response()->json(['success'=>true]);
    }
}
