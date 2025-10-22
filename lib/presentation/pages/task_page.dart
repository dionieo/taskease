import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/task_model.dart';
import '../../data/services/hive_storage.dart';
import '../../data/services/notification_service.dart'; // 🔔 Tambahan

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final HiveStorage _storage = HiveStorage();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  DateTime? _selectedDeadline;

  @override
  Widget build(BuildContext context) {
    final tasks = _storage.getTasks();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Listify'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada tugas nih 😴',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildTaskCard(task, index);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    final today =
        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Halo 👋',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        Text(
          today,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task, int index) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Checkbox(
          value: task.isDone,
          activeColor: Colors.green,
          onChanged: (value) async {
            final updated = TaskModel(
              id: task.id,
              title: task.title,
              description: task.description,
              deadline: task.deadline,
              isDone: value ?? false,
            );
            await _storage.updateTask(index, updated);
            setState(() {});
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isDone ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description?.isNotEmpty ?? false)
              Text(task.description ?? ''),
            if (task.deadline != null)
              Text(
                'Deadline: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(task.deadline!)}',
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () async {
            await _storage.deleteTask(index);
            setState(() {});
          },
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    _selectedDeadline = null;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Tugas Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Tugas'),
              ),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDeadline == null
                          ? 'Belum pilih deadline'
                          : 'Deadline: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(_selectedDeadline!)}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _selectedDeadline = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _titleController.clear();
              _descController.clear();
              Navigator.pop(context);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_titleController.text.isNotEmpty) {
                final newTask = TaskModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: _titleController.text,
                  description: _descController.text,
                  deadline: _selectedDeadline,
                  isDone: false,
                );

                await _storage.addTask(newTask);

                if (_selectedDeadline != null) {
                  await NotificationService.showNotification(
                    title: 'Pengingat Tugas',
                    body:
                        'Tugas "${_titleController.text}" akan berakhir sebentar lagi!',
                    scheduledTime:
                        _selectedDeadline!.subtract(const Duration(minutes: 30)),
                  );
                }

                _titleController.clear();
                _descController.clear();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
