<?php
namespace App\Http\Controllers;
use App\Models\StudentSubject;
use App\Models\TeacherStudentSubject;
use Illuminate\Http\Request;
class TeacherAssignmentController extends Controller
{
 public function store(Request $request){$d=$request->validate(['teacher_id'=>'required|exists:teachers,id','student_id'=>'required|exists:students,id','subject'=>'required|string|max:150','teacher_rate'=>'required|numeric|min:0','academy_percentage'=>'required|numeric|min:0|max:100','supervisor_id'=>'nullable|exists:supervisors,id','status'=>'nullable|in:active,inactive']);if(!StudentSubject::where(['student_id'=>$d['student_id'],'subject'=>$d['subject']])->exists())return response()->json(['message'=>'المادة غير مضافة إلى مواد الطالب.'],422);$a=TeacherStudentSubject::updateOrCreate(['teacher_id'=>$d['teacher_id'],'student_id'=>$d['student_id'],'subject'=>$d['subject']],['teacher_rate'=>$d['teacher_rate'],'academy_percentage'=>$d['academy_percentage'],'supervisor_id'=>$d['supervisor_id']??null,'status'=>$d['status']??'active']);return response()->json(['success'=>true,'data'=>$a->load(['teacher','student','supervisor'])],201);}
 public function update(Request $request,TeacherStudentSubject $assignment){$d=$request->validate(['teacher_rate'=>'sometimes|required|numeric|min:0','academy_percentage'=>'sometimes|required|numeric|min:0|max:100','supervisor_id'=>'nullable|exists:supervisors,id','status'=>'nullable|in:active,inactive']);$assignment->update($d);return response()->json(['success'=>true,'data'=>$assignment->fresh()->load(['teacher','student','supervisor'])]);}
 public function destroy(TeacherStudentSubject $assignment){$assignment->delete();return['success'=>true];}
}
