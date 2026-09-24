<?php
namespace App\Http\Controllers;
use App\Models\StudentSubject;
use App\Models\TeacherStudentSubject;
use Illuminate\Http\Request;
class TeacherAssignmentController extends Controller
{
 public function store(Request $request){$d=$request->validate(['teacher_id'=>'required|exists:teachers,id','student_id'=>'required|exists:students,id','subject'=>'required|string|max:150','lesson_price'=>'required|numeric|min:0','academy_percentage'=>'required|numeric|min:0|max:99.99','supervisor_id'=>'nullable|exists:supervisors,id','status'=>'nullable|in:active,inactive']);if(!StudentSubject::where(['student_id'=>$d['student_id'],'subject'=>$d['subject']])->exists())return response()->json(['message'=>'المادة غير مضافة إلى مواد الطالب.'],422);$a=TeacherStudentSubject::updateOrCreate(['teacher_id'=>$d['teacher_id'],'student_id'=>$d['student_id'],'subject'=>$d['subject']],['lesson_price'=>$d['lesson_price'],'teacher_rate'=>round((float)$d['lesson_price']*(1-(float)$d['academy_percentage']/100),2),'academy_percentage'=>$d['academy_percentage'],'supervisor_id'=>$d['supervisor_id']??null,'status'=>$d['status']??'active']);return response()->json(['success'=>true,'data'=>$a->load(['teacher','student','supervisor'])],201);}
 public function update(Request $request,TeacherStudentSubject $assignment){$d=$request->validate(['lesson_price'=>'sometimes|required|numeric|min:0','academy_percentage'=>'sometimes|required|numeric|min:0|max:99.99','supervisor_id'=>'nullable|exists:supervisors,id','status'=>'nullable|in:active,inactive']);if(array_key_exists('lesson_price',$d)||array_key_exists('academy_percentage',$d)){ $gross=array_key_exists('lesson_price',$d)?(float)$d['lesson_price']:(float)$assignment->lesson_price; $pct=array_key_exists('academy_percentage',$d)?(float)$d['academy_percentage']:(float)$assignment->academy_percentage; $d['lesson_price']=round($gross,2); $d['teacher_rate']=round($gross*(1-$pct/100),2); } $assignment->update($d);return response()->json(['success'=>true,'data'=>$assignment->fresh()->load(['teacher','student','supervisor'])]);}
 public function destroy(TeacherStudentSubject $assignment){$assignment->delete();return['success'=>true];}
}
