class GroupModel {
  final int id;
  final String name, course, teacher, schedule, status;
  final int studentsCount;
  const GroupModel({required this.id, required this.name, this.course='', this.teacher='', this.schedule='', this.status='', this.studentsCount=0});
  factory GroupModel.fromJson(Map<String,dynamic> j)=>GroupModel(
    id:int.tryParse('${j['id']??0}')??0,
    name:'${j['name']??j['title']??j['group_name']??''}',
    course:'${j['course_name']??j['course']??j['course_title']??''}',
    teacher:'${j['teacher_name']??j['teacher']??j['teacher_full_name']??''}',
    schedule:'${j['schedule']??j['meeting_time']??j['time']??''}',
    status:'${j['status']??''}',
    studentsCount:int.tryParse('${j['students_count']??j['studentsCount']??j['students_count_total']??0}')??0,
  );
}
