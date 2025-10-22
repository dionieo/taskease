import 'package:hive/hive.dart';
import '../models/task_model.dart';

class HiveStorage {
  // Singleton pattern (biar cuma ada satu instance di seluruh aplikasi)
  static final HiveStorage _instance = HiveStorage._internal();
  factory HiveStorage() => _instance;
  HiveStorage._internal();

  // Akses box Hive yang menyimpan semua data task
  final Box<TaskModel> _taskBox = Hive.box<TaskModel>('tasks');

  // CREATE - tambah tugas baru
  Future<void> addTask(TaskModel task) async {
    // DEBUG: tampilkan apa yang mau disimpan
    print('DEBUG addTask: task.deadline BEFORE ADD = ${task.deadline}');

    final int key = await _taskBox.add(task);

    // DEBUG: baca kembali entry yang baru saja ditambahkan
    final stored = _taskBox.getAt(_taskBox.length - 1);
    print('DEBUG addTask: stored.deadline AFTER ADD = ${stored?.deadline}');
    print('DEBUG addTask: stored.runtimeType = ${stored.runtimeType}, key=$key');
  }

  // READ - ambil semua tugas dari box
  List<TaskModel> getTasks() {
    final list = _taskBox.values.toList();
    // DEBUG: list deadlines
    print('DEBUG getTasks: deadlines = ${list.map((t) => t.deadline).toList()}');
    return list;
  }

  // UPDATE - ubah data tugas tertentu
  Future<void> updateTask(int index, TaskModel updatedTask) async {
    await _taskBox.putAt(index, updatedTask);
  }

  // DELETE - hapus tugas berdasarkan index
  Future<void> deleteTask(int index) async {
    await _taskBox.deleteAt(index);
  }

  // CLEAR - hapus semua tugas
  Future<void> clearTasks() async {
    await _taskBox.clear();
  }

  // GET BY STATUS - ambil hanya tugas yang belum selesai
  List<TaskModel> getPendingTasks() {
    return _taskBox.values.where((task) => task.isDone == false).toList();
  }

  // GET BY STATUS - ambil hanya tugas yang sudah selesai
  List<TaskModel> getCompletedTasks() {
    return _taskBox.values.where((task) => task.isDone == true).toList();
  }

  // GET BY DEADLINE - ambil tugas yang deadlinenya masih aktif (belum lewat)
  List<TaskModel> getActiveDeadlines() {
    final now = DateTime.now();
    return _taskBox.values
        .where((task) => task.deadline != null && task.deadline!.isAfter(now))
        .toList();
  }
}
