class ReportSummary {
  final int students;
  final int teachers;
  final int courses;
  final int groups;
  final int activeSubscriptions;
  final double revenue;
  final double collected;
  final double outstanding;
  final int present;
  final int absent;
  final int late;
  final int excused;
  final List<ReportItem> items;

  const ReportSummary({this.students=0,this.teachers=0,this.courses=0,this.groups=0,this.activeSubscriptions=0,this.revenue=0,this.collected=0,this.outstanding=0,this.present=0,this.absent=0,this.late=0,this.excused=0,this.items=const []});
  static const empty = ReportSummary();
  factory ReportSummary.fromJson(Map<String,dynamic> j) {
    double d(dynamic v)=>double.tryParse(v?.toString()??'')??0;
    int i(dynamic v)=>int.tryParse(v?.toString()??'')??0;
    final raw = j['items'] ?? j['data']?['items'] ?? [];
    return ReportSummary(
      students:i(j['students'] ?? j['data']?['students']), teachers:i(j['teachers'] ?? j['data']?['teachers']), courses:i(j['courses'] ?? j['data']?['courses']), groups:i(j['groups'] ?? j['data']?['groups']), activeSubscriptions:i(j['active_subscriptions'] ?? j['activeSubscriptions'] ?? j['data']?['active_subscriptions']),
      revenue:d(j['revenue'] ?? j['data']?['revenue']), collected:d(j['collected'] ?? j['data']?['collected']), outstanding:d(j['outstanding'] ?? j['data']?['outstanding']),
      present:i(j['present'] ?? j['data']?['present']), absent:i(j['absent'] ?? j['data']?['absent']), late:i(j['late'] ?? j['data']?['late']), excused:i(j['excused'] ?? j['data']?['excused']),
      items: raw is List ? raw.whereType<Map>().map((e)=>ReportItem.fromJson(Map<String,dynamic>.from(e))).toList() : const []);
  }
}
class ReportItem { final String label; final String value; const ReportItem({required this.label,required this.value}); factory ReportItem.fromJson(Map<String,dynamic> j)=>ReportItem(label:(j['label']??j['name']??'').toString(),value:(j['value']??j['total']??'').toString()); }
