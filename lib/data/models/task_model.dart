import 'package:hive/hive.dart';

part 'task_model.g.dart';

@HiveType(typeId: 0)
class TaskModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime? deadline;

  @HiveField(4)
  bool isDone;

  @HiveField(5)
  int priority; // 1=Rendah, 2=Sedang, 3=Tinggi

  TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.isDone = false,
    this.priority = 2, // default: Sedang
  });
}
