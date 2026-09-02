class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String type;
  final bool read;
  final DateTime? createdAt;

  NotificationModel({required this.id, required this.title, required this.body, required this.type, required this.read, this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: int.tryParse('${json['id'] ?? 0}') ?? 0,
    title: '${json['title'] ?? json['subject'] ?? 'إشعار'}',
    body: '${json['body'] ?? json['message'] ?? ''}',
    type: '${json['type'] ?? 'general'}',
    read: json['read'] == true || json['is_read'] == true || json['read_at'] != null,
    createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
  );
}
