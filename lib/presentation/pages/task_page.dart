import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import '../../config/app_constants.dart';
import '../../data/models/task_model.dart';
import '../../data/services/hive_storage.dart';
import '../../data/services/notification_service.dart';

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
  int _selectedPriority = 2;

  final Set<int> _expandedIndices = {};

  @override
  Widget build(BuildContext context) {
    final tasks = _storage.getTasks();
    final pendingTasks = tasks.where((t) => !t.isDone).length;
    final completedTasks = tasks.where((t) => t.isDone).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'TaskEase',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID')
                              .format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildStatCard(
                              icon: Icons.pending_actions,
                              label: 'Aktif',
                              count: pendingTasks,
                              color: Colors.orangeAccent,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              icon: Icons.check_circle,
                              label: 'Selesai',
                              count: completedTasks,
                              color: Colors.greenAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          tasks.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.task_alt,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada tugas',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tekan tombol + untuk menambah',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildTaskCard(tasks[index], index),
                      childCount: tasks.length,
                    ),
                  ),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Tugas'),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task, int index) {
    Color priorityColor;
    String priorityLabel;
    IconData priorityIcon;
    
    switch (task.priority) {
      case 1:
        priorityColor = Colors.green;
        priorityLabel = 'Rendah';
        priorityIcon = Icons.arrow_downward;
        break;
      case 3:
        priorityColor = Colors.red;
        priorityLabel = 'Tinggi';
        priorityIcon = Icons.arrow_upward;
        break;
      default:
        priorityColor = Colors.orange;
        priorityLabel = 'Sedang';
        priorityIcon = Icons.remove;
    }

    final bool isExpanded = _expandedIndices.contains(index);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      elevation: task.isDone ? 1 : 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Ketuk card untuk edit
          _showEditTaskDialog(context, task, index);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: task.isDone,
                    activeColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    onChanged: (value) async {
                      final updated = TaskModel(
                        id: task.id,
                        title: task.title,
                        description: task.description,
                        deadline: task.deadline,
                        isDone: value ?? false,
                        priority: task.priority,
                      );
                      await _storage.updateTask(index, updated);
                      setState(() {});
                    },
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedIndices.remove(index);
                          } else {
                            _expandedIndices.add(index);
                          }
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                decoration: task.isDone
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                color: task.isDone ? Colors.grey : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            size: 20,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: priorityColor, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(priorityIcon, size: 14, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          priorityLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditTaskDialog(context, task, index);
                      } else if (value == 'delete') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Konfirmasi'),
                            content: const Text('Hapus tugas ini?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Batal'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Hapus',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await NotificationService.cancelTaskReminders(task.id);
                          await _storage.deleteTask(index);
                          _expandedIndices.remove(index);
                          setState(() {});
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Hapus', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if ((task.description?.isNotEmpty ?? false) && isExpanded) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
              if (task.deadline != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: task.deadline!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEEE, d MMM yyyy • HH:mm', 'id_ID')
                            .format(task.deadline!),
                        style: TextStyle(
                          fontSize: 13,
                          color: task.deadline!.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    DateTime? tempDeadline;
    _titleController.clear();
    _descController.clear();
    _selectedPriority = 2;

    _showTaskDialog(
      context: context,
      title: 'Tambah Tugas Baru',
      tempDeadline: tempDeadline,
      onSave: (tempDeadline) async {
        final title = _titleController.text.trim();
        if (title.isEmpty) return;

        final task = TaskModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          description: _descController.text.trim(),
          deadline: tempDeadline,
          isDone: false,
          priority: _selectedPriority,
        );

        await _storage.addTask(task);

        if (tempDeadline != null) {
          await NotificationService.scheduleTaskReminders(
            taskId: task.id,
            title: task.title,
            deadline: tempDeadline,
          );
        }

        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  void _showEditTaskDialog(BuildContext context, TaskModel task, int index) {
    _titleController.text = task.title;
    _descController.text = task.description ?? '';
    _selectedPriority = task.priority;
    DateTime? tempDeadline = task.deadline;

    _showTaskDialog(
      context: context,
      title: 'Edit Tugas',
      tempDeadline: tempDeadline,
      onSave: (newDeadline) async {
        final title = _titleController.text.trim();
        if (title.isEmpty) return;

        // Batalkan notifikasi lama
        await NotificationService.cancelTaskReminders(task.id);

        final updatedTask = TaskModel(
          id: task.id,
          title: title,
          description: _descController.text.trim(),
          deadline: newDeadline,
          isDone: task.isDone,
          priority: _selectedPriority,
        );

        await _storage.updateTask(index, updatedTask);

        // Jadwalkan notifikasi baru jika ada deadline
        if (newDeadline != null) {
          await NotificationService.scheduleTaskReminders(
            taskId: updatedTask.id,
            title: updatedTask.title,
            deadline: newDeadline,
          );
        }

        setState(() {});
        Navigator.pop(context);
      },
    );
  }

  void _showTaskDialog({
    required BuildContext context,
    required String title,
    required DateTime? tempDeadline,
    required Function(DateTime?) onSave,
  }) {
    DateTime? localDeadline = tempDeadline;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            labelText: 'Judul',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.title),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag, color: Colors.grey, size: 20),
                              const SizedBox(width: 8),
                              const Text('Prioritas'),
                              const Spacer(),
                              DropdownButton<int>(
                                value: _selectedPriority,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('🟢 Rendah')),
                                  DropdownMenuItem(value: 2, child: Text('🟠 Sedang')),
                                  DropdownMenuItem(value: 3, child: Text('🔴 Tinggi')),
                                ],
                                onChanged: (value) {
                                  setModalState(() => _selectedPriority = value ?? 2);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: localDeadline ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                              locale: const Locale('id', 'ID'),
                            );
                            if (date == null) return;

                            final time = await showTimePicker(
                              context: context,
                              initialTime: localDeadline != null
                                  ? TimeOfDay.fromDateTime(localDeadline!)
                                  : TimeOfDay.now(),
                            );
                            if (time == null) return;

                            setModalState(() {
                              localDeadline = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    localDeadline == null
                                        ? 'Pilih tanggal & waktu'
                                        : DateFormat('EEE, d MMM yyyy • HH:mm',
                                                'id_ID')
                                            .format(localDeadline!),
                                    style: TextStyle(
                                      color: localDeadline == null
                                          ? Colors.grey
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        onPressed: () => onSave(localDeadline),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
